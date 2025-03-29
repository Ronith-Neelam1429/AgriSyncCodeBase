import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ARFarmPlanningPage extends StatefulWidget {
  const ARFarmPlanningPage({super.key});

  @override
  State<ARFarmPlanningPage> createState() => _ARFarmPlanningPageState();
}

class _ARFarmPlanningPageState extends State<ARFarmPlanningPage> {
  ArCoreController? arCoreController;
  ArCoreReferenceNode? tractorNode;

  @override
  void dispose() {
    arCoreController?.dispose();
    super.dispose();
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    arCoreController?.onPlaneTap = _handlePlaneTap;
  }

  void _handlePlaneTap(List<ArCoreHitTestResult> hits) {
    final hit = hits.first;
    _addTractor(hit);
  }

  Future<void> _addTractor(ArCoreHitTestResult hit) async {
    if (tractorNode != null) {
      arCoreController?.removeNode(nodeName: tractorNode!.name);
    }

    // Create ReferenceNode directly instead of using shape parameter
    tractorNode = ArCoreReferenceNode(
      name: 'Tractor',
      objectUrl: 'assets/tractor.glb',
      position: hit.pose.translation,
      rotation: hit.pose.rotation,
      scale: vector.Vector3(0.5, 0.5, 0.5),
    );

    arCoreController?.addArCoreNode(tractorNode!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Farm Planning'),
      ),
      body: ArCoreView(
        onArCoreViewCreated: _onArCoreViewCreated,
        enableTapRecognizer: true,
        enablePlaneRenderer: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => arCoreController?.dispose(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}