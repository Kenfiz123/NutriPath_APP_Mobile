typedef JsonMap = Map<String, dynamic>;

JsonMap asJsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, dynamic item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

List<JsonMap> jsonMapList(Object? value) {
  if (value is! List) return <JsonMap>[];
  return value.map(asJsonMap).toList();
}

String asString(Object? value, [String fallback = '']) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

int asInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double asDouble(Object? value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool asBool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return fallback;
}

List<String> stringList(Object? value) {
  if (value is! List) return <String>[];
  return value.map((item) => item.toString()).toList();
}

List<JsonMap> embeddedList(JsonMap json, String key) {
  return jsonMapList(asJsonMap(json['_embedded'])[key]);
}

class MacroTargets {
  const MacroTargets({
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.calories = 0,
    this.waterMl = 0,
    this.waterGlasses = 0,
  });

  factory MacroTargets.fromJson(Object? value) {
    final json = asJsonMap(value);
    final waterGlasses = asDouble(json['waterGlasses']);
    return MacroTargets(
      protein: asDouble(json['protein']),
      carbs: asDouble(json['carbs']),
      fat: asDouble(json['fat']),
      calories: asDouble(json['calories']),
      waterMl: asDouble(json['waterMl'], waterGlasses * 250),
      waterGlasses: waterGlasses,
    );
  }

  final double protein;
  final double carbs;
  final double fat;
  final double calories;
  final double waterMl;
  final double waterGlasses;
}

class MemberAccess {
  const MemberAccess({
    this.tier = 'free',
    this.recipeLimit,
    this.advancedAiContext = false,
    this.aiCoach = false,
    this.mealHistoryDays = 3,
    this.mealItemsPerDay = 12,
    this.analyticsWindowDays = 7,
    this.reportExports = false,
  });

  factory MemberAccess.fromJson(Object? value) {
    final json = asJsonMap(value);
    return MemberAccess(
      tier: asString(json['tier'], 'free'),
      recipeLimit: json['recipeLimit'] == null
          ? null
          : asInt(json['recipeLimit']),
      advancedAiContext: asBool(json['advancedAiContext']),
      aiCoach: asBool(json['aiCoach']),
      mealHistoryDays: asInt(json['mealHistoryDays'], 3),
      mealItemsPerDay: asInt(json['mealItemsPerDay'], 12),
      analyticsWindowDays: asInt(json['analyticsWindowDays'], 7),
      reportExports: asBool(json['reportExports']),
    );
  }

  final String tier;
  final int? recipeLimit;
  final bool advancedAiContext;
  final bool aiCoach;
  final int mealHistoryDays;
  final int mealItemsPerDay;
  final int analyticsWindowDays;
  final bool reportExports;
}

class Subscription {
  const Subscription({
    this.planId = 'free',
    this.billing = 'monthly',
    this.status = 'active',
    this.startedAt = '',
    this.purchaseAt,
    this.renewsAt,
    this.daysTotal,
    this.daysRemaining,
  });

  factory Subscription.fromJson(Object? value) {
    final json = asJsonMap(value);
    return Subscription(
      planId: asString(json['planId'], 'free'),
      billing: asString(json['billing'], 'monthly'),
      status: asString(json['status'], 'active'),
      startedAt: asString(json['startedAt']),
      purchaseAt: json['purchaseAt']?.toString(),
      renewsAt: json['renewsAt']?.toString(),
      daysTotal: json['daysTotal'] == null ? null : asInt(json['daysTotal']),
      daysRemaining: json['daysRemaining'] == null
          ? null
          : asInt(json['daysRemaining']),
    );
  }

  final String planId;
  final String billing;
  final String status;
  final String startedAt;
  final String? purchaseAt;
  final String? renewsAt;
  final int? daysTotal;
  final int? daysRemaining;
}

class Member {
  const Member({
    required this.id,
    required this.name,
    required this.email,
    this.initials = 'U',
    this.role = 'member',
    this.status = 'active',
    this.tier = 'free',
    this.joinedAt = '',
    this.calorieTarget = 1800,
    this.macroTargets = const MacroTargets(protein: 120, carbs: 220, fat: 60),
    this.waterTargetGlasses = 8,
    this.gender,
    this.age,
    this.weightKg,
    this.heightCm,
    this.activityLevel,
    this.goal,
    this.access,
    this.subscription,
    this.stats = const <String, dynamic>{},
  });

