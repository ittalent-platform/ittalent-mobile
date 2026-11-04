import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/client.dart';
import '../../../auth/auth_notifier.dart';
import '../../../auth/auth_state.dart';
import 'notifications_constants.dart';
import 'notifications_providers.dart';

class NotificationSseParser {
  const NotificationSseParser._();

  static Stream<Map<String, dynamic>> parse(
    Stream<List<int>> byteStream,
  ) async* {
    final lineStream = byteStream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    String? currentEvent;
    final buffer = StringBuffer();

    await for (final line in lineStream) {
      if (line.isEmpty) {
        if (currentEvent != null && buffer.isNotEmpty) {
          try {
            final dataJson = jsonDecode(buffer.toString());
            yield {'event': currentEvent, 'data': dataJson};
          } catch (_) {}
        }
        currentEvent = null;
        buffer.clear();
      } else if (line.startsWith('event:')) {
        currentEvent = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.write(line.substring(5).trim());
      }
    }
  }
}

class NotificationStreamManager {
  NotificationStreamManager(this.ref) {
    _init();
  }

  final Ref ref;
  CancelToken? _cancelToken;
  bool _isDisposed = false;
  bool _isConnecting = false;

  void _init() {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        _start();
      } else if (next.status == AuthStatus.unauthenticated) {
        _stop();
      }
    }, fireImmediately: true);
  }

  void _start() {
    if (_isConnecting || _isDisposed) return;
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    unawaited(_connectLoop());
  }

  void _stop() {
    _cancelToken?.cancel();
    _cancelToken = null;
    _isConnecting = false;
  }

  Future<void> _connectLoop() async {
    while (!_isDisposed && _cancelToken != null && !_cancelToken!.isCancelled) {
      final authState = ref.read(authNotifierProvider);
      if (authState.status != AuthStatus.authenticated) break;

      _isConnecting = true;
      try {
        final dio = ref.read(dioProvider);
        final response = await dio.get<ResponseBody>(
          NotificationConstants.streamPath,
          options: Options(
            responseType: ResponseType.stream,
            headers: {
              'Accept': 'text/event-stream',
              'Cache-Control': 'no-cache',
            },
          ),
          cancelToken: _cancelToken,
        );

        final stream = response.data?.stream;
        if (stream != null) {
          await for (final event in NotificationSseParser.parse(stream)) {
            if (_isDisposed || _cancelToken?.isCancelled == true) break;

            if (event['event'] == 'notification' &&
                event['data'] is Map<String, dynamic>) {
              final raw = event['data'] as Map<String, dynamic>;
              final item = NotificationItem.fromJson(raw);

              // Update badge counter
              ref.read(unreadCountProvider.notifier).increment(1);

              // Update live feed list if active
              ref
                  .read(notificationsFeedProvider.notifier)
                  .addLiveNotification(item);
            }
          }
        }
      } catch (e) {
        // Ignored or backoff
      } finally {
        _isConnecting = false;
      }

      if (_isDisposed || _cancelToken?.isCancelled == true) break;
      // Reconnection backoff interval (5 seconds)
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }

  void dispose() {
    _isDisposed = true;
    _stop();
  }
}

final notificationStreamManagerProvider = Provider<NotificationStreamManager>((
  ref,
) {
  final manager = NotificationStreamManager(ref);
  ref.onDispose(manager.dispose);
  return manager;
});
