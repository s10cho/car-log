import 'package:car_log/features/garage/domain/car_body_style.dart';
import 'package:car_log/features/garage/domain/car_paint_color.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a vehicle looks like is stored as two ids, so the mapping back from an
/// id has to survive the model set changing underneath it.
void main() {
  test('every body style ships the model it names', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    for (final style in CarBodyStyle.values) {
      final bytes = await rootBundle.load(style.assetPath);

      expect(
        bytes.lengthInBytes,
        greaterThan(0),
        reason: '${style.id} 의 모델 파일이 없다',
      );
    }
  });

  test('a body style that no longer has a model becomes the nearest one', () {
    // 밴·트럭·대형 SUV 는 새 모델 세트에 없다. 세단으로 떨어뜨리면 사용자가
    // 고른 적 없는 차가 되므로, 남아 있는 가장 가까운 모양으로 보낸다.
    expect(CarBodyStyle.fromId('van'), CarBodyStyle.suv);
    expect(CarBodyStyle.fromId('truck'), CarBodyStyle.suv);
    expect(CarBodyStyle.fromId('delivery'), CarBodyStyle.suv);
    expect(CarBodyStyle.fromId('suv-luxury'), CarBodyStyle.suv);
  });

  test('an unknown body style falls back to the default', () {
    expect(CarBodyStyle.fromId('hovercraft'), CarBodyStyle.fallback);
    expect(CarBodyStyle.fromId(null), CarBodyStyle.fallback);
  });

  test('body style ids are unique and stable', () {
    final ids = CarBodyStyle.values.map((style) => style.id).toSet();

    expect(ids, hasLength(CarBodyStyle.values.length));
    // 저장된 값이므로 이름을 바꾸면 사용자의 차가 바뀐다.
    expect(ids, containsAll(['sedan', 'suv', 'taxi', 'police']));
  });

  test('a missing colour stays missing rather than becoming a default', () {
    // null 은 "모델이 그려진 색 그대로" 라는 뜻이다. 색이 생기기 전에 등록한
    // 차를 임의의 색으로 칠해 버리면 안 된다.
    expect(CarPaintColor.fromId(null), isNull);
    expect(CarPaintColor.fromId('chartreuse'), isNull);
    expect(CarPaintColor.fromId('red'), CarPaintColor.red);
  });

  test('colour ids are unique', () {
    final ids = CarPaintColor.values.map((color) => color.id).toSet();

    expect(ids, hasLength(CarPaintColor.values.length));
  });
}