  factory Member.fromJson(Object? value) {
    final json = asJsonMap(value);
    return Member(
      id: asString(json['id']),
      name: asString(json['name'], 'User'),
      email: asString(json['email']),
      initials: asString(json['initials'], 'U'),
      role: asString(json['role'], 'member').toLowerCase(),
      status: asString(json['status'], 'active'),
      tier: asString(json['tier'], 'free').toLowerCase(),
      joinedAt: asString(json['joinedAt']),
      calorieTarget: asInt(json['calorieTarget'], 1800),
      macroTargets: MacroTargets.fromJson(json['macroTargets']),
      waterTargetGlasses: asInt(json['waterTargetGlasses'], 8),
      gender: json['gender']?.toString(),
      age: json['age'] == null ? null : asInt(json['age']),
      weightKg: json['weightKg'] == null ? null : asDouble(json['weightKg']),
      heightCm: json['heightCm'] == null ? null : asDouble(json['heightCm']),
      activityLevel: json['activityLevel']?.toString(),
      goal: json['goal']?.toString(),
      access: json['access'] == null
          ? null
          : MemberAccess.fromJson(json['access']),
      subscription: json['subscription'] == null
          ? null
          : Subscription.fromJson(json['subscription']),
      stats: asJsonMap(json['stats']),
    );
  }

  JsonMap toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'email': email,
    'initials': initials,
    'role': role,
    'status': status,
    'tier': tier,
    'joinedAt': joinedAt,
    'calorieTarget': calorieTarget,
    'macroTargets': {
      'protein': macroTargets.protein,
      'carbs': macroTargets.carbs,
      'fat': macroTargets.fat,
    },
    'waterTargetGlasses': waterTargetGlasses,
    'gender': gender,
    'age': age,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'activityLevel': activityLevel,
    'goal': goal,
    'access': access == null
        ? null
        : {
            'tier': access!.tier,
            'recipeLimit': access!.recipeLimit,
            'advancedAiContext': access!.advancedAiContext,
            'aiCoach': access!.aiCoach,
            'mealHistoryDays': access!.mealHistoryDays,
            'mealItemsPerDay': access!.mealItemsPerDay,
            'analyticsWindowDays': access!.analyticsWindowDays,
            'reportExports': access!.reportExports,
          },
    'subscription': subscription == null
        ? null
        : {
            'planId': subscription!.planId,
            'billing': subscription!.billing,
            'status': subscription!.status,
            'startedAt': subscription!.startedAt,
            'purchaseAt': subscription!.purchaseAt,
            'renewsAt': subscription!.renewsAt,
            'daysTotal': subscription!.daysTotal,
            'daysRemaining': subscription!.daysRemaining,
          },
    'stats': stats,
  };

  Member copyWith({String? name, String? email, String? tier}) {
    return Member(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      initials: initials,
      role: role,
      status: status,
      tier: tier ?? this.tier,
      joinedAt: joinedAt,
      calorieTarget: calorieTarget,
      macroTargets: macroTargets,
      waterTargetGlasses: waterTargetGlasses,
      gender: gender,
      age: age,
      weightKg: weightKg,
      heightCm: heightCm,
      activityLevel: activityLevel,
      goal: goal,
      access: access,
      subscription: subscription,
      stats: stats,
    );
  }

  final String id;
  final String name;
  final String email;
  final String initials;
  final String role;
  final String status;
  final String tier;
  final String joinedAt;
  final int calorieTarget;
  final MacroTargets macroTargets;
  final int waterTargetGlasses;
  final String? gender;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final String? activityLevel;
  final String? goal;
  final MemberAccess? access;
  final Subscription? subscription;
  final JsonMap stats;

  bool get isAdmin => role == 'admin';
  bool get isSvip => tier == 'svip';
  bool get canUseCoach => access?.aiCoach ?? isSvip;
  bool get canExportReports => access?.reportExports ?? isSvip;
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.member,
    this.expiresAt,
  });

  factory AuthSession.fromJson(Object? value) {
    final json = asJsonMap(value);
    return AuthSession(
      token: asString(json['token']),
      expiresAt: json['expiresAt']?.toString(),
      member: Member.fromJson(json['member']),
    );
  }

  JsonMap toJson() => <String, dynamic>{
    'token': token,
    'expiresAt': expiresAt,
    'member': member.toJson(),
  };

  final String token;
  final String? expiresAt;
  final Member member;
}

