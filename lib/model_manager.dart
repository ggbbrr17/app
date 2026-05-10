import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

class ModelManager {
  static const String modelUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm';
  static const String modelFileName = 'gemma-4-E2B-it.litertlm';

  Future<File> get localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$modelFileName');
  }

  Future<bool> isModelDownloaded() async {
    final file = await localFile;
    return await file.exists();
  }

  Future<void> downloadModel({
    required Function(double) onProgress,
    required Function() onCompleted,
    required Function(String) onError,
  }) async {
    try {
      final file = await localFile;
      Dio dio = Dio();
      await dio.download(
        modelUrl,
        file.path,
        onReceiveProgress: (received, total) {
          if (total != -1) onProgress(received / total);
        },
      );
      onCompleted();
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> initializeGemma() async {
    if (await isModelDownloaded()) {
      final file = await localFile;
      await FlutterGemma.initialize();
      await FlutterGemma.installModel(modelType: ModelType.gemma4)
          .fromFile(file.path)
          .install();
    }
  }
}
