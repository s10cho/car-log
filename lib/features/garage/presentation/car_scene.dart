import 'dart:async';
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

/// Starts loading the 3D engine's shared resources, before any car needs them.
///
/// These load once per app run and the first [SceneView] would otherwise wait
/// on them while the home screen is already on screen. Called from bootstrap
/// and deliberately not awaited: the app must open at the same speed whether
/// or not the device can render 3D at all.
Future<void> warmUpCarScene() async {
  try {
    await Scene.initializeStaticResources();
  } on Object catch (error, stackTrace) {
    _log.warning(
      '3D engine unavailable; cars will be drawn flat',
      error,
      stackTrace,
    );
  }
}

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
  /// How long the stage stays empty before a drawn car is put there instead.
  ///
  /// On a warm engine the model is ready well inside this, and the user sees
  /// the car arrive once. On a slow device an empty stage would look broken,
  /// so the drawing stands in — and then cross-fades rather than snapping.
  static const Duration _patience = Duration(milliseconds: 900);

  Scene? _scene;
  bool _failed = false;
  bool _waitedLongEnough = false;
  Timer? _patienceTimer;

  @override
  void initState() {
    super.initState();
    _patienceTimer = Timer(_patience, () {
      if (mounted && _scene == null) {
        setState(() => _waitedLongEnough = true);
      }
    });
    _load();
  }

  @override
  void dispose() {
    _patienceTimer?.cancel();
    super.dispose();
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
      // Wait for the engine here rather than letting SceneView swap a
      // placeholder in mid-flight. That placeholder is what the user saw as a
      // flat car flicking over into a 3D one a beat after the app opened.
      if (!Scene.isReadyToRender) {
        await Scene.initializeStaticResources();
      }
      if (!mounted || widget.style != style || widget.color != color) {
        return;
      }
      paintCar(node, style, color);

      // The runtime glTF importer puts a handedness flip on the root it
      // synthesises. Anything this app wants to do to the car — placing it,
      // turning it — goes on a parent, never on that root.
      final car = Node(name: 'car')..add(node);
      _fit(car);

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

  /// Sizes and places an imported car so every model arrives the same.
  ///
  /// The models come from different authors and are authored in whatever units
  /// suited them — one car is four units long, another four hundred, a third
  /// four hundredths. Rather than carry a magic scale per model, the car is
  /// measured once on load and scaled to a real car's length, centred, and set
  /// down on the ground, facing the camera.
  void _fit(Node car) {
    final bounds = car.combinedLocalBounds;
    if (bounds == null) {
      return;
    }
    final size = bounds.max - bounds.min;
    final length = math.max(size.x, size.z);
    if (length <= 0) {
      return;
    }

    final scale = _targetLength / length;
    // Half a turn. glTF points a vehicle down -Z and the runtime importer's
    // handedness flip turns that into +Z — straight at the camera's back. Left
    // alone, every screen shows the user the boot of their car.
    final rotation = vm.Matrix4.rotationY(math.pi);
    final centre = (bounds.min + bounds.max) * 0.5 * scale;
    final placed = rotation.transformed3(vm.Vector3(centre.x, 0, centre.z));

    final transform =
        vm.Matrix4.translation(
          vm.Vector3(-placed.x, -bounds.min.y * scale, -placed.z),
        ) *
        rotation *
        vm.Matrix4.diagonal3Values(scale, scale, scale);
    car.localTransform = transform as vm.Matrix4;
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
    // width must be given: under the loose constraints a Stack hands its
    // non-positioned children, a height-only SizedBox collapses to zero width
    // and the scene renders nothing at all.
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      // Whatever replaces what is on screen fades in over it. The car is the
      // one thing on this screen the user is looking at, and it should not
      // appear by snapping into place.
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: _stage(),
      ),
    );
  }

  Widget _stage() {
    final scene = _scene;
    if (_failed || (scene == null && _waitedLongEnough)) {
      return CarSilhouette(
        key: const ValueKey('drawn'),
        style: widget.style,
        color: widget.color,
        height: widget.height,
      );
    }
    if (scene == null) {
      return SizedBox(
        key: const ValueKey('empty'),
        width: double.infinity,
        height: widget.height,
      );
    }

    return SizedBox(
      key: const ValueKey('scene'),
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
            // Nothing, rather than a stand-in: the engine is already ready by
            // the time this builds, and anything drawn here would only ever be
            // seen as a flicker.
            loadingBuilder: (context, progress) =>
                SizedBox(width: double.infinity, height: widget.height),
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

/// Every car is scaled to this length in metres, whatever it was authored at.
const double _targetLength = 4.3;

/// How far back the camera has to sit for the whole car to fit.
///
/// The viewport's shape decides this, not the pose. The same car has to fit a
/// wide home card and a tall wizard step, and one fixed distance either cuts
/// the bumpers off in the tall one or leaves a toy in the middle of the wide
/// one — which is exactly what both looked like before this was measured.
double _distanceFor(double aspect) {
  // Every model is scaled to the same length; the tallest of them (the van)
  // is what the height has to clear.
  const carLength = _targetLength;
  const carHeight = 2.0;
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