class Food {
  const Food({
    required this.id,
    required this.name,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.portion = '',
    this.category = '',
  });

  factory Food.fromJson(Object? value) {
    final json = asJsonMap(value);
    return Food(
      id: asString(json['id']),
      name: asString(json['name'], 'Món ăn'),
      calories: asDouble(json['calories']),
      protein: asDouble(json['protein']),
      carbs: asDouble(json['carbs']),
      fat: asDouble(json['fat']),
      portion: asString(json['portion'], '1 phần'),
      category: asString(json['category']),
    );
  }

  JsonMap toMealPayload({double quantity = 1}) => <String, dynamic>{
    'name': name,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'portion': portion,
    'quantity': quantity,
  };

  final String id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String portion;
  final String category;
}

class MealItem extends Food {
  const MealItem({
    required super.id,
    required super.name,
    super.calories,
    super.protein,
    super.carbs,
    super.fat,
    super.portion,
    super.category,
    this.quantity = 1,
    this.foodId,
  });

  factory MealItem.fromJson(Object? value) {
    final json = asJsonMap(value);
    return MealItem(
      id: asString(json['id'], asString(json['foodId'])),
      foodId: json['foodId']?.toString(),
      name: asString(json['name'], 'Món ăn'),
      calories: asDouble(json['calories']),
      protein: asDouble(json['protein']),
      carbs: asDouble(json['carbs']),
      fat: asDouble(json['fat']),
      portion: asString(json['portion'], '1 phần'),
      quantity: asDouble(json['quantity'], 1),
      category: asString(json['category']),
    );
  }

  final double quantity;
  final String? foodId;
}

class MealSection {
  const MealSection({
    required this.id,
    required this.name,
    this.icon = '',
    this.targetKcal = 0,
    this.time = '',
    this.items = const <MealItem>[],
  });

  factory MealSection.fromJson(Object? value) {
    final json = asJsonMap(value);
    return MealSection(
      id: asString(json['id']),
      name: asString(json['name'], 'Bữa ăn'),
      icon: asString(json['icon']),
      targetKcal: asDouble(json['targetKcal']),
      time: asString(json['time']),
      items: jsonMapList(json['items']).map(MealItem.fromJson).toList(),
    );
  }

  final String id;
  final String name;
  final String icon;
  final double targetKcal;
  final String time;
  final List<MealItem> items;

  double get totalCalories =>
      items.fold<double>(0, (sum, item) => sum + item.calories);
}

class MealSummary {
  const MealSummary({
    this.totals = const MacroTargets(),
    this.targets = const MacroTargets(),
    this.remainingCalories = 0,
    this.calorieProgressPct = 0,
  });

  factory MealSummary.fromJson(Object? value) {
    final json = asJsonMap(value);
    return MealSummary(
      totals: MacroTargets.fromJson(json['totals']),
      targets: MacroTargets.fromJson(json['targets']),
      remainingCalories: asDouble(json['remainingCalories']),
      calorieProgressPct: asInt(json['calorieProgressPct']),
    );
  }

  final MacroTargets totals;
  final MacroTargets targets;
  final double remainingCalories;
  final int calorieProgressPct;
}

class MealLog {
  const MealLog({
    required this.id,
    required this.memberId,
    required this.date,
    this.waterMl = 0,
    this.waterGlasses = 0,
    this.activity = const <String, dynamic>{},
    this.goals = const <JsonMap>[],
    this.meals = const <MealSection>[],
    this.summary = const MealSummary(),
    this.access,
  });

  factory MealLog.fromJson(Object? value) {
    final json = asJsonMap(value);
    final waterGlasses = asInt(json['waterGlasses']);
    return MealLog(
      id: asString(json['id']),
      memberId: asString(json['memberId']),
      date: asString(json['date']),
      waterMl: asInt(json['waterMl'], waterGlasses * 250),
      waterGlasses: waterGlasses,
      activity: asJsonMap(json['activity']),
      goals: jsonMapList(json['goals']),
      meals: jsonMapList(json['meals']).map(MealSection.fromJson).toList(),
      summary: MealSummary.fromJson(json['summary']),
      access: json['access'] == null
          ? null
          : MemberAccess.fromJson(json['access']),
    );
  }

  final String id;
  final String memberId;
  final String date;
  final int waterMl;
  final int waterGlasses;
  final JsonMap activity;
  final List<JsonMap> goals;
  final List<MealSection> meals;
  final MealSummary summary;
  final MemberAccess? access;
}

