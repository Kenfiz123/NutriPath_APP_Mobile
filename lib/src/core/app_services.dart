import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class AppConfig {
  const AppConfig._();

  static const _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_definedBaseUrl.trim().isNotEmpty) return _definedBaseUrl.trim();
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8080'
        : 'http://127.0.0.1:8080';
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.tokenProvider});

  final String? Function() tokenProvider;
  final http.Client _client = http.Client();

  void close() => _client.close();

  Future<JsonMap> _request(
    String path, {
    String method = 'GET',
    Object? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = auth ? tokenProvider() : null;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final encodedBody = body == null ? null : jsonEncode(body);
    final http.Response response;
    try {
      final request = switch (method) {
        'POST' => _client.post(uri, headers: headers, body: encodedBody),
        'PATCH' => _client.patch(uri, headers: headers, body: encodedBody),
        'PUT' => _client.put(uri, headers: headers, body: encodedBody),
        'DELETE' => _client.delete(uri, headers: headers, body: encodedBody),
        _ => _client.get(uri, headers: headers),
      };
      response = await request.timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw const ApiException(
          'Backend phản hồi quá lâu. Hãy kiểm tra server rồi thử lại.',
          code: 'timeout',
        ),
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'Không kết nối được backend tại ${AppConfig.apiBaseUrl}. Hãy kiểm tra backend đã chạy và đúng port 8080.',
        code: 'network_error',
      );
    }

    final Object? decoded;
    try {
      decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw ApiException(
        'Backend trả về dữ liệu không hợp lệ. Hãy kiểm tra log server.',
        statusCode: response.statusCode,
        code: 'invalid_response',
      );
    }
    final payload = asJsonMap(decoded);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = asJsonMap(payload['error']);
      final message = asString(
        error['message'],
        'API request failed: ${response.statusCode}',
      );
      if (response.statusCode == 401 && token != null) {
        await SessionController.instance.expireSession(message);
      }
      throw ApiException(
        message,
        statusCode: response.statusCode,
        code: error['code']?.toString(),
      );
    }

    return payload;
  }

  String _memberId() {
    final memberId = SessionController.instance.session?.member.id;
    if (memberId == null || memberId.isEmpty) {
      throw const ApiException('Bạn cần đăng nhập để tiếp tục.');
    }
    return memberId;
  }

  Future<AuthSession> login(String email, String password) async {
    final json = await _request(
      '/api/auth/login',
      method: 'POST',
      auth: false,
      body: {'email': email, 'password': password},
    );
    return AuthSession.fromJson(json);
  }

  Future<AuthSession> register(JsonMap payload) async {
    final json = await _request(
      '/api/auth/register',
      method: 'POST',
      auth: false,
      body: payload,
    );
    return AuthSession.fromJson(json);
  }

  Future<Member> getMe() async {
    final json = await _request('/api/auth/me');
    return Member.fromJson(json['member']);
  }

  Future<void> logout() async {
    await _request('/api/auth/logout', method: 'POST');
  }

  Future<DashboardData> getDashboard({String? date}) async {
    final query = date == null ? '' : '?date=${Uri.encodeQueryComponent(date)}';
    final json = await _request('/api/members/${_memberId()}/dashboard$query');
    return DashboardData.fromJson(json);
  }

  Future<NutritionReport> getNutritionReport({
    int days = 7,
    String? endDate,
  }) async {
    final params = <String, String>{'days': '$days'};
    if (endDate != null) params['endDate'] = endDate;
    final json = await _request(
      '/api/members/${_memberId()}/reports/nutrition?${Uri(queryParameters: params).query}',
    );
    return NutritionReport.fromJson(json);
  }

  Future<JsonMap> exportNutritionReport({int days = 7, String? endDate}) async {
    final params = <String, String>{'days': '$days'};
    if (endDate != null) params['endDate'] = endDate;
    return _request(
      '/api/members/${_memberId()}/reports/export?${Uri(queryParameters: params).query}',
    );
  }

  Future<List<AppNotification>> getNotifications({
    int limit = 20,
    bool unread = false,
  }) async {
    final params = <String, String>{'limit': '$limit'};
    if (unread) params['unread'] = 'true';
    final json = await _request(
      '/api/members/${_memberId()}/notifications?${Uri(queryParameters: params).query}',
    );
    return embeddedList(
      json,
      'notifications',
    ).map(AppNotification.fromJson).toList();
  }

  Future<void> markAllNotificationsRead() async {
    await _request(
      '/api/members/${_memberId()}/notifications/read-all',
      method: 'PATCH',
    );
  }

  Future<JsonMap> createWeeklyCoachPlan({String? startDate}) async {
    final body = <String, dynamic>{};
    if (startDate != null) {
      body['startDate'] = startDate;
    }
    return _request('/api/ai/coach-weekly-plan', method: 'POST', body: body);
  }

  Future<List<WeeklyCoachPlan>> getWeeklyCoachPlans() async {
    final json = await _request('/api/members/${_memberId()}/coach-plans');
    return embeddedList(
      json,
      'coachPlans',
    ).map(WeeklyCoachPlan.fromJson).toList();
  }

  Future<CalorieCalculation> calculateCalories(JsonMap payload) async {
    final json = await _request(
      '/api/calculations/calorie',
      method: 'POST',
      auth: false,
      body: payload,
    );
    return CalorieCalculation.fromJson(json);
  }

  Future<Member> saveNutritionProfile(JsonMap payload) async {
    final json = await _request(
      '/api/members/${_memberId()}/nutrition-profile',
      method: 'POST',
      body: payload,
    );
    return Member.fromJson(json['member']);
  }

  Future<MealLog> getMealLog(String date) async {
    final json = await _request(
      '/api/members/${_memberId()}/meal-logs/${Uri.encodeComponent(date)}',
    );
    return MealLog.fromJson(json);
  }

  Future<List<Food>> getFoods([String search = '']) async {
    final json = await _request(
      '/api/foods?search=${Uri.encodeQueryComponent(search)}',
    );
    return embeddedList(json, 'foods').map(Food.fromJson).toList();
  }

  Future<MealLog> addMealItem(
    String date,
    String mealId,
    Object payload,
  ) async {
    final body = payload is String ? {'foodId': payload} : payload;
    final json = await _request(
      '/api/members/${_memberId()}/meal-logs/${Uri.encodeComponent(date)}/meals/$mealId/items',
      method: 'POST',
      body: body,
    );
    return MealLog.fromJson(json);
  }

  Future<MealLog> deleteMealItem(
    String date,
    String mealId,
    String itemId,
  ) async {
    final json = await _request(
      '/api/members/${_memberId()}/meal-logs/${Uri.encodeComponent(date)}/meals/$mealId/items/$itemId',
      method: 'DELETE',
    );
    return MealLog.fromJson(json);
  }

  Future<MealLog> updateWater(String date, int waterGlasses) async {
    final json = await _request(
      '/api/members/${_memberId()}/meal-logs/${Uri.encodeComponent(date)}/water',
      method: 'PATCH',
      body: {'waterGlasses': waterGlasses},
    );
    return MealLog.fromJson(json);
  }

  Future<JsonMap> estimateFoodPhoto({
    required String imageDataUrl,
    String? notes,
  }) {
    final body = <String, dynamic>{'imageDataUrl': imageDataUrl};
    if (notes != null) {
      body['notes'] = notes;
    }
    return _request('/api/ai/food-photo-estimate', method: 'POST', body: body);
  }

  Future<JsonMap> getCustomFoodIngredients([String search = '']) {
    return _request(
      '/api/nutrition/custom-food/ingredients?search=${Uri.encodeQueryComponent(search)}',
    );
  }

  Future<JsonMap> estimateCustomFood(JsonMap payload) {
    return _request(
      '/api/nutrition/custom-food/estimate',
      method: 'POST',
      body: payload,
    );
  }

  Future<List<JsonMap>> getSavedCustomFoods([String search = '']) async {
    final json = await _request(
      '/api/members/${_memberId()}/custom-foods?search=${Uri.encodeQueryComponent(search)}',
    );
    return embeddedList(json, 'customFoods');
  }

  Future<RecipeCollection> getRecipes({
    String search = '',
    String tag = 'Tất cả',
  }) async {
    final params = <String, String>{};
    if (search.isNotEmpty) params['search'] = search;
    if (tag.isNotEmpty && tag != 'Tất cả') params['tag'] = tag;
    final query = Uri(queryParameters: params).query;
    final json = await _request(
      '/api/recipes${query.isEmpty ? '' : '?$query'}',
    );
    return RecipeCollection.fromJson(json);
  }

  Future<JsonMap> generatePersonalizedRecipe(JsonMap payload) {
    return _request(
      '/api/ai/personalized-recipes',
      method: 'POST',
      body: payload,
    );
  }

  Future<List<Recipe>> getPersonalizedRecipes() async {
    final json = await _request(
      '/api/members/${_memberId()}/personalized-recipes',
    );
    return embeddedList(json, 'recipes').map(Recipe.fromJson).toList();
  }

  Future<List<Plan>> getPlans(String billing) async {
    final json = await _request('/api/plans?billing=$billing');
    return embeddedList(json, 'plans').map(Plan.fromJson).toList();
  }

  Future<CheckoutQuote> getCheckoutQuote({
    required String planId,
    required String billing,
    String discountCode = '',
    int trialDays = 0,
  }) async {
    final json = await _request(
      '/api/checkout/quote',
      method: 'POST',
      body: {
        'planId': planId,
        'billing': billing,
        'discountCode': discountCode,
        'trialDays': trialDays,
      },
    );
    return CheckoutQuote.fromJson(json['quote']);
  }

  Future<(Payment, Member)> createPayment(JsonMap payload) async {
    final json = await _request('/api/payments', method: 'POST', body: payload);
    return (Payment.fromJson(json['payment']), Member.fromJson(json['member']));
  }

  Future<JsonMap> getProfile() {
    return _request('/api/members/${_memberId()}/profile');
  }

  Future<Member> updateMemberProfile(
    JsonMap payload, {
    String? memberId,
  }) async {
    final json = await _request(
      '/api/members/${memberId ?? _memberId()}',
      method: 'PATCH',
      body: payload,
    );
    return Member.fromJson(json);
  }

  Future<List<ChatMessage>> getChatHistory() async {
    final memberId = SessionController.instance.session?.member.id;
    final query = memberId == null
        ? ''
        : '?memberId=${Uri.encodeQueryComponent(memberId)}';
    final json = await _request(
      '/api/chat/history$query',
      auth: memberId != null,
    );
    return jsonMapList(json['messages']).map(ChatMessage.fromJson).toList();
  }

  Future<List<String>> getQuickReplies() async {
    final json = await _request('/api/chat/quick-replies', auth: false);
    return stringList(json['quickReplies']);
  }

  Future<JsonMap> sendChatMessage(String text, {String mode = 'assistant'}) {
    final memberId = SessionController.instance.session?.member.id;
    final body = <String, dynamic>{'text': text, 'mode': mode};
    if (memberId != null) {
      body['memberId'] = memberId;
    }
    return _request(
      '/api/chat/messages',
      method: 'POST',
      auth: memberId != null,
      body: body,
    );
  }

  Future<AdminOverview> getAdminOverview() async {
    final json = await _request('/api/admin/overview');
    return AdminOverview.fromJson(json);
  }

  Future<JsonMap> getAdminUsers({
    String search = '',
    String role = 'Tất cả',
    String status = 'Tất cả',
  }) {
    final params = <String, String>{};
    if (search.isNotEmpty) params['search'] = search;
    if (role != 'Tất cả') params['role'] = role;
    if (status != 'Tất cả') params['status'] = status;
    final query = Uri(queryParameters: params).query;
    return _request('/api/admin/users${query.isEmpty ? '' : '?$query'}');
  }

  Future<JsonMap> getAdminContent() => _request('/api/admin/content');

  Future<JsonMap> getAdminAnalytics() => _request('/api/admin/analytics');

  Future<JsonMap> getAdminAiSettings() => _request('/api/admin/settings/ai');

  Future<JsonMap> updateAdminAiSettings(JsonMap payload) {
    return _request('/api/admin/settings/ai', method: 'PATCH', body: payload);
  }

  Future<JsonMap> getAdminSecurity() => _request('/api/admin/security');

  Future<JsonMap> updateAdminSecurity(JsonMap payload) {
    return _request('/api/admin/security', method: 'PATCH', body: payload);
  }

  Future<JsonMap> getAdminAiSafetyLogs() =>
      _request('/api/admin/ai-safety-logs');

  Future<Food> createFood(JsonMap payload) async {
    final json = await _request('/api/foods', method: 'POST', body: payload);
    return Food.fromJson(json);
  }

  Future<Food> updateFood(String foodId, JsonMap payload) async {
    final json = await _request(
      '/api/foods/$foodId',
      method: 'PATCH',
      body: payload,
    );
    return Food.fromJson(json);
  }

  Future<void> deleteFood(String foodId) async {
    await _request('/api/foods/$foodId', method: 'DELETE');
  }
}

