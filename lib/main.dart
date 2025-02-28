import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ARScene(),
    );
  }
}

class ARScene extends StatefulWidget {
  const ARScene({super.key});

  @override
  State<ARScene> createState() => _ARSceneState();
}

class _ARSceneState extends State<ARScene> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;

  @override
  void dispose() {
    arSessionManager.dispose();
    super.dispose();
  }

  void onARViewCreated(
    ARSessionManager arSessionMgr,
    ARObjectManager arObjectMgr,
    ARAnchorManager arAnchorMgr,
    ARLocationManager arLocationMgr,
  ) {
    arSessionManager = arSessionMgr;
    arObjectManager = arObjectMgr;

    arSessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
    );

    arObjectManager.onInitialize();
    print("AR Object Manager initialized successfully");

    // Add a sample 3D model with debug logging
    try {
      final node = ARNode(
        type: NodeType.fileSystemAppFolderGLB,
        uri: "assets/source/123.glb",
        scale: vm.Vector3(0.5, 0.5, 0.5), // Adjusted to a reasonable scale
        position: vm.Vector3(0.0, 0.0, -1.0), // 1 meter in front of camera
        rotation: vm.Vector4(0.0, 0.0, 0.0, 1.0), // Identity quaternion as Vector4 [x, y, z, w]
      );

      arObjectManager.addNode(node).then((_) {
        print("Node added successfully: $node");
      }).catchError((error) {
        print("Error adding node: $error");
      });
    } catch (e) {
      print("Exception while creating node: $e");
    }

    // Handle tap to place node on detected plane
    arSessionManager.onPlaneOrPointTap = (List<ARHitTestResult> hitTestResults) {
      if (hitTestResults.isNotEmpty) {
        final plane = hitTestResults.first;
        print("Tapped on plane at: ${plane.worldTransform.getTranslation()}");
        try {
          final node = ARNode(
            type: NodeType.localGLTF2,
            uri: "assets/source/123.glb",
            scale: vm.Vector3(10,10,10),
            position: plane.worldTransform.getTranslation(), // Extract Vector3 from hit result
            rotation: vm.Vector4(0.0, 0.0, 0.0, 1.0), // Identity quaternion as Vector4
          );
          arObjectManager.addNode(node);
          print("Node placed on tap successfully: $node");
        } catch (e) {
          print("Error placing node on tap: $e");
        }
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AR Flutter Demo')),
      body: ARView(
        onARViewCreated: onARViewCreated,
        planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
      ),
    );
  }
}