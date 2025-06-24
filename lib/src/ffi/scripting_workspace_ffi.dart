// ignore_for_file: collection_methods_unrelated_type

import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:rive_native/scripting_workspace.dart';
import 'package:rive_native/src/ffi/dynamic_library_helper.dart';
import 'package:rive_native/utilities.dart';

final DynamicLibrary _nativeLib = DynamicLibraryHelper.nativeLib;

Pointer<Void> Function(Pointer<NativeFunction<Void Function(Pointer<Void>)>>)
    _makeScriptingWorkspace = _nativeLib
        .lookup<
                NativeFunction<
                    Pointer<Void> Function(
                        Pointer<
                            NativeFunction<Void Function(Pointer<Void>)>>)>>(
            'makeScriptingWorkspace')
        .asFunction();
void Function(
  Pointer<Void> workspace,
) _deleteScriptingWorkspace = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'deleteScriptingWorkspace')
    .asFunction();
Pointer<Void> Function(
  Pointer<Void> workspace,
  Pointer<Utf8> scriptName,
  Pointer<Utf8> source,
) _setScriptSource = _nativeLib
    .lookup<
        NativeFunction<
            Pointer<Void> Function(
              Pointer<Void>,
              Pointer<Utf8>,
              Pointer<Utf8>,
            )>>('scriptingWorkspaceSetScriptSource')
    .asFunction();

Pointer<Void> Function(
  Pointer<Void> workspace,
  Pointer<Utf8> source,
) _format = _nativeLib
    .lookup<
        NativeFunction<
            Pointer<Void> Function(
              Pointer<Void>,
              Pointer<Utf8>,
            )>>('scriptingWorkspaceFormat')
    .asFunction();

Pointer<Void> Function(
  Pointer<Void>,
  Pointer<Utf8> scriptName,
) _requestProblemReport = _nativeLib
    .lookup<
        NativeFunction<
            Pointer<Void> Function(
              Pointer<Void>,
              Pointer<Utf8> scriptName,
            )>>('scriptingWorkspaceRequestProblemReport')
    .asFunction();

int Function(
  Pointer<Void>,
  Pointer<Utf8> scriptName,
  int line,
  int column,
) _scriptingWorkspaceCompleteInsertion = _nativeLib
    .lookup<
        NativeFunction<
            Uint8 Function(
              Pointer<Void>,
              Pointer<Utf8> scriptName,
              Uint32 line,
              Uint32 column,
            )>>('scriptingWorkspaceCompleteInsertion')
    .asFunction();

Pointer<Void> Function(
  Pointer<Void>,
  Pointer<Utf8> scriptName,
  int line,
  int column,
) _scriptingWorkspaceRequestAutocomplete = _nativeLib
    .lookup<
        NativeFunction<
            Pointer<Void> Function(
              Pointer<Void>,
              Pointer<Utf8> scriptName,
              Uint32 line,
              Uint32 column,
            )>>('scriptingWorkspaceRequestAutocomplete')
    .asFunction();

HighlightBuffer Function(
  Pointer<Void>,
  Pointer<Utf8> scriptName,
  int row,
) _scriptingWorkspaceHighlightRow = _nativeLib
    .lookup<
        NativeFunction<
            HighlightBuffer Function(
              Pointer<Void>,
              Pointer<Utf8> scriptName,
              Uint32 row,
            )>>('scriptingWorkspaceHighlightRow')
    .asFunction();

final class HighlightBuffer extends Struct {
  @Uint32()
  external int count;

  external Pointer<Uint32> data;
}

final class ScriptingWorkspaceResponseResult extends Struct {
  @Bool()
  external bool available;

  external Pointer<Uint8> data;

  @Size()
  external int size;
}

ScriptingWorkspaceResponseResult Function(
  Pointer<Void> workspace,
  Pointer<Void> workId,
) _scriptingWorkspaceResponse = _nativeLib
    .lookup<
        NativeFunction<
            ScriptingWorkspaceResponseResult Function(
              Pointer<Void> workspace,
              Pointer<Void> workId,
            )>>('scriptingWorkspaceResponse')
    .asFunction();

