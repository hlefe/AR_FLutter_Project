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
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart'; // You need to import ar Anchor to be able to create anchors and position objects on them.

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
  late ARAnchorManager? arAnchorManager; // You need an AnchorManager

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
    arAnchorManager = arAnchorMgr;

    arSessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
    );

    arObjectManager.onInitialize();
    print("AR Object Manager initialized successfully");

    // Handle tap to place node on detected plane
    arSessionManager.onPlaneOrPointTap = (List<ARHitTestResult> hitTestResults) {
      if (hitTestResults.isNotEmpty) {
        final singleHitTestResult = hitTestResults.first;
        print("Tapped on plane at: ${singleHitTestResult.worldTransform.getTranslation()}");
        // You need to create an anchor from the coordinates of the tapped plane, and only then add a node to this anchor. :
        var newAnchor =
        ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
        this.arAnchorManager!.addAnchor(newAnchor).then((bool? didAddAnchor) {
          if (didAddAnchor == true) {
            try {
              final node = ARNode(
                type: NodeType.localGLTF2,
                uri: "assets/source/123.glb",
                //scale: vm.Vector3(10,10,10),
                scale: vm.Vector3(1, 1, 1),
                // I think your scale was too big
                //position: plane.worldTransform.getTranslation(), // Extract Vector3 from hit result
                position: vm.Vector3(0, 0, 0),
                // You need to set the coordinates relative to where the user tapped, so 0,0,0 if you want to place the object exactly where the tap occurred.
                rotation: vm.Vector4(
                //    0.0, 0.0, 0.0, 1.0), // Identity quaternion as Vector4
                    1.0, 0.0, 0.0, 1.0), // Rotation adjustement
              );
              //arObjectManager.addNode(node)
              arObjectManager.addNode(node, planeAnchor:newAnchor).then((bool? success) {
                print("addNode result: $success");
                if (success == true) {
                  print("Node added successfully.");
                } else {
                  print("Failure to add the node.");
                }
              }).catchError((error) {
                print("Error : $error");
              });
              print("Node placed on tap successfully: $node");
            } catch (e) {
              print("Error placing node on tap: $e");
            }
          }
          else {
            print("Error Adding Anchor failed ");
          }
        }
        );

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