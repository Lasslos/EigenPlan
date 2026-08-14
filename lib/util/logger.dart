import 'dart:io';

import 'package:http/http.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';

Logger getLogger() {
  return Logger();
}

void logRequestError(String message, Object? error, StackTrace stackTrace) {
  if (error is RPCError) {
    if (error.code == RPCError.invalidClientTime) {
      getLogger().w(message, error: error, stackTrace: stackTrace);
      Sentry.addBreadcrumb(
        Breadcrumb(
          category: 'rpc.error',
          message: '$message: Invalid client time',
          level: SentryLevel.warning,
        ),
      );
    } else if (error.code == RPCError.authenticationFailed) {
      getLogger().w(message, error: error, stackTrace: stackTrace);
      Sentry.addBreadcrumb(
        Breadcrumb(
          category: 'rpc.error',
          message: '$message: Bad credentials',
          level: SentryLevel.warning,
        ),
      );
    } else if (error.code == RPCError.tooManyResults) {
    } else {
      getLogger().e(message, error: error, stackTrace: stackTrace);
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap(
          {
            'message': message,
          },
        ),
      );
    }
  } else if (error is IllegalIdTokenException) {
    getLogger().w(message, error: error, stackTrace: stackTrace);
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'rpc.error',
        message: '$message: $error',
        level: SentryLevel.warning,
      ),
    );
  } else if (error is SocketException) {
    getLogger().w(message, error: error, stackTrace: stackTrace);
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'network.error',
        message: '$message: SocketException',
        level: SentryLevel.warning,
      ),
    );
  } else if (error is HttpException) {
    switch (error.statusCode) {
      case 504:
      case 529:
        getLogger().w('$message: Server down', error: error, stackTrace: stackTrace);
        Sentry.addBreadcrumb(
          Breadcrumb(
            category: 'network.error',
            message: '$message: Server down',
            level: SentryLevel.warning,
          ),
        );
        break;

      default:
        getLogger().e(message, error: error, stackTrace: stackTrace);
        Sentry.captureException(
          error,
          stackTrace: stackTrace,
          hint: Hint.withMap(
            {
              'message': message,
            },
          ),
        );
    }
  } else if (error is ClientException) {
    getLogger().w(message, error: error, stackTrace: stackTrace);
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'network.error',
        message: '$message: ClientException',
        level: SentryLevel.warning,
      ),
    );
  } else {
    getLogger().e(message, error: error, stackTrace: stackTrace);
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: Hint.withMap(
        {
          'message': message,
        },
      ),
    );
  }
}
