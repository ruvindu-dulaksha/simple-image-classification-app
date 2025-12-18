import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class Classifier {
  late Interpreter _interpreter;
  late List<String> _labels;
  final int inputSize = 32; // Changed to 32 for your model

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/model.tflite');
    final labelsData = await rootBundle.loadString('assets/labels.txt');
    _labels = LineSplitter().convert(labelsData);
  }

  List<double> predict(img.Image image) {
    // Convert to grayscale
    final grayscale = img.grayscale(image);
    final resized = img.copyResize(
      grayscale,
      width: inputSize,
      height: inputSize,
    );

    var input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            img.getLuminance(pixel) / 255.0,
          ]; // Single channel for grayscale
        }),
      ),
    );

    var output = List.filled(1, 0.0).reshape([1, 1]);

    _interpreter.run(input, output);

    return output[0];
  }

  String getLabel(List<double> output) {
    // For binary sigmoid: output[0] > 0.5 means Dog (index 1), else Cat (index 0)
    final index = output[0] > 0.5 ? 1 : 0;
    return _labels[index];
  }
}
