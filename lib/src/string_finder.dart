import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class FoundString {
  final String filePath;
  final Map<String, List<int>> stringsPerLine = {};

  FoundString({
    required this.filePath,
  });
}

class StringFinder {

  List<FoundString> stringsFoundPerFile = [];

  void getAllInnerString({
    required String filePath,
    required List<String> textLines,
  }) {
    final foundStrings = FoundString(filePath: filePath);
    final content = textLines.join('\n');
    final unit = parseString(content: content).unit;

    unit.visitChildren(_I18nVisitor((value, line) {
      if (!foundStrings.stringsPerLine.containsKey(value)) {
        foundStrings.stringsPerLine[value] = [];
      }
      foundStrings.stringsPerLine[value]!.add(line);
    }));

    stringsFoundPerFile.add(foundStrings);
  }

  Map<String,List<String>> generateReferenceFileData() {
    Map<String,List<String>> allStrings = {};
    for(FoundString stringFinder in stringsFoundPerFile) {
      for (String key in stringFinder.stringsPerLine.keys) {
        List<int> lines = stringFinder.stringsPerLine[key]!;
        String fileLines = '${stringFinder.filePath}: ${lines.toString()}';
        if(!allStrings.keys.contains(key)) {
          allStrings[key] = [];
        }
        allStrings[key]!.add(fileLines);
      }
    }
    return allStrings;
  }

  Map<String, String> generateJsonFileData() {
    Map<String, String> allStrings = {};
    for (FoundString foundString in stringsFoundPerFile) {
      for(String string in foundString.stringsPerLine.keys) {
        allStrings[string] = string;
      }
    }
    return allStrings;
  }

  bool containsImport({required String text}) {
    RegExp pattern = RegExp(r"^import\s['].*[']");
    return pattern.hasMatch(text);
  }

  bool containsPart({required String text}) {
    RegExp pattern = RegExp(r"^part\s['].*[']");
    return pattern.hasMatch(text);
  }

  bool containsMapKeys({required String text}) {
    return text.contains('"]') || text.contains("']");
  }

  bool validateString({
    required String text,
    required bool removeImports,
    required bool removePart,
    required bool removeMapKeys,
    }) {
    if(removeImports && containsImport(text: text)) {return true;}
    else if(removePart && containsPart(text: text)) {return true;}
    else if(removeMapKeys && containsMapKeys(text: text)) {return true;}
    else {return false;}
  }
}

class _I18nVisitor extends RecursiveAstVisitor<void> {
  final void Function(String value, int line) onFound;

  _I18nVisitor(this.onFound);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Queremos apenas chamadas do tipo "<string>.i18n()"
    if (node.methodName.name == 'i18n' && node.target is StringLiteral) {
      final literal = node.target as StringLiteral;
      final value = literal.stringValue ?? '';
      // final lineInfo = node.root.beginToken.lineInfo;
      // final lineNumber = lineInfo?.getLocation(node.offset).lineNumber ?? 0;
      // onFound(value, lineNumber);
      onFound(value, 0);
    }
    super.visitMethodInvocation(node);
  }
}
