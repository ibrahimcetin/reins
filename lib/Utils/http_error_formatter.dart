import 'dart:async';
import 'dart:io';

/// A utility class for formatting HTTP errors and exceptions into human-readable messages.
///
/// Provides static methods to convert common network exceptions and HTTP status codes
/// into user-friendly error messages.
class HttpErrorFormatter {
  HttpErrorFormatter._(); // Private constructor - use static methods

  /// Converts common exceptions to human-readable error messages.
  static String formatException(Object error) {
    if (error is TimeoutException) {
      return 'Connection timed out. Please check if the server is running.';
    } else if (error is SocketException) {
      final message = error.message.toLowerCase();
      if (message.contains('no route to host') || message.contains('network is unreachable')) {
        return 'Network unreachable. Please check your internet connection.';
      } else if (message.contains('connection refused')) {
        return 'Connection refused. The server may not be running.';
      } else if (message.contains('no address associated') || message.contains('failed host lookup')) {
        return 'Could not find server. Please verify the server address in settings.';
      }
      return 'Network error: ${error.message}';
    } else if (error is HttpException) {
      return 'HTTP error: ${error.message}';
    } else if (error is FormatException) {
      return 'Invalid server address format. Please check the server configuration.';
    } else if (error is HandshakeException) {
      return 'SSL/TLS handshake failed. Check server certificate.';
    } else if (error is TlsException) {
      return 'Secure connection failed. Check server certificate.';
    }
    return 'Connection failed: ${error.toString()}';
  }

  /// Converts HTTP status codes to human-readable error messages.
  ///
  /// [statusCode] is the HTTP status code returned by the server.
  /// [body] is the optional response body that will be appended to the message.
  ///
  /// Returns a formatted error message with the status code and optional body.
  static String formatHttpError(int statusCode, {String? body}) {
    final reason = switch (statusCode) {
      400 => 'Bad request. Please check the server address.',
      401 => 'Unauthorized. Please check your API key.',
      403 => 'Access forbidden. You don\'t have permission to access this server.',
      404 => 'Resource not found. The requested model or endpoint does not exist.',
      408 => 'Request timed out. Please try again.',
      429 => 'Too many requests. Please wait and try again.',
      500 => 'Internal server error. The server encountered a problem.',
      502 => 'Bad gateway. There may be a problem with the server or proxy',
      503 => 'Service unavailable. The server is temporarily down.',
      504 => 'Gateway timeout. The server took too long to respond.',
      _ => 'Server returned an error.',
    };

    final trimmedBody = body?.trim();

    if (trimmedBody == null || trimmedBody.isEmpty) {
      return '$reason\n(HTTP $statusCode)';
    }

    return '$reason\n(HTTP $statusCode)\n\n$trimmedBody';
  }
}
