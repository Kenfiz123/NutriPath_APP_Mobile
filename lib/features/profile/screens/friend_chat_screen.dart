import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../core/app_services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';

class FriendChatScreen extends ConsumerStatefulWidget {
  const FriendChatScreen({required this.friendId, super.key});

  final String friendId;

  @override
  ConsumerState<FriendChatScreen> createState() => _FriendChatScreenState();
}

class _FriendChatScreenState extends ConsumerState<FriendChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _fallbackTimer;
  Timer? _reconnectTimer;
  http.Client? _sseClient;
  bool _sending = false;
  bool _sseConnected = false;
  int _reconnectAttempt = 0;
  static const _maxBackoffSeconds = 30;
  int _lastMsgCount = 0;

  List<FriendChatMessage> _messages = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialHistory();
    _startSseListener();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_sseConnected) {
        _pollChatHistorySilent();
      }
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _reconnectTimer?.cancel();
    _sseClient?.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialHistory() async {
    try {
      final list = await ref
          .read(apiClientProvider)
          .getFriendChatHistory(widget.friendId);
      if (mounted) {
        setState(() {
          _messages = list;
          _loading = false;
          _lastMsgCount = list.length;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _pollChatHistorySilent() async {
    try {
      final list = await ref
          .read(apiClientProvider)
          .getFriendChatHistory(widget.friendId);
      if (mounted) {
        setState(() {
          for (final msg in list) {
            if (!_messages.any((m) => m.id == msg.id)) {
              _messages.add(msg);
            }
          }
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          if (_messages.length > _lastMsgCount) {
            _lastMsgCount = _messages.length;
            WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
            );
          }
        });
      }
    } catch (_) {}
  }

  void _startSseListener() async {
    _sseClient = http.Client();
    try {
      final token = ref.read(sessionControllerProvider).session?.token ?? '';
      final request = http.Request(
        'GET',
        Uri.parse(
          '${AppConfig.apiBaseUrl}/api/friends/chats/${widget.friendId}/stream',
        ),
      );
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final response = await _sseClient!.send(request);
      if (response.statusCode != 200) {
        _reconnectSse();
        return;
      }

      _sseConnected = true;
      _reconnectAttempt = 0;

      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
          if (line.startsWith('data: ')) {
            final dataStr = line.substring(6).trim();
            if (dataStr == 'connected') return;
            try {
              final newMsg = FriendChatMessage.fromJson(
                jsonDecode(dataStr),
              );
              if (mounted) {
                setState(() {
                  if (!_messages.any((m) => m.id == newMsg.id)) {
                    _messages.add(newMsg);
                    _messages.sort(
                          (a, b) => a.createdAt.compareTo(b.createdAt),
                    );
                  }
                  if (_messages.length > _lastMsgCount) {
                    _lastMsgCount = _messages.length;
                    WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _scrollToBottom(),
                    );
                  }
                });
              }
            } catch (_) {}
          }
        },
        onError: (e) {
          _sseConnected = false;
          _reconnectSse();
        },
        onDone: () {
          _sseConnected = false;
          _reconnectSse();
        },
        cancelOnError: true,
      );
    } catch (_) {
      _sseConnected = false;
      _reconnectSse();
    }
  }

  void _reconnectSse() {
    _sseClient?.close();
    _reconnectTimer?.cancel();
    if (!mounted) return;
    // Exponential backoff (2s, 4s, 8s, 16s, capped at 30s) so a persistently
    // unreachable server doesn't get hammered with reconnect attempts.
    final delaySeconds = (2 << _reconnectAttempt).clamp(2, _maxBackoffSeconds).toInt();
    if (_reconnectAttempt < 10) _reconnectAttempt++;
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (mounted) {
        _startSseListener();
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncProfile = ref.watch(publicProfileProvider(widget.friendId));
    final myId = ref.read(sessionControllerProvider).session?.member.id ?? '';

    final friendName = asyncProfile.maybeWhen(
      data: (p) => p.name,
      orElse: () => 'Đang tải...',
    );

    final initials = asyncProfile.maybeWhen(
      data: (p) => p.initials,
      orElse: () => '?',
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                friendName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.friends);
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildChatBody(myId)),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildChatBody(String myId) {
    if (_loading && _messages.isEmpty) {
      return const LoadingPanel();
    }
    if (_error != null && _messages.isEmpty) {
      return Center(
        child: Text(
          'Lỗi tải tin nhắn: ${readableError(_error!)}',
          style: const TextStyle(color: AppColors.red),
        ),
      );
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Chưa có tin nhắn nào. Hãy gửi lời chào đầu tiên!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg.senderId == myId;
        return _buildMessageBubble(msg, isMe);
      },
    );
  }

  Widget _buildMessageBubble(FriendChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 16),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    isDense: true,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.4,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton.filled(
                tooltip: 'Gửi',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
                  disabledForegroundColor: Colors.white70,
                ),
                icon: _sending
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.send_rounded),
                onPressed: _sending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _sending = true;
    });

    try {
      await ref
          .read(apiClientProvider)
          .sendFriendChatMessage(widget.friendId, text);
      _messageController.clear();
      _pollChatHistorySilent();
    } catch (e) {
      if (mounted) showSnack(context, readableError(e));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }
}