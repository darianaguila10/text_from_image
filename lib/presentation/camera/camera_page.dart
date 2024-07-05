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
  String _name = '';
  String _surname = '';
  String _birthDate = '';
  String _idNumber = '';
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
    return Scaffold(
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
                ? Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 80, bottom: 120),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CameraPreview(
                              controller!,
                            ),
                          ),
                          ClipPath(
                            clipper: TransparentHoleClipper(),
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                              child: Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                        width: 5,
                                        color: Colors.white.withOpacity(0.8)),
                                  ),
                                  height:
                                      MediaQuery.of(context).size.height * 0.5,
                                  width:
                                      MediaQuery.of(context).size.width * 0.65,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
                              height: MediaQuery.of(context).size.height * 0.6,
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
                            ),
                            const SizedBox(height: 20),
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
        onPressed: () => _image == null ? _onTap(null) : replay(),
        shape: const CircleBorder(),
        tooltip: 'Replay',
        child: _image == null
            ? const Icon(Icons.camera)
            : const Icon(Icons.replay_outlined),
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
    _parseRecognizedText(text);
    if (context.mounted) {
      await showDialog(
        context: (context),
        builder: (context) {
          return AlertDialog(
            title: const Text('Texto'),
            content: Text(
              'Nombre: $_name \n'
              'Apellidos: $_surname\n'
              'Fecha de Nacimiento: $_birthDate\n'
              'Número de Identificación: $_idNumber\n',
            ),
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
    void parseRecognizedText(String text) {
      final nameRegex = RegExp(r'NOMBRES\s+(.+)', caseSensitive: false);
      final surnameRegex = RegExp(r'APELLIDOS\s+(.+)', caseSensitive: false);
      final birthDateRegex =
          RegExp(r'(\d{2}/\d{2}/\d{4})', caseSensitive: false);
      final idNumberRegex = RegExp(r'V-\d{8,9}', caseSensitive: false);

      final nameMatch = nameRegex.firstMatch(text);
      final surnameMatch = surnameRegex.firstMatch(text);
      final birthDateMatch = birthDateRegex.firstMatch(text);
      final idNumberMatch = idNumberRegex.firstMatch(text);

      setState(() {
        _name = nameMatch?.group(1) ?? 'No encontrado';
        _surname = surnameMatch?.group(1) ?? 'No encontrado';
        _birthDate = birthDateMatch?.group(1) ?? 'No encontrado';
        _idNumber = idNumberMatch?.group(0) ?? 'No encontrado';
      });
    }
  }

  void _parseRecognizedText(String text) {
    final nameRegex = RegExp(r'NOMBRES\s+(.+)', caseSensitive: false);
    final surnameRegex = RegExp(r'APELLIDOS\s+(.+)', caseSensitive: false);
    final birthDateRegex = RegExp(r'(\d{2}/\d{2}/\d{4})', caseSensitive: false);
    final idNumberRegex =
        RegExp(r'V\s?\d{1,2}\.\d{3}\.\d{3}', caseSensitive: false);

    final nameMatch = nameRegex.firstMatch(text);
    final surnameMatch = surnameRegex.firstMatch(text);
    final birthDateMatch = birthDateRegex.firstMatch(text);
    final idNumberMatch = idNumberRegex.firstMatch(text);

    setState(() {
      _name = nameMatch?.group(1) ?? 'No encontrado';
      _surname = surnameMatch?.group(1) ?? 'No encontrado';
      _birthDate = birthDateMatch?.group(1) ?? 'No encontrado';
      _idNumber = idNumberMatch?.group(0) ?? 'No encontrado';
    });
  }

  Future<void> _onTap(TapUpDetails? details) async {
    if (controller!.value.isInitialized) {
      showFocusCircle = true;
    /*   x = details.localPosition.dx;
      y = details.localPosition.dy;

      double fullWidth = MediaQuery.of(context).size.width;
      double cameraHeight = fullWidth * controller!.value.aspectRatio;

      double xp = x / fullWidth;
      double yp = y / cameraHeight;

      Offset point = Offset(xp, yp);
      setState(() {});

      await controller!.setFocusPoint(point); */

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

class TransparentHoleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double containerHeight = size.height * 0.65;
    double containerWidth = size.width * 0.65;
    double centerX = size.width / 2;
    double centerY = size.height / 2;

    Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX, centerY),
            width: containerWidth,
            height: containerHeight,
          ),
          const Radius.circular(24),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
