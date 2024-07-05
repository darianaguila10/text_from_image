import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  CameraViewState createState() => CameraViewState();
}

class CameraViewState extends State<CameraView> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  String _name = '';
  String _surname = '';
  String _birthDate = '';
  String _idNumber = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
    );

    await _cameraController?.initialize();

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _captureAndScan() async {
    try {
      final XFile file = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(file.path);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      String result = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          result += '${line.text}\n';
        }
      }

      _parseRecognizedText(result);
    } catch (e) {
      print('Error capturing and scanning: $e');
    }
  }

  void _parseRecognizedText(String text) {
    final nameRegex = RegExp(r'NOMBRES\s+(.+)', caseSensitive: false);
    final surnameRegex = RegExp(r'APELLIDOS\s+(.+)', caseSensitive: false);
    final birthDateRegex =
        RegExp(r'F\. NACIMIENTO\s+(\d{2}/\d{2}/\d{4})', caseSensitive: false);
    final idNumberRegex =
        RegExp(r'CÉDULA DE IDENTIDAD\s+(\w+\s+\d+)', caseSensitive: false);

    final nameMatch = nameRegex.firstMatch(text);
    final surnameMatch = surnameRegex.firstMatch(text);
    final birthDateMatch = birthDateRegex.firstMatch(text);
    final idNumberMatch = idNumberRegex.firstMatch(text);

    setState(() {
      _name = nameMatch?.group(1) ?? 'Not found';
      _surname = surnameMatch?.group(1) ?? 'Not found';
      _birthDate = birthDateMatch?.group(1) ?? 'Not found';
      _idNumber = idNumberMatch?.group(1) ?? 'Not found';
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_cameraController != null && _isInitialized)
              CameraPreview(_cameraController!)
            else
              const Center(child: CircularProgressIndicator()),
            Positioned.fill(
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(width: 2, color: Colors.white),
                  ),
                  height: MediaQuery.of(context).size.height * 0.5,
                  width: MediaQuery.of(context).size.width * 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final width = size.width * 0.8;
    final height = size.height * 0.3;
    final left = (size.width - width) / 2;
    final top = (size.height - height) / 2;

    // Draw the outer darkened area
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), paint);
    canvas.drawRect(Rect.fromLTWH(0, top, left, height), paint);
    canvas.drawRect(Rect.fromLTWH(left + width, top, left, height), paint);
    canvas.drawRect(
        Rect.fromLTWH(0, top + height, size.width, size.height - top - height),
        paint);

    // Draw the viewfinder border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(Rect.fromLTWH(left, top, width, height), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