class DashboardData {
  const DashboardData({
    required this.date,
    required this.greeting,
    required this.member,
    required this.nutrition,
    required this.mealLog,
    this.weeklyProgress = const <JsonMap>[],
    this.tips = const <String>[],
    this.achievements = const <JsonMap>[],
  });

  factory DashboardData.fromJson(Object? value) {
    final json = asJsonMap(value);
    return DashboardData(
      date: asString(json['date']),
      greeting: asString(json['greeting'], 'Xin chào'),
      member: Member.fromJson(json['member']),
      nutrition: MealSummary.fromJson(json['nutrition']),
      mealLog: MealLog.fromJson(json['mealLog']),
      weeklyProgress: jsonMapList(json['weeklyProgress']),
      tips: stringList(json['tips']),
      achievements: jsonMapList(json['achievements']),
    );
  }

  final String date;
  final String greeting;
  final Member member;
  final MealSummary nutrition;
  final MealLog mealLog;
  final List<JsonMap> weeklyProgress;
  final List<String> tips;
  final List<JsonMap> achievements;
}

class CalorieCalculation {
  const CalorieCalculation({
    required this.input,
    required this.results,
    this.aiInsight,
  });

  factory CalorieCalculation.fromJson(Object? value) {
    final json = asJsonMap(value);
    return CalorieCalculation(
      input: asJsonMap(json['input']),
      results: asJsonMap(json['results']),
      aiInsight: json['aiInsight'] == null
          ? null
          : asJsonMap(json['aiInsight']),
    );
  }

  final JsonMap input;
  final JsonMap results;
  final JsonMap? aiInsight;
}

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    this.image = '',
    this.timeMinutes = 0,
    this.calories = 0,
    this.difficulty = 0,
    this.tags = const <String>[],
    this.servings = 1,
    this.ingredients = const <JsonMap>[],
    this.steps = const <String>[],
    this.nutrition = const <String, dynamic>{},
    this.notes = const <String>[],
    this.personalizationSummary = '',
  });

  factory Recipe.fromJson(Object? value) {
    final json = asJsonMap(value);
    return Recipe(
      id: asString(json['id']),
      name: asString(json['name'], 'Công thức'),
      image: asString(json['image']),
      timeMinutes: asInt(json['timeMinutes']),
      calories: asDouble(json['calories']),
      difficulty: asInt(json['difficulty']),
      tags: stringList(json['tags']),
      servings: asInt(json['servings'], 1),
      ingredients: jsonMapList(json['ingredients']),
      steps: stringList(json['steps']),
      nutrition: asJsonMap(json['nutrition']),
      notes: stringList(json['notes']),
      personalizationSummary: asString(json['personalizationSummary']),
    );
  }

  final String id;
  final String name;
  final String image;
  final int timeMinutes;
  final double calories;
  final int difficulty;
  final List<String> tags;
  final int servings;
  final List<JsonMap> ingredients;
  final List<String> steps;
  final JsonMap nutrition;
  final List<String> notes;
  final String personalizationSummary;
}

class RecipeCollection {
  const RecipeCollection({
    this.recipes = const <Recipe>[],
    this.tags = const <String>[],
    this.access,
  });

  factory RecipeCollection.fromJson(Object? value) {
    final json = asJsonMap(value);
    return RecipeCollection(
      recipes: embeddedList(json, 'recipes').map(Recipe.fromJson).toList(),
      tags: stringList(json['tags']),
      access: json['access'] == null
          ? null
          : MemberAccess.fromJson(json['access']),
    );
  }

  final List<Recipe> recipes;
  final List<String> tags;
  final MemberAccess? access;
}

class Plan {
  const Plan({
    required this.id,
    required this.name,
    this.monthlyPrice = 0,
    this.period = '',
    this.description = '',
    this.features = const <JsonMap>[],
    this.pricePreview,
  });

  factory Plan.fromJson(Object? value) {
    final json = asJsonMap(value);
    return Plan(
      id: asString(json['id'], 'free'),
      name: asString(json['name'], 'Gói'),
      monthlyPrice: asDouble(json['monthlyPrice']),
      period: asString(json['period']),
      description: asString(json['description']),
      features: jsonMapList(json['features']),
      pricePreview: json['pricePreview'] == null
          ? null
          : CheckoutQuote.fromJson(json['pricePreview']),
    );
  }

