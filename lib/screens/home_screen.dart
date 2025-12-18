import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:simple_image_classification_app/services/classifier.dart';
import 'package:simple_image_classification_app/utils/image_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final classifier = Classifier();
  final imageHelper = ImageHelper();

  File? _image;
  String _result = '';
  double _confidence = 0;
  bool _isModelLoaded = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      await classifier.loadModel();
      setState(() => _isModelLoaded = true);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load model: $e');
    }
  }

  Future<void> _classifyImage(File imageFile) async {
    if (!_isModelLoaded) return;

    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        setState(() => _errorMessage = 'Failed to decode image');
        return;
      }

      final output = classifier.predict(image);

      setState(() {
        final label = classifier.getLabel(output);
        _result = label;
        _confidence = output[0] > 0.5
            ? output[0]
            : 1 - output[0]; // Confidence for the predicted class
        _errorMessage = ''; // Clear any previous error
      });
    } catch (e) {
      setState(() => _errorMessage = 'Classification failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dog VS Cat",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /// 🖼 IMAGE FRAME
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  height: 230,
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  child: _image != null
                      ? Image.file(_image!, fit: BoxFit.contain)
                      : Image.asset("assets/logo.png", fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 24),

              /// 🔘 BUTTONS ROW
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.photo, size: 25),
                      label: const Text(
                        "Pick from Gallery",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _isModelLoaded
                          ? () async {
                              final image = await imageHelper.pickFromGallery();
                              if (image == null) return;
                              setState(() => _image = image);
                              _classifyImage(image);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt, size: 25),
                      label: const Text(
                        "Take a Photo",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _isModelLoaded
                          ? () async {
                              final image = await imageHelper.pickFromCamera();
                              if (image == null) return;
                              setState(() => _image = image);
                              _classifyImage(image);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              /// 📊 RESULT DASHBOARD
              if (_result.isNotEmpty)
                Card(
                  elevation: 8,
                  color: Colors.grey.shade900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Result",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _result,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "Confidence",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${(_confidence * 100).toStringAsFixed(2)}%",
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              if (!_isModelLoaded)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: CircularProgressIndicator(),
                ),

              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
