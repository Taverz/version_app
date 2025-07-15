import 'dart:async';

import 'package:shelf/shelf.dart';

mixin AppRouterUtils {
  FutureOr<Response> Function(Request) handleCors(
    FutureOr<Response> Function(Request) innerHandler,
  ) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok(
          null,
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Origin, Content-Type',
          },
        );
      }

      final response = await innerHandler(request);

      return response.change(
        headers: {...response.headersAll, 'Access-Control-Allow-Origin': '*'},
      );
    };
  }
}
