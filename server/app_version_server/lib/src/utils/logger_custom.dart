import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:shelf/shelf.dart';

/// Красивый логгер для Shelf-сервера в стиле PrettyDioLogger
///
/// Пример использования:
/// ```dart
/// final logger = PrettyShelfLogger(
///   debugMode: true,
///   requestHeader: true,
///   requestBody: true,
///   responseBody: true,
/// );
///
/// final handler = Pipeline()
///     .addMiddleware(logger.middleware)
///     .addHandler(router);
/// ```
class PrettyShelfLogger {
  final bool debugMode;
  final bool request;
  final bool requestHeader;
  final bool requestBody;
  final bool responseBody;
  final bool responseHeader;
  final bool error;
  final int maxWidth;
  final bool compact;
  final void Function(Object object)? onLogPrint;
  final void Function(String object)? onViewFullJson;

  static const int _initialTab = 1;
  static const String _tabStep = '    ';

  PrettyShelfLogger({
    this.debugMode = false,
    this.request = true,
    this.requestHeader = false,
    this.requestBody = false,
    this.responseHeader = false,
    this.responseBody = true,
    this.error = true,
    this.maxWidth = 90,
    this.compact = true,
    this.onLogPrint,
    this.onViewFullJson,
  });

  Middleware get middleware {
    return (Handler innerHandler) {
      return (Request request) async {
        if (debugMode && this.request) {
          _logRequest(request);
        }

        try {
          final response = await innerHandler(request);

          if (debugMode) {
            await _logResponse(response);
          }

          return response;
        } catch (e, stackTrace) {
          if (debugMode && this.error) {
            _logError(e, stackTrace);
          }
          return Response.internalServerError(body: 'Error: ${e.toString()}');
        }
      };
    };
  }

  void _logRequest(Request request) async {
    _printBoxed(
      header: 'Request ║ ${request.method}',
      text: request.requestedUri.toString(),
    );

    if (requestHeader && request.headers.isNotEmpty) {
      _printMapAsTable(request.headers, header: 'Headers');
    }

    if (requestBody && request.method != 'GET') {
      await _printRequestBody(request);
    }
  }

  Future<void> _logResponse(Response response) async {
    final cachedResponse = await _cacheResponse(response);

    _printBoxed(
      header: 'Response ║ Status: ${cachedResponse.statusCode}',
      text: '',
    );

    if (responseHeader && cachedResponse.headersAll.isNotEmpty) {
      _printMapAsTable(cachedResponse.headersAll, header: 'Response Headers');
    }

    if (responseBody) {
      await _printResponseBody(cachedResponse);
    }
  }

  Future<Response> _cacheResponse(Response response) async {
    // ignore: inference_failure_on_untyped_parameter
    final body = await response.readAsString().catchError((e) {
      developer.log('Error reading response body: $e');
      return 'Error!';
    });
    return response.change(body: body);
  }

  void _logError(dynamic e, StackTrace stackTrace) {
    _printBoxed(
      header: 'Error ║ ${e.runtimeType}',
      text: '$e\n${stackTrace.toString()}',
    );
  }

  Future<void> _printRequestBody(Request request) async {
    try {
      if (request.method != 'GET') {
        final body = await request.readAsString();
        if (body.isNotEmpty) {
          _printBlock('Body:');
          _printJsonOrText(body);
        }
      }
    } catch (e) {
      _printBlock('Error reading request body: $e');
    }
  }

  Future<void> _printResponseBody(Response response) async {
    try {
      final body = await response.readAsString();
      if (body.isNotEmpty) {
        _printBlock('Response Body:');
        _printJsonOrText(body);
      }
    } catch (e) {
      _printBlock('Error reading response body: $e');
    }
  }

  void _printJsonOrText(String content) {
    try {
      final jsonData = jsonDecode(content);
      if (jsonData is Map<String, dynamic>) {
        _printPrettyMap(jsonData);
      } else if (jsonData is List) {
        _printList(jsonData);
      } else {
        _printBlock(content);
      }
    } catch (e) {
      _printBlock(content);
    }
  }

  void _printBoxed({required String header, String? text}) {
    _logPrint('');
    _logPrint('╔╣ $header');
    if (text != null && text.isNotEmpty) {
      _logPrint('║  $text');
    }
    _printLine('╚');
  }