  final String id;
  final String name;
  final double monthlyPrice;
  final String period;
  final String description;
  final List<JsonMap> features;
  final CheckoutQuote? pricePreview;
}

class CheckoutQuote {
  const CheckoutQuote({
    required this.planId,
    required this.planName,
    this.billing = 'monthly',
    this.months = 1,
    this.currency = 'VND',
    this.monthlyPrice = 0,
    this.subtotal = 0,
    this.vat = 0,
    this.discountCode,
    this.discountAmount = 0,
    this.total = 0,
    this.trialDays = 0,
  });

  factory CheckoutQuote.fromJson(Object? value) {
    final json = asJsonMap(value);
    return CheckoutQuote(
      planId: asString(json['planId']),
      planName: asString(json['planName'], asString(json['name'])),
      billing: asString(json['billing'], 'monthly'),
      months: asInt(json['months'], 1),
      currency: asString(json['currency'], 'VND'),
      monthlyPrice: asDouble(json['monthlyPrice']),
      subtotal: asDouble(json['subtotal']),
      vat: asDouble(json['vat']),
      discountCode: json['discountCode']?.toString(),
      discountAmount: asDouble(json['discountAmount']),
      total: asDouble(json['total']),
      trialDays: asInt(json['trialDays']),
    );
  }

  final String planId;
  final String planName;
  final String billing;
  final int months;
  final String currency;
  final double monthlyPrice;
  final double subtotal;
  final double vat;
  final String? discountCode;
  final double discountAmount;
  final double total;
  final int trialDays;
}

class Payment {
  const Payment({
    required this.id,
    required this.memberId,
    required this.invoice,
    required this.planId,
    required this.billing,
    this.paymentMethod,
    this.amount = 0,
    this.currency = 'VND',
    this.status = '',
    this.paidAt = '',
  });

  factory Payment.fromJson(Object? value) {
    final json = asJsonMap(value);
    return Payment(
      id: asString(json['id']),
      memberId: asString(json['memberId']),
      invoice: asString(json['invoice']),
      planId: asString(json['planId']),
      billing: asString(json['billing']),
      paymentMethod: json['paymentMethod']?.toString(),
      amount: asDouble(json['amount']),
      currency: asString(json['currency'], 'VND'),
      status: asString(json['status']),
      paidAt: asString(json['paidAt']),
    );
  }

  final String id;
  final String memberId;
  final String invoice;
  final String planId;
  final String billing;
  final String? paymentMethod;
  final double amount;
  final String currency;
  final String status;
  final String paidAt;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.text,
    this.priority = 'normal',
    this.readAt,
    this.createdAt = '',
  });

  factory AppNotification.fromJson(Object? value) {
    final json = asJsonMap(value);
    return AppNotification(
      id: asString(json['id']),
      title: asString(json['title'], 'Thông báo'),
      text: asString(json['text']),
      priority: asString(json['priority'], 'normal'),
      readAt: json['readAt']?.toString(),
      createdAt: asString(json['createdAt']),
    );
  }

  final String id;
  final String title;
  final String text;
  final String priority;
  final String? readAt;
  final String createdAt;
}

class NutritionReport {
  const NutritionReport({
    this.range = const <String, dynamic>{},
    this.access,
    this.targets = const MacroTargets(),
    this.totals = const <String, dynamic>{},
    this.averages = const <String, dynamic>{},
    this.adherence = const <String, dynamic>{},
    this.daily = const <JsonMap>[],
    this.mealBreakdown = const <JsonMap>[],
    this.topFoods = const <JsonMap>[],
    this.insights = const <String>[],
    this.generatedAt = '',
  });

  factory NutritionReport.fromJson(Object? value) {
    final json = asJsonMap(value);
    return NutritionReport(
      range: asJsonMap(json['range']),
      access: json['access'] == null
          ? null
          : MemberAccess.fromJson(json['access']),
      targets: MacroTargets.fromJson(json['targets']),
      totals: asJsonMap(json['totals']),
      averages: asJsonMap(json['averages']),
      adherence: asJsonMap(json['adherence']),
      daily: jsonMapList(json['daily']),
      mealBreakdown: jsonMapList(json['mealBreakdown']),
      topFoods: jsonMapList(json['topFoods']),
      insights: stringList(json['insights']),
      generatedAt: asString(json['generatedAt']),
    );
  }