class SessionStore {
  static const _key = 'nutripath_session';

  Future<AuthSession?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final session = AuthSession.fromJson(jsonDecode(raw));
      if (session.token.isEmpty || session.member.id.isEmpty) return null;
      return session;
    } catch (_) {
      await prefs.remove(_key);
      return null;
    }
  }

  Future<void> write(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class SessionController extends ChangeNotifier {
  SessionController() {
    instance = this;
    api = ApiClient(tokenProvider: () => _session?.token);
  }

  static late SessionController instance;

  final SessionStore _store = SessionStore();
  late final ApiClient api;
  AuthSession? _session;
  bool _initialized = false;
  bool _busy = false;
  String? _error;

  AuthSession? get session => _session;
  Member? get member => _session?.member;
  bool get initialized => _initialized;
  bool get busy => _busy;
  String? get error => _error;
  bool get isLoggedIn => _session?.token.isNotEmpty ?? false;
  bool get isAdmin => member?.isAdmin ?? false;

  Future<void> restore() async {
    _busy = true;
    notifyListeners();
    _session = await _store.read();
    if (_session != null) {
      try {
        final refreshed = await api.getMe();
        _session = AuthSession(
          token: _session!.token,
          expiresAt: _session!.expiresAt,
          member: refreshed,
        );
        await _store.write(_session!);
      } on ApiException catch (error) {
        _error = error.message;
        _session = null;
        await _store.clear();
      }
    }
    _busy = false;
    _initialized = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _run(() async {
      final next = await api.login(email, password);
      await _setSession(next);
    });
  }

  Future<void> register(JsonMap payload) async {
    await _run(() async {
      final next = await api.register(payload);
      await _setSession(next);
    });
  }

  Future<void> logout() async {
    _busy = true;
    notifyListeners();
    try {
      await api.logout();
    } catch (_) {
      // Local logout still succeeds if the server session is already gone.
    }
    _session = null;
    await _store.clear();
    _busy = false;
    notifyListeners();
  }

  Future<void> expireSession(String message) async {
    _session = null;
    _error = message;
    await _store.clear();
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> syncMember(Member member) async {
    final current = _session;
    if (current == null) return;
    _session = AuthSession(
      token: current.token,
      expiresAt: current.expiresAt,
      member: member,
    );
    await _store.write(_session!);
    notifyListeners();
  }

  Future<void> _setSession(AuthSession session) async {
    _session = session;
    await _store.write(session);
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on ApiException catch (error) {
      _error = error.message;
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    api.close();
    super.dispose();
  }
}

final sessionControllerProvider = ChangeNotifierProvider<SessionController>((
  ref,
) {
  final controller = SessionController();
  controller.restore();
  return controller;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ref.watch(sessionControllerProvider).api;
});