class ScriptingWorkspaceFFI extends ScriptingWorkspace {
  late Pointer<Void> _nativeWorkspace;
  NativeCallable<Void Function(Pointer<Void>)>? _callable;
  ScriptingWorkspaceFFI() {
    _callable = NativeCallable<Void Function(Pointer<Void>)>.listener(
        _workReadyCallback);

    final callback = _callable;
    _nativeWorkspace = callback == null
        ? nullptr
        : _makeScriptingWorkspace(callback.nativeFunction);
  }

  void _workReadyCallback(Pointer<Void> workId) {
    var completer = _completers.remove(workId.address);
    if (completer == null) {
      return;
    }
    var response = _scriptingWorkspaceResponse(_nativeWorkspace, workId);
    assert(response.available);

    if (completer is Completer<ScriptProblemResult>) {
      _completeProblemReport(completer, response);
    } else if (completer is Completer<HighlightResult>) {
      _completeHighlight(completer, response);
    } else if (completer is Completer<FormatResult>) {
      _completeFormat(completer, response);
    } else if (completer is Completer<AutocompleteResult>) {
      _completeAutocomplete(completer, response);
    }
  }

  @override
  void dispose() {
    _callable?.close();
    _callable = null;
    _deleteScriptingWorkspace(_nativeWorkspace);
    _nativeWorkspace = nullptr;
  }

  @override
  Future<AutocompleteResult> autocomplete(
      String scriptName, ScriptPosition position) {
    var scriptNameNative = scriptName.toNativeUtf8(allocator: calloc);
    var workId = _scriptingWorkspaceRequestAutocomplete(
      _nativeWorkspace,
      scriptNameNative,
      position.line,
      position.column,
    );
    calloc.free(scriptNameNative);
    var response = _scriptingWorkspaceResponse(_nativeWorkspace, workId);
    final completer = Completer<AutocompleteResult>();
    if (response.available) {
      _completeAutocomplete(completer, response);
    } else {
      assert(!_completers.containsKey(workId));
      _completers[workId.address] = completer;
    }
    return completer.future;
  }

  void _completeAutocomplete(Completer<AutocompleteResult> completer,
      ScriptingWorkspaceResponseResult result) {
    assert(result.available);
    var data = result.data.asTypedList(result.size);

    var reader = BinaryReader.fromList(data);
    var fromLine = reader.readVarUint();
    var fromColumn = reader.readVarUint();
    var toLine = reader.readVarUint();
    var toColumn = reader.readVarUint();

    List<AutocompleteEntry> entries = [];
    while (!reader.isEOF) {
      entries.add(
        AutocompleteEntry(
          value: reader.readString(),
          typeName: reader.readString(),
        ),
      );
    }

    completer.complete(
      AutocompleteResult(
        range: ScriptRange(
          begin: ScriptPosition(
            line: fromLine,
            column: fromColumn,
          ),
          end: ScriptPosition(
            line: toLine,
            column: toColumn,
          ),
        ),
        entries: entries,
      ),
    );
  }

  static ScriptPosition _readPosition(BinaryReader reader) =>
      ScriptPosition(line: reader.readVarUint(), column: reader.readVarUint());

  static ScriptRange _readRange(BinaryReader reader) => ScriptRange(
        begin: _readPosition(reader),
        end: _readPosition(reader),
      );

  static ScriptProblem _readProblem(BinaryReader reader) => ScriptProblem(
        type: ScriptProblemType.values[reader.readUint8()],
        range: _readRange(reader),
        message: reader.readString(),
      );

  void _completeHighlight(Completer<HighlightResult> completer,
      ScriptingWorkspaceResponseResult result) {
    completer.complete(HighlightResult.computed);
  }

  void _completeFormat(Completer<FormatResult> completer,
      ScriptingWorkspaceResponseResult result) {
    assert(result.available);
    var data = result.data.asTypedList(result.size);

    var reader = BinaryReader.fromList(data);
    completer.complete(FormatResult.read(reader));
  }

