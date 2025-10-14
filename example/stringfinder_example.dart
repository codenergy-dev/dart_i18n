import 'dart:io';

import 'package:dart_i18n/dart_i18n.dart';

String sk8erPath = '../sk8ers/lib';
String jsonOutputPath = './example/files/pt_BR.json';

Future<void> main() async {
  await updateStrings();
}

Future<void> extractStrings() async {
  String referenceOutputPath = './example/files/reference.txt';
  DartFileFinder dartFileFinder = DartFileFinder(
    dirPath: sk8erPath, 
    ignoreDirs: ['mockup/', 'constants/', 'i18n/'],
  );
  List<FileSystemEntity> dartFiles = await dartFileFinder.searchForDartFiles();
  FileManager fileManager = FileManager();
  for(FileSystemEntity file in dartFiles) {
    await fileManager.readDartFilePerLines(filePath: file.path);
  }
  StringFinder stringFinder = StringFinder();
  for(InputedData data in fileManager.extractedData) {
    stringFinder.getAllInnerString(filePath: data.filePath, textLines: data.lines);
  }
  Map<String, List<String>> referenceData = stringFinder.generateReferenceFileData();
  Map<String, dynamic> jsonData = stringFinder.generateJsonFileData();
  fileManager.writeReferenceFile(filepath: referenceOutputPath, data: referenceData);
  fileManager.writeJsonFile(outputFilePath: jsonOutputPath, data: jsonData);
}

Future<void> updateStrings() async {
  DartFileFinder dartFileFinder = DartFileFinder(
    dirPath: sk8erPath, 
    ignoreDirs: ['mockup/', 'constants/', 'i18n/'],
  );
  List<FileSystemEntity> dartFiles = await dartFileFinder.searchForDartFiles();
  FileManager fileManager = FileManager();
  for(FileSystemEntity file in dartFiles) {
    await fileManager.readDartFilePerLines(filePath: file.path);
  }
  StringFinder stringFinder = StringFinder();
  for(InputedData data in fileManager.extractedData) {
    stringFinder.getAllInnerString(filePath: data.filePath, textLines: data.lines);
  }
  Map<String, dynamic> jsonData = stringFinder.generateJsonFileData();
  fileManager.updateJsonFile(filepath: jsonOutputPath, newData: jsonData);
}