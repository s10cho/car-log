import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scene/scene.dart';
import 'package:logging/logging.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../domain/car_body_style.dart';
import '../domain/car_paint_color.dart';
import 'car_paint.dart';
import 'car_silhouette.dart';

final _log = Logger('car_scene');

/// How the car is presented.
enum CarPose {
  /// Turns slowly on the spot, for picking a shape.
  showcase,

  /// Sits still at a three-quarter angle, for the home screen.
  parked,

  /// Rocks gently as though rolling, for a vehicle in good order.
  driving,
}

/// A 3D car, rendered with Flutter GPU.
///
/// Falls back to a drawn silhouette whenever 3D is unavailable — an older
/// device, a platform without Flutter GPU, or a model that fails to load. The
/// car is decoration: it must never be the reason a screen cannot be used.
class CarScene extends StatefulWidget {
  const CarScene({
    required this.style,
    this.color,
    this.pose = CarPose.parked,
    this.height = 200,
    super.key,
  });

  final CarBodyStyle style;
  final CarPaintColor? color;
  final CarPose pose;
  final double height;

  @override
  State<CarScene> createState() => _CarSceneState();
}

class _CarSceneState extends State<CarScene> {
  Scene? _scene;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CarScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style != widget.style || oldWidget.color != widget.color) {
      _load();
    }
  }

  Future<void> _load() async {
    final style = widget.style;
    final color = widget.color;
    try {
      final node = await _CarModels.instance.load(style);
      if (!mounted || widget.style != style || widget.color != color) {
        return;
      }
      paintCar(node, style, color);

      // The runtime glTF importer puts a handedness flip on the root it
      // synthesises. Anything this app wants to do to the car — placing it,
      // turning it — goes on a parent, never on that root.
      //
      // Turned to face the camera: the models are authored nose-down-Z, and
      // left alone every screen would show the user the back of their car.
      final car = Node(name: 'car')
        ..add(node)
        ..rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), math.pi);

      final scene = Scene()
        ..add(car)
        ..add(_ground())
        // A key light low enough to rake along the body, so the shoulder line
        // catches and the car stops reading as a flat cut-out.
        ..directionalLight = DirectionalLight(
          direction: vm.Vector3(-0.55, -1.0, -0.35),
          intensity: 3.2,
          castsShadow: true,
          shadowSoftness: 0.14,
          contactShadows: true,
        )
        ..environmentSettings = _look;

      setState(() {
        _scene = scene;
        _failed = false;
      });
    } on Object catch (error, stackTrace) {
      _log.warning(
        '3D car unavailable; drawing a silhouette',
        error,
        stackTrace,
      );
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  /// An invisible disc under the car that collects its shadow.
  ///
  /// Without it the car floats: nothing in the scene is under the wheels, so
  /// the light has nothing to fall on. The catcher draws only the darkening,
  /// which means the card behind it still shows through.
  Node _ground() => Node(
    name: 'ground',
    mesh: Mesh(
      DiscGeometry(radius: 3.0),
      ShadowCatcherMaterial(
        shadowIntensity: 0.45,
        // No ambient term on the plane. The disc is wider than the frame, so
        // any occlusion it collects greys the whole card it is drawn over —
        // the card went muddy the first time this was turned up. The car's
        // own contact darkening comes from the scene's occlusion instead.
        aoStrength: 0,
        softness: 0.3,
        // Fade to nothing well before the disc's edge, or the shadow ends in
        // a visible circle rather than in the background.
        fadeStart: 0.8,
        fadeEnd: 2.2,
      ),
    ),
  );

  /// One deliberate look rather than a dozen independently tuned knobs.
  ///
  /// Filmic tone mapping and a little bloom give paint its highlight; ambient
  /// occlusion at half resolution grounds the wheels without costing a phone
  /// its frame budget. Reflections are left off: a car is the only thing in
  /// this scene, so screen-space reflections have nothing to reflect.
  EnvironmentSettings get _look => EnvironmentSettings(
    toneMapping: ToneMappingMode.aces,
    exposure: 1.05,
    bloomEnabled: true,
    bloomThreshold: 1.1,
    bloomIntensity: 0.18,
    bloomScatter: 0.7,
    ambientOcclusionEnabled: true,
    ambientOcclusionIntensity: 0.9,
    ambientOcclusionHalfResolution: true,
  );

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return CarSilhouette(
        style: widget.style,
        color: widget.color,
        height: widget.height,
      );
    }

    final scene = _scene;
    if (scene == null) {
      return SizedBox(width: double.infinity, height: widget.height);
    }

    // width must be given: under the loose constraints a Stack hands its
    // non-positioned children, a height-only SizedBox collapses to zero width
    // and the scene renders nothing at all.
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final aspect =
              constraints.hasBoundedWidth && constraints.maxHeight > 0
              ? constraints.maxWidth / constraints.maxHeight
              : 1.0;
          return SceneView(
            scene,
            cameraBuilder: (elapsed) => _camera(elapsed, aspect),
            // The engine's shared shaders load once per app run. Gating on that
            // and drawing the silhouette meanwhile beats dropping the first frames
            // and having the car appear a beat late — and it is the same picture
            // the fallback uses, so nothing jumps.
            loadingBuilder: (context, progress) => CarSilhouette(
              style: widget.style,
              color: widget.color,
              height: widget.height,
            ),
          );
        },
      ),
    );
  }

  /// Poses the car by moving the camera rather than the model, so a cached
  /// model can be shared between screens showing it differently.
  PerspectiveCamera _camera(Duration elapsed, double aspect) {
    final seconds = elapsed.inMilliseconds / 1000;
    final distance = _distanceFor(aspect);

    final (angle, elevation) = switch (widget.pose) {
      // A full turn every 24 seconds: fast enough to read as alive, slow
      // enough not to fight the user trying to look at it.
      CarPose.showcase => (seconds * math.pi / 12, 0.30 * distance),
      CarPose.parked => (0.9, 0.29 * distance),
      // A shallow sway, as if the car were rolling towards the viewer.
      CarPose.driving => (
        0.9 + math.sin(seconds * 0.9) * 0.1,
        (0.29 + math.sin(seconds * 1.7) * 0.008) * distance,
      ),
    };

    return PerspectiveCamera(
      // Long-lens rather than wide: a car photographed from close up bulges
      // at the near wheel, which is exactly the look to avoid.
      fovRadiansY: _fov,
      position: vm.Vector3(
        math.sin(angle) * distance,
        elevation,
        math.cos(angle) * distance,
      ),
      target: vm.Vector3(0, 0.62, 0),
    );
  }
}

