import 'dart:developer';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraPage({super.key, required this.cameras});

  @override
  CameraPageState createState() => CameraPageState();
}

class CameraPageState extends State<CameraPage> {
  File? _image;
  CameraController? controller;
  late Future<void> _initializeControllerFuture;
  bool showFocusCircle = false;
  double x = 0;
  double y = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future getImageFromGallery() async {
    try {
      await _initializeControllerFuture;
      final image = await controller!.takePicture();
      _image = File(image.path);
      setState(() {});
    } catch (e) {
      log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTapUp: (details) {
            if (_image == null) _onTap(details);
          },
          child: Stack(
            children: [
              controller != null &&
                      controller!.value.isInitialized &&
                      _image == null
                  ? Center(
                      child: CameraPreview(
                        controller!,
                      ),
                    )
                  : _image == null
                      ? const Center(child: Text('No image selected.'))
                      : SafeArea(
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 40,
                              ),
                              Image.file(
                                _image!,
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Center(
                                child: ElevatedButton(
                                    onPressed: () {
                                      readTextFromImage();
                                    },
                                    child: const Text("Obtener texto")),
                              )
                            ],
                          ),
                        ),
              if (showFocusCircle)
                Positioned(
                    top: y - 40,
                    left: x - 40,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.7)),
                    ))
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => replay(),
          shape: const CircleBorder(),
          tooltip: 'Replay',
          child: const Icon(Icons.replay_outlined),
        ),
      ),
    );
  }

  Future<void> readTextFromImage() async {
    final inputImage = InputImage.fromFile(_image!);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);
    String text = recognizedText.text;
    textRecognizer.close();

    if (context.mounted) {
      await showDialog(
        context: (context),
        builder: (context) {
          return AlertDialog(
            title: const Text('Texto'),
            content: Text(text),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _onTap(TapUpDetails details) async {
    if (controller!.value.isInitialized) {
      showFocusCircle = true;
      x = details.localPosition.dx;
      y = details.localPosition.dy;

      double fullWidth = MediaQuery.of(context).size.width;
      double cameraHeight = fullWidth * controller!.value.aspectRatio;

      double xp = x / fullWidth;
      double yp = y / cameraHeight;

      Offset point = Offset(xp, yp);
      setState(() {});

      await controller!.setFocusPoint(point);

      showFocusCircle = false;
      getImageFromGallery();
    }
  }

  replay() {
    setState(() {
      showFocusCircle = false;
      x = 0;
      y = 0;
      _image = null;
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> init() async {
    try {
      var cameraStatus = await Permission.camera.request();

      if (cameraStatus.isGranted) {
        controller = CameraController(
          widget.cameras.first,
          ResolutionPreset.max,
          enableAudio: false,
        );
        _initializeControllerFuture = controller!.initialize().then((_) {
          if (!mounted) {
            controller!.takePicture();
            return;
          }
          setState(() {});
        }).catchError((Object e) {});
      }
    } catch (e) {
      log(e.toString());
    }
  }
}
