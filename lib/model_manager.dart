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
    try {
      await FlutterGemma.initialize();
      bool gemmaInstalled = await FlutterGemma.isModelInstalled(modelFileName);
      if (gemmaInstalled) return true;
    } catch (_) {}
    
    final file = await localFile;
    return await file.exists();
  }

  Future<void> downloadModel({
    required Function(double) onProgress,
    required Function() onCompleted,
    required Function(String) onError,
  }) async {
    try {
      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      )
          .fromNetwork(modelUrl, foreground: true)
          .withProgress((progress) {
            onProgress(progress / 100.0);
          })
          .install();
      onCompleted();
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> initializeGemma() async {
    await FlutterGemma.initialize();
    
    if (await FlutterGemma.isModelInstalled(modelFileName)) {
       await FlutterGemma.installModel(
         modelType: ModelType.gemma4,
         fileType: ModelFileType.litertlm,
       ).fromNetwork(modelUrl).install(); 
    } else {
       final file = await localFile;
       if (await file.exists()) {
         await FlutterGemma.installModel(
           modelType: ModelType.gemma4,
           fileType: ModelFileType.litertlm,
         ).fromFile(file.path).install();
       }
    }
  }
}
