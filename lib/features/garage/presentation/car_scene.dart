import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scene/scene.dart';
import 'package:logging/logging.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../domain/car_body_style.dart';
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
    this.pose = CarPose.parked,
    this.height = 200,
    super.key,
  });

  final CarBodyStyle style;
  final CarPose pose;
  final double height;

  @override
  State<CarScene> createState() => _CarSceneState();
}

class _CarSceneState extends State<CarScene> {
  Scene? _scene;
  Node? _car;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CarScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style != widget.style) {
      _load();
    }
  }

  Future<void> _load() async {
    final style = widget.style;
    try {
      final node = await _CarModels.instance.load(style);
      if (!mounted || widget.style != style) {
        return;
      }
      final scene = Scene()..add(node);
      setState(() {
        _scene = scene;
        _car = node;
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

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return CarSilhouette(style: widget.style, height: widget.height);
    }

    final scene = _scene;
    final car = _car;
    if (scene == null || car == null) {
      return SizedBox(width: double.infinity, height: widget.height);
    }

    // width must be given: under the loose constraints a Stack hands its
    // non-positioned children, a height-only SizedBox collapses to zero width
    // and the scene renders nothing at all.
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: SceneView(
        scene,
        cameraBuilder: (elapsed) => _camera(elapsed, car),
        // The engine's shared shaders load once per app run. Gating on that
        // and drawing the silhouette meanwhile beats dropping the first frames
        // and having the car appear a beat late — and it is the same picture
        // the fallback uses, so nothing jumps.
        loadingBuilder: (context, progress) =>
            CarSilhouette(style: widget.style, height: widget.height),
      ),
    );
  }

  /// Poses the car by moving the camera rather than the model, so a cached
  /// model can be shared between screens showing it differently.
  PerspectiveCamera _camera(Duration elapsed, Node car) {
    final seconds = elapsed.inMilliseconds / 1000;

    final (angle, elevation, distance) = switch (widget.pose) {
      // A full turn every 12 seconds: fast enough to read as alive, slow
      // enough not to fight the user trying to look at it.
      CarPose.showcase => (seconds * math.pi / 6, 2.2, 5.4),
      CarPose.parked => (0.8, 1.9, 5.0),
      // A shallow sway, as if the car were rolling towards the viewer.
      CarPose.driving => (
        0.8 + math.sin(seconds * 0.9) * 0.12,
        1.9 + math.sin(seconds * 1.7) * 0.06,
        5.0,
      ),
    };

    return PerspectiveCamera(
      position: vm.Vector3(
        math.sin(angle) * distance,
        elevation,
        math.cos(angle) * distance,
      ),
      target: vm.Vector3(0, 0.45, 0),
    );
  }
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
