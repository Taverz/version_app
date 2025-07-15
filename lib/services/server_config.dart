import 'package:dio/dio.dart';
import 'package:version_app/untils/pretty_dio_logger_custom.dart';
import 'package:version_app/services/custom_server_service_dio.dart';

class ConfigServer {
  static const urlServer = 'http://test-servicebook.ru:8000';
  static const urlTestServer = 'http://127.0.0.1:8923';

  final dartServer = CustomServerService(
    dio: Dio()
      ..options = BaseOptions(baseUrl: ConfigServer.urlTestServer)
      ..interceptors.add(PrettyDioLoggerCustom()),
  );
}
