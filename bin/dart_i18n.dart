import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'package:dart_i18n/dart_i18n.dart';

const String extractCommand = 'extract';
const String helpCommand = 'help';
const String createReferenceFile = 'reference-file';
const String ignoredDirsOptions = 'ignore-dirs';
const String localeOptions = 'locale';
const String verboseMode = 'verbose';

void main(List<String> arguments) {
  exitCode = 0;

  final extractCommandArgParser = ArgParser()
    ..addMultiOption(
      ignoredDirsOptions,
      abbr: 'i',
      valueHelp: 'dirnames',
      help: 'List all directories, separated by comma(,), to ignore inner Search Directory',
    )
    ..addMultiOption(
      localeOptions, 
      abbr: 'l',
      valueHelp: 'language_code',
      help: 'List all locale json file that you want to create.',
    )
    ..addFlag(
      createReferenceFile, 
      abbr: 'r',
      negatable: false, 
      help: 'Create a reference file (.txt) list all strings found by files and lines.'
    )
    ..addFlag(
      verboseMode, 
      abbr: 'v',
      negatable: false,
      help: 'Show additional diagnostic info.' 
    );

  final parser = ArgParser()
    ..addCommand(extractCommand, extractCommandArgParser)
    ..addCommand(helpCommand);

  ArgResults argResults = parser.parse(arguments);

  switch (argResults.command?.name) {
    case extractCommand:
      extractStringsToJson(
        searchDir: argResults.command!.rest[0],
        outputDir: argResults.command!.rest.length > 1 ? argResults.command!.rest[1] : './example/files',
        ignoredDirs: argResults.command![ignoredDirsOptions],
        locales: argResults.command![localeOptions],
        referenceFile: argResults.command![createReferenceFile] as bool,
        verboseMode: argResults.command![verboseMode] as bool,
      );  
      break;
    case helpCommand:
      for(final command in parser.commands.keys) {
        if(command != helpCommand) {
          print('[$command]');
          print(parser.commands[command]?.usage);
        }

      }
      break;
    default:
      exitCode = 2;
      stderr.writeln('Invalid command: ${argResults.command}');
      exit(2);
  }
}

Future<void> extractStringsToJson({ 
  required String searchDir,
  required String outputDir,
  List<String> ignoredDirs = const [],
  List<String> locales = const [],
  bool referenceFile = false,
  bool verboseMode = false,
}) async {

  final outputDirectory = Directory(outputDir);
  List<String> jsonFilesInOutputDir = [];

  stdout.writeln('Search directory: $searchDir');
  stdout.writeln('Ignored directories: $ignoredDirs');
  stdout.writeln('Output directory: $outputDir');
  if(await outputDirectory.exists()) {
    List<FileSystemEntity> files = outputDirectory.listSync();
    stdout.writeln('These json files were found in output directory:');
    for(final file in files) {
      if(file.path.contains('.json')) {
        jsonFilesInOutputDir.add(file.path);
        String filenameWithExt = path.split(file.path).last;
        String filenameWithoutExt = filenameWithExt.replaceAll('.json', '');
        stdout.writeln(
          locales.contains(filenameWithoutExt) && !files.contains(file) 
            ? '- $filenameWithExt (it will be created)'
            : '- $filenameWithExt (it will be updated)');
        locales.add(filenameWithoutExt);
      }
    }
    locales = locales.toSet().toList();
    stdout.writeln('Locales detected: ${locales.toString()}');
  } else {
    stdout.writeln('Output directory do not exist, so it will be created during the process');
    outputDirectory.create(recursive: true);
  }
  stdout.writeln('Do you want to continue? [y/n]');
  String response = stdin.readLineSync() ?? 'n';
  if(response == 'y') {
    DartFileFinder dartFileFinder = DartFileFinder(
      dirPath: searchDir, 
      ignoreDirs: ignoredDirs,
    );
    List<FileSystemEntity> dartFiles = await dartFileFinder.searchForDartFiles();
    if(verboseMode) {
      stdout.writeln('Found ${dartFiles.length} dart files:');
      for(FileSystemEntity file in dartFiles) {
        stdout.writeln(file.path);
      }
    } else {
      stdout.writeln('Found ${dartFiles.length} dart files.');
    }
    FileManager fileManager = FileManager();
    for(FileSystemEntity file in dartFiles) {
      await fileManager.readDartFilePerLines(filePath: file.path);
    }
    StringFinder stringFinder = StringFinder();
    for(InputedData data in fileManager.extractedData) {
      stringFinder.getAllInnerString(filePath: data.filePath, textLines: data.lines);
    }
    if(referenceFile) {
      Map<String, List<String>> referenceData = stringFinder.generateReferenceFileData();
      fileManager.writeReferenceFile(filepath: '$outputDir/reference.txt', data: referenceData);
    }
    Map<String, dynamic> jsonData = stringFinder.generateJsonFileData();
    stdout.writeln('${jsonData.keys.length} strings were found!');
    if(locales.isNotEmpty) {
      for(String locale in locales) {
        if(jsonFilesInOutputDir.any((filepath) => filepath.contains(locale))) {
          fileManager.updateJsonFile(filepath: path.join(outputDir,'$locale.json'), newData: jsonData);
          stdout.writeln('- $locale.json was updated');
        } else {
          fileManager.writeJsonFile(outputFilePath: path.join(outputDir,'$locale.json'), data: jsonData);
          stdout.writeln('- $locale.json was created');
        }
      }
    } else {
      fileManager.writeJsonFile(outputFilePath: '$outputDir/strings.json', data: jsonData);
      stdout.writeln('Created locale file strings.json in $outputDir');
    }
  } else {
    exit(0);
  }
}