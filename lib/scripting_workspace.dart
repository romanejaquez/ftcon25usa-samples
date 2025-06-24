import 'dart:typed_data';

import 'package:rive_native/src/utilities/utilities.dart';

import 'package:rive_native/src/ffi/scripting_workspace_ffi.dart'
    if (dart.library.js_interop) 'package:rive_native/src/web/scripting_workspace_web.dart';
import 'package:rive_native/utilities.dart';

enum HighlightScope {
  none,
  keyword,
  type,
  literal,
  number,
  operator,
  punctuation,
  property,
  string,
  comment,
  boolean,
  nil,
  interpString,
  function
}

class FormatOp {
  final ScriptPosition position;
  Object? userdata;
  FormatOp({required this.position});
}

class FormatOpInsert extends FormatOp {
  final String text;

  FormatOpInsert({
    required super.position,
    required this.text,
  });
}

class FormatOpErase extends FormatOp {
  final ScriptPosition positionEnd;

  FormatOpErase({required super.position, required this.positionEnd});
}

class FormatResult {
  final List<FormatOp> operations;

  FormatResult({required this.operations});

  static FormatResult read(BinaryReader reader) {
    final List<FormatOp> operations = [];
    while (!reader.isEOF) {
      switch (reader.readUint8()) {
        case 1:
          final line = reader.readVarUint();
          final column = reader.readVarUint();
          final text = reader.readString();
          operations.add(
            FormatOpInsert(
              position: ScriptPosition(line: line, column: column),
              text: text,
            ),
          );
          break;
        case 0:
          final lineFrom = reader.readVarUint();
          final columnFrom = reader.readVarUint();
          final lineTo = reader.readVarUint();
          final columnTo = reader.readVarUint();
          operations.add(
            FormatOpErase(
              position: ScriptPosition(line: lineFrom, column: columnFrom),
              positionEnd: ScriptPosition(line: lineTo, column: columnTo),
            ),
          );
          break;
      }
    }
    return FormatResult(operations: operations);
  }
}

class ScriptPosition implements Comparable<ScriptPosition> {
  final int line;
  final int column;

  const ScriptPosition({required this.line, required this.column});

  @override
  int get hashCode => szudzik(line, column);

  @override
  bool operator ==(Object other) =>
      other is ScriptPosition && other.line == line && other.column == column;

  @override
  String toString() => 'Ln $line, Col $column';

  @override
  int compareTo(ScriptPosition other) {
    if (line < other.line) {
      return -1;
    }
    if (line > other.line) {
      return 1;
    }
    if (column < other.column) {
      return -1;
    }
    if (column > other.column) {
      return 1;
    }
    return 0;
  }
}

class ScriptRange {
  final ScriptPosition begin;
  final ScriptPosition end;

  const ScriptRange({required this.begin, required this.end});

  bool get isCollapsed => begin == end;

  @override
  String toString() => '$begin -> $end';

  @override
  int get hashCode =>
      Object.hash(begin.line, begin.column, end.line, end.column);

  @override
  bool operator ==(Object other) =>
      other is ScriptRange && other.begin == begin && other.end == end;
}

enum ScriptProblemType {
  unknown,

  linterUnknownGlobal,
  linterDeprecatedGlobal,
  linterGlobalUsedAsLocal,
  linterLocalShadow,
  linterSameLineStatement,
  linterMultiLineStatement,
  linterLocalUnused,
  linterFunctionUnused,
  linterImportUnused,
  linterBuiltinGlobalWrite,
  linterPlaceholderRead,
  linterUnreachableCode,
  linterUnknownType,
  linterForRange,
  linterUnbalancedAssignment,
  linterImplicitReturn,
  linterDuplicateLocal,
  linterFormatString,
  linterTableLiteral,
  linterUninitializedLocal,
  linterDuplicateFunction,
  linterDeprecatedApi,
  linterTableOperations,
  linterDuplicateCondition,
  linterMisleadingAndOr,
  linterCommentDirective,
  linterIntegerParsing,
  linterComparisonPrecedence,

  typeError,
  syntaxError,
}

class ScriptProblemResult {
  final String scriptName;
  final List<ScriptProblem> errors;
  final List<ScriptProblem> warnings;

  ScriptProblemResult(
      {required this.scriptName, required this.errors, required this.warnings});
}

class ScriptProblem {
  final ScriptRange range;
  final String message;
  final ScriptProblemType type;

  ScriptProblem({
    required this.range,
    required this.message,
    required this.type,
  });

  @override
  String toString() => 'ScriptProblem($type:$range) - $message';

  @override
  int get hashCode => Object.hash(range, message, type);

  @override
  bool operator ==(Object other) =>
      other is ScriptProblem &&
      other.type == type &&
      other.range == range &&
      other.message == message;
}

class AutocompleteResult {
  final ScriptRange range;
  final List<AutocompleteEntry> entries;

  AutocompleteResult({required this.range, required this.entries});
}

class AutocompleteEntry {
  final String value;
  final String typeName;

  AutocompleteEntry({required this.value, required this.typeName});
}

enum HighlightResult { unknown, computed }

enum InsertionCompletion { none, end, doEnd, until, thenEnd }

/// A workspace represents a collection of files that are likely related
/// (usually part of a single Rive file).
abstract class ScriptingWorkspace {
  /// Set the [source] code for the script with [scriptName]. Calling this again
  /// with the same [scriptName] will overwrite the script. Set [highlight] to
  /// true if you'd like to have highlighting data computed.
  Future<HighlightResult> setScriptSource(String scriptName, String source,
      {bool highlight = false});

  /// Formats module named [scriptName].
  Future<FormatResult> format(String scriptName);

  /// Get the highlight data for a single row of [scriptName].
  Uint32List rowHighlight(String scriptName, int row);

  /// Get an error report for all the script files in this workspace.
  Future<List<ScriptProblemResult>> fullProblemReport();

  /// Get an error report for a script file with identified by [scriptName].
  Future<ScriptProblemResult> problemReport(String scriptName);

  /// Get possible autocompletion results at [position] in script with name
  /// [scriptName].
  Future<AutocompleteResult> autocomplete(
      String scriptName, ScriptPosition position);

  /// Dispose of the workspace, any further calls will not work.
  void dispose();

  /// Get extra text insertion to be auto-completed at the given position.
  InsertionCompletion completeInsertion(
      String scriptName, ScriptPosition position);

  static ScriptingWorkspace make() => makeScriptingWorkspace();
}
