import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

class ModelManager {
  static const String modelUrl =
      'https://huggingface.co/datasets/Gabriel/Glyph/resolve/main/gemma-2b-it-q4.tflite';
  static const String modelFileName = 'gemma-2b-it-q4.tflite';

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$modelFileName');
  }

  Future<bool> isModelDownloaded() async {
    final file = await _localFile;
    return await file.exists();
  }

  Future<void> downloadModel({
    required Function(double) onProgress,
    required Function() onCompleted,
    required Function(String) onError,
  }) async {
    try {
      final file = await _localFile;
      Dio dio = Dio();
      await dio.download(
        modelUrl,
        file.path,
        onReceiveProgress: (received, total) {
          if (total != -1) onProgress(received / total);
        },
      );
      await initializeGemma();
      onCompleted();
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> initializeGemma() async {
    if (await isModelDownloaded()) {
      final file = await _localFile;
      await FlutterGemmaPlugin.instance.init(modelPath: file.path);
    }
  }
}