  void _completeProblemReport(Completer<ScriptProblemResult> completer,
      ScriptingWorkspaceResponseResult result) {
    assert(result.available);
    var data = result.data.asTypedList(result.size);

    var reader = BinaryReader.fromList(data);
    var scriptName = reader.readString();
    var errorCount = reader.readVarUint();
    var warningCount = reader.readVarUint();

    var errors = <ScriptProblem>[];
    for (int i = 0; i < errorCount; i++) {
      errors.add(_readProblem(reader));
    }

    var warnings = <ScriptProblem>[];
    for (int i = 0; i < warningCount; i++) {
      warnings.add(_readProblem(reader));
    }

    completer.complete(ScriptProblemResult(
      scriptName: scriptName,
      errors: errors,
      warnings: warnings,
    ));
  }

  @override
  Future<ScriptProblemResult> problemReport(String scriptName) {
    var scriptNameNative = scriptName.toNativeUtf8(allocator: calloc);
    final completer = Completer<ScriptProblemResult>();
    var workId = _requestProblemReport(_nativeWorkspace, scriptNameNative);
    var response = _scriptingWorkspaceResponse(_nativeWorkspace, workId);
    if (response.available) {
      _completeProblemReport(completer, response);
    } else {
      assert(!_completers.containsKey(workId));
      _completers[workId.address] = completer;
    }
    calloc.free(scriptNameNative);

    return completer.future;
  }

  @override
  Future<List<ScriptProblemResult>> fullProblemReport() {
    // TODO: implement fullErrorReport

    throw UnimplementedError();
  }

  final HashMap<int, Completer> _completers = HashMap<int, Completer>();

  @override
  Future<HighlightResult> setScriptSource(String scriptName, String source,
      {bool highlight = false}) async {
    final scriptNameNative = scriptName.toNativeUtf8(allocator: calloc);
    final sourceNative = source.toNativeUtf8(allocator: calloc);
    final workId =
        _setScriptSource(_nativeWorkspace, scriptNameNative, sourceNative);
    calloc.free(scriptNameNative);
    calloc.free(sourceNative);
    if (!highlight) {
      return HighlightResult.unknown;
    }
    var response = _scriptingWorkspaceResponse(_nativeWorkspace, workId);
    final completer = Completer<HighlightResult>();
    if (response.available) {
      _completeHighlight(completer, response);
    } else {
      assert(!_completers.containsKey(workId));
      _completers[workId.address] = completer;
    }
    return completer.future;
  }

  @override
  Future<FormatResult> format(String scriptName) async {
    var sourceNative = scriptName.toNativeUtf8(allocator: calloc);
    var workId = _format(_nativeWorkspace, sourceNative);
    calloc.free(sourceNative);

    var response = _scriptingWorkspaceResponse(_nativeWorkspace, workId);
    final completer = Completer<FormatResult>();
    if (response.available) {
      _completeFormat(completer, response);
    } else {
      assert(!_completers.containsKey(workId.address));
      _completers[workId.address] = completer;
    }
    return completer.future;
  }

  @override
  Uint32List rowHighlight(String scriptName, int row) {
    var scriptNameNative = scriptName.toNativeUtf8(allocator: calloc);
    var result = _scriptingWorkspaceHighlightRow(
        _nativeWorkspace, scriptNameNative, row);
    calloc.free(scriptNameNative);
    return result.data.asTypedList(result.count);
  }

  @override
  InsertionCompletion completeInsertion(
      String scriptName, ScriptPosition position) {
    var scriptNameNative = scriptName.toNativeUtf8(allocator: calloc);
    var completionType = _scriptingWorkspaceCompleteInsertion(
      _nativeWorkspace,
      scriptNameNative,
      position.line,
      position.column,
    );
    calloc.free(scriptNameNative);
    return InsertionCompletion.values[completionType];
  }
}

ScriptingWorkspace makeScriptingWorkspace() => ScriptingWorkspaceFFI();
