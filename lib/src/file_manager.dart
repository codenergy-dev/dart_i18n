import 'dart:convert';
import 'dart:io';

class InputedData {
  final String filePath;
  final List<String> lines;
  InputedData({
    required this.filePath,
    required this.lines,
  });
}

class FileManager {

  List<InputedData> extractedData = [];

  Future<void> readDartFilePerLines({required String filePath}) async {
    final File file = File(filePath);
    if(await file.exists()) {
      List<String> lines = await file.readAsLines();
      InputedData inputData = InputedData(filePath: filePath, lines: lines);
      extractedData.add(inputData);
    } else {
      throw Exception('File do not exists');
    }
  }

  void writeReferenceFile({required String filepath, required Map<String, List<String>> data}) {
    final File file = File(filepath);
    final IOSink sink = file.openWrite();
    for(String key in data.keys) {
      sink.write('$key:\n');
      for(String specificLines in data[key]!) {
        sink.write('$specificLines\n');
      }
      sink.write('\n\n');
    }
    sink.close();
  }

  Future<Map<String, dynamic>> readJsonFile({ required String filepath }) async {
    final File file = File(filepath);
    if(await file.exists()) {
      final String content = file.readAsStringSync();
      JsonDecoder jsonDecoder = JsonDecoder();
      try {
        Map<String, dynamic> json = jsonDecoder.convert(content);
        return json;
      } catch (_) {
      }
        return {};
    } else {
      throw Exception('File do not exists');
    }
  }

  void writeJsonFile({required String outputFilePath, required Map<String, dynamic> data}) {
    final File file = File(outputFilePath);
    final IOSink sink = file.openWrite();
    JsonEncoder jsonEncoder = JsonEncoder.withIndent(' ' * 4);
    String json = jsonEncoder.convert(data);
    sink.write(json.replaceAll(r'\\', r'\'));
    sink.close();
  }

  Future<void> updateJsonFile({ required String filepath, required Map<String, dynamic> newData }) async {
    final Map<String, dynamic> previousJson = await readJsonFile(filepath: filepath);
    for(String key in newData.keys) {
      if(previousJson[key] != null) {
        newData[key] = previousJson[key];
      }
    }
    writeJsonFile(outputFilePath: filepath, data: newData);
  }

  Future<void> writeOrUpdateJsonFile({
    required String outputFileName,
    required String outputDirPath,
    required Map<String, dynamic> newData,
  }) async{
    final outputDir = Directory(outputDirPath);
    if(await outputDir.exists()) {
      final listFiles = outputDir.listSync();
      for(FileSystemEntity file in listFiles) {
        if(file.path.contains(outputFileName)) {
          return updateJsonFile(filepath: file.path, newData: newData);
        }
      }
      return writeJsonFile(outputFilePath: outputFileName, data: newData);
    } else {
      throw Exception('Output Directory do not exists.');
    }
  }

}