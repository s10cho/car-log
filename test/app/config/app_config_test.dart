import 'package:car_log/app/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEnvironment.fromKey', () {
    test('resolves the known environments', () {
      expect(AppEnvironment.fromKey('dev'), AppEnvironment.dev);
      expect(AppEnvironment.fromKey('production'), AppEnvironment.production);
    });

    test('rejects an unknown key', () {
      expect(() => AppEnvironment.fromKey('staging'), throwsArgumentError);
    });
  });

  group('AppConfig', () {
    test('dev and production never share a database file', () {
      final dev = AppConfig.of(AppEnvironment.dev);
      final production = AppConfig.of(AppEnvironment.production);

      expect(dev.databaseName, isNot(production.databaseName));
    });

    test('dev enables verbose logging, production does not', () {
      expect(AppConfig.of(AppEnvironment.dev).verboseLogging, isTrue);
      expect(AppConfig.of(AppEnvironment.production).verboseLogging, isFalse);
    });

    test('isDev reflects the environment', () {
      expect(AppConfig.of(AppEnvironment.dev).isDev, isTrue);
      expect(AppConfig.of(AppEnvironment.production).isDev, isFalse);
    });

    test('defaults to dev when APP_ENV is not defined', () {
      expect(AppConfig.fromDartDefine().environment, AppEnvironment.dev);
    });
  });
}