const double _fov = 32 * math.pi / 180;

/// How far back the camera has to sit for the whole car to fit.
///
/// The viewport's shape decides this, not the pose. The same car has to fit a
/// wide home card and a tall wizard step, and one fixed distance either cuts
/// the bumpers off in the tall one or leaves a toy in the middle of the wide
/// one — which is exactly what both looked like before this was measured.
double _distanceFor(double aspect) {
  // The longest model, at the three-quarter angle it is shown from.
  const carLength = 4.4;
  const carHeight = 1.7;
  const margin = 1.2;

  final halfExtent = math.tan(_fov / 2);
  final forHeight = carHeight * margin / (2 * halfExtent);
  final forWidth = carLength * margin / (2 * halfExtent * aspect);
  return math.max(forWidth, forHeight);
}

/// Caches the model files, not the models.
///
/// A [Node] belongs to the scene it was added to, so handing the same instance
/// to a second [Scene] leaves one of them with nothing to draw — which is what
/// happened when the home screen showed an empty stage after the wizard had
/// already rendered the same car. The bytes are shared instead, and each view
/// builds its own node from them.
class _CarModels {
  _CarModels._();

  static final _CarModels instance = _CarModels._();

  final Map<CarBodyStyle, Future<Uint8List>> _bytes = {};

  Future<Node> load(CarBodyStyle style) async {
    final bytes = await _bytes.putIfAbsent(style, () async {
      final data = await rootBundle.load(style.assetPath);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    });
    return Node.fromGlbBytes(bytes);
  }
}