  void _printLine([String pre = '', String suf = '╝']) {
    _logPrint('$pre${'═' * maxWidth}$suf');
  }

  void _printKV(String? key, Object? v) {
    final pre = '╟ $key: ';
    final msg = v.toString();

    if (pre.length + msg.length > maxWidth) {
      _logPrint(pre);
      _printBlock(msg);
    } else {
      _logPrint('$pre$msg');
    }
  }

  void _printBlock(String msg) {
    final lines = (msg.length / maxWidth).ceil();
    for (var i = 0; i < lines; ++i) {
      _logPrint(
        '║ ${msg.substring(i * maxWidth, math.min(i * maxWidth + maxWidth, msg.length))}',
      );
    }
  }

  String _indent([int tabCount = _initialTab]) => _tabStep * tabCount;

  void _printPrettyMap(
    Map<String, dynamic> data, {
    int tabs = _initialTab,
    bool isListItem = false,
    bool isLast = false,
  }) {
    final isRoot = tabs == _initialTab;
    final initialIndent = _indent(tabs);
    tabs++;

    if (isRoot || isListItem) _logPrint('║$initialIndent{');

    data.keys.toList().asMap().forEach((index, dynamic key) {
      final isLastItem = index == data.length - 1;
      dynamic value = data[key];
      if (value is String) {
        value = '"${value.toString().replaceAll(RegExp(r'([\r\n])+'), " ")}"';
      }
      if (value is Map<String, dynamic>) {
        if (compact && _canFlattenMap(value)) {
          _logPrint('║${_indent(tabs)} $key: $value${!isLastItem ? ',' : ''}');
        } else {
          _logPrint('║${_indent(tabs)} $key: {');
          _printPrettyMap(value, tabs: tabs);
        }
      } else if (value is List) {
        if (compact && _canFlattenList(value)) {
          _logPrint('║${_indent(tabs)} $key: ${value.toString()}');
        } else {
          _logPrint('║${_indent(tabs)} $key: [');
          _printList(value, tabs: tabs);
          _logPrint('║${_indent(tabs)} ]${isLastItem ? '' : ','}');
        }
      } else {
        final msg = value.toString().replaceAll('\n', '');
        final indent = _indent(tabs);
        final linWidth = maxWidth - indent.length;
        if (msg.length + indent.length > linWidth) {
          final lines = (msg.length / linWidth).ceil();
          for (var i = 0; i < lines; ++i) {
            _logPrint(
              '║${_indent(tabs)} ${msg.substring(i * linWidth, math.min(i * linWidth + linWidth, msg.length))}',
            );
          }
        } else {
          _logPrint('║${_indent(tabs)} $key: $msg${!isLastItem ? ',' : ''}');
        }
      }
    });

    _logPrint('║$initialIndent}${isListItem && !isLast ? ',' : ''}');
  }

  void _printList(List<dynamic> list, {int tabs = _initialTab}) {
    list.asMap().forEach((i, dynamic e) {
      final isLast = i == list.length - 1;
      if (e is Map<String, dynamic>) {
        if (compact && _canFlattenMap(e)) {
          _logPrint('║${_indent(tabs)}  $e${!isLast ? ',' : ''}');
        } else {
          _printPrettyMap(e, tabs: tabs + 1, isListItem: true, isLast: isLast);
        }
      } else {
        _logPrint('║${_indent(tabs + 2)} $e${isLast ? '' : ','}');
      }
    });
  }

  bool _canFlattenMap(Map<String, dynamic> map) {
    return map.values.where((val) => val is Map || val is List).isEmpty &&
        map.toString().length < maxWidth;
  }

  bool _canFlattenList(List<dynamic> list) {
    return list.length < 10 && list.toString().length < maxWidth;
  }

  void _printMapAsTable(Map<String, dynamic> map, {String? header}) {
    if (map.isEmpty) return;
    _logPrint('╔ $header');
    map.forEach((key, value) => _printKV(key, value));
    _printLine('╚');
  }

  void _logPrint(String message) {
    if (debugMode) {
      developer.log(message);
      if (onLogPrint != null) onLogPrint!(message);
    }
  }
}
