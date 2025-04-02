import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ARFarmPlanningPage extends StatefulWidget {
  const ARFarmPlanningPage({Key? key}) : super(key: key);

  @override
  _ARFarmPlanningPageState createState() => _ARFarmPlanningPageState();
}

class _ARFarmPlanningPageState extends State<ARFarmPlanningPage> {
  late ArCoreController arCoreController;

  @override
  void dispose() {
    arCoreController.dispose();
    super.dispose();
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    // Listen for taps on detected planes.
    arCoreController.onPlaneTap = _handleOnPlaneTap;
  }

  void _handleOnPlaneTap(List<ArCoreHitTestResult> hits) {
    if (hits.isNotEmpty) {
      final hit = hits.first;
      _add3DModel(hit);
    }
  }

  Future<void> _add3DModel(ArCoreHitTestResult hitTestResult) async {
    // Create a reference node that loads a 3D model from assets.
    final node = ArCoreReferenceNode(
      name: "tractor",
      objectUrl: "assets/Models/tractor.glb",
      position: hitTestResult.pose.translation,
      rotation: hitTestResult.pose.rotation,
      scale: vector.Vector3(0.2, 0.2, 0.2), // Adjust scale as needed.
    );
    // Add the node with an anchor so it stays fixed to the real world.
    arCoreController.addArCoreNodeWithAnchor(node);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "AR Farm Planning",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: ArCoreView(
        onArCoreViewCreated: _onArCoreViewCreated,
        enableTapRecognizer: true,
      ),
    );
  }
}