  final JsonMap range;
  final MemberAccess? access;
  final MacroTargets targets;
  final JsonMap totals;
  final JsonMap averages;
  final JsonMap adherence;
  final List<JsonMap> daily;
  final List<JsonMap> mealBreakdown;
  final List<JsonMap> topFoods;
  final List<String> insights;
  final String generatedAt;
}

class WeeklyCoachPlan {
  const WeeklyCoachPlan({
    required this.id,
    required this.memberId,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.targetCalories = 0,
    this.macroTargets = const MacroTargets(),
    this.summary = '',
    this.actionSteps = const <String>[],
    this.days = const <CoachPlanDay>[],
    this.generatedAt = '',
    this.generatedBy = '',
  });

  factory WeeklyCoachPlan.fromJson(Object? value) {
    final json = asJsonMap(value);
    return WeeklyCoachPlan(
      id: asString(json['id']),
      memberId: asString(json['memberId']),
      title: asString(json['title'], 'Kế hoạch AI Coach'),
      startDate: asString(json['startDate']),
      endDate: asString(json['endDate']),
      targetCalories: asDouble(json['targetCalories']),
      macroTargets: MacroTargets.fromJson(json['macroTargets']),
      summary: asString(json['summary']),
      actionSteps: stringList(json['actionSteps']),
      days: jsonMapList(json['days']).map(CoachPlanDay.fromJson).toList(),
      generatedAt: asString(json['generatedAt']),
      generatedBy: asString(json['generatedBy']),
    );
  }

  final String id;
  final String memberId;
  final String title;
  final String startDate;
  final String endDate;
  final double targetCalories;
  final MacroTargets macroTargets;
  final String summary;
  final List<String> actionSteps;
  final List<CoachPlanDay> days;
  final String generatedAt;
  final String generatedBy;
}

class CoachPlanDay {
  const CoachPlanDay({
    required this.date,
    required this.label,
    this.targetCalories = 0,
    this.focus = '',
    this.meals = const <CoachPlanMeal>[],
  });

  factory CoachPlanDay.fromJson(Object? value) {
    final json = asJsonMap(value);
    return CoachPlanDay(
      date: asString(json['date']),
      label: asString(json['label']),
      targetCalories: asDouble(json['targetCalories']),
      focus: asString(json['focus']),
      meals: jsonMapList(json['meals']).map(CoachPlanMeal.fromJson).toList(),
    );
  }

  final String date;
  final String label;
  final double targetCalories;
  final String focus;
  final List<CoachPlanMeal> meals;
}

class CoachPlanMeal {
  const CoachPlanMeal({
    required this.name,
    required this.time,
    required this.suggestion,
    this.calories = 0,
  });

  factory CoachPlanMeal.fromJson(Object? value) {
    final json = asJsonMap(value);
    return CoachPlanMeal(
      name: asString(json['name'], 'Bữa ăn'),
      time: asString(json['time']),
      suggestion: asString(json['suggestion']),
      calories: asDouble(json['calories']),
    );
  }

  final String name;
  final String time;
  final String suggestion;
  final double calories;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
  });

  factory ChatMessage.fromJson(Object? value) {
    final json = asJsonMap(value);
    return ChatMessage(
      id: asString(json['id']),
      sender: asString(json['sender'], 'ai'),
      text: asString(json['text']),
      time: asString(json['time']),
    );
  }

  final String id;
  final String sender;
  final String text;
  final String time;
}

class AdminOverview {
  const AdminOverview({
    this.kpis = const <JsonMap>[],
    this.systemServices = const <JsonMap>[],
    this.recentUsers = const <JsonMap>[],
    this.roleBreakdown = const <JsonMap>[],
    this.tierBreakdown = const <JsonMap>[],
    this.topRecipes = const <JsonMap>[],
  });

  factory AdminOverview.fromJson(Object? value) {
    final json = asJsonMap(value);
    return AdminOverview(
      kpis: jsonMapList(json['kpis']),
      systemServices: jsonMapList(json['systemServices']),
      recentUsers: jsonMapList(json['recentUsers']),
      roleBreakdown: jsonMapList(json['roleBreakdown']),
      tierBreakdown: jsonMapList(json['tierBreakdown']),
      topRecipes: jsonMapList(json['topRecipes']),
    );
  }

  final List<JsonMap> kpis;
  final List<JsonMap> systemServices;
  final List<JsonMap> recentUsers;
  final List<JsonMap> roleBreakdown;
  final List<JsonMap> tierBreakdown;
  final List<JsonMap> topRecipes;
}
