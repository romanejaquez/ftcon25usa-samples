// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:collection';
import 'dart:js_interop' as js;
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:rive_native/scripting_workspace.dart';
import 'package:rive_native/utilities.dart';

late js.JSFunction _makeScriptingWorkspace;
late js.JSFunction _deleteScriptingWorkspace;
late js.JSFunction _requestProblemReport;
late js.JSFunction _scriptingWorkspaceCompleteInsertion;
// ignore: unused_element
late js.JSFunction _scriptingWorkspaceRequestAutocomplete;
late js.JSFunction _scriptingWorkspaceHighlightRow;
late js.JSFunction _scriptingWorkspaceResponse;
late js.JSFunction _setScriptSource;
late js.JSFunction _scriptingWorkspaceFormat;

class ScriptingWorkspaceResponseResult {
  final bool available;
  late final Uint8List? data;
  ScriptingWorkspaceResponseResult(js.JSObject object)
      : available = (object['available'] as js.JSBoolean).toDart {
    data = available ? (object['data'] as js.JSUint8Array).toDart : null;
  }
}

class ScriptingWorkspaceWasm extends ScriptingWorkspace {
  static void link(js.JSObject module) {
    _makeScriptingWorkspace = module['makeScriptingWorkspace'] as js.JSFunction;
    _deleteScriptingWorkspace =
        module['_deleteScriptingWorkspace'] as js.JSFunction;
    _requestProblemReport =
        module['scriptingWorkspaceRequestProblemReport'] as js.JSFunction;
    _scriptingWorkspaceCompleteInsertion =
        module['scriptingWorkspaceCompleteInsertion'] as js.JSFunction;
    _scriptingWorkspaceRequestAutocomplete =
        module['_scriptingWorkspaceRequestAutocomplete'] as js.JSFunction;
    _scriptingWorkspaceHighlightRow =
        module['scriptingWorkspaceHighlightRow'] as js.JSFunction;
    _scriptingWorkspaceResponse =
        module['scriptingWorkspaceResponse'] as js.JSFunction;
    _setScriptSource =
        module['scriptingWorkspaceSetScriptSource'] as js.JSFunction;
    _scriptingWorkspaceFormat =
        module['scriptingWorkspaceFormat'] as js.JSFunction;
  }

  static final Finalizer<int> _finalizer = Finalizer(
    (nativePtr) => _deleteScriptingWorkspace.callAsFunction(
      null,
      nativePtr.toJS,
    ),
  );
  int _nativePtr = 0;

  ScriptingWorkspaceWasm() {
    _nativePtr = (_makeScriptingWorkspace.callAsFunction(
      null,
      _workReadyCallback.toJS,
    ) as js.JSNumber)
        .toDartInt;
    _finalizer.attach(this, _nativePtr, detach: this);
  }

  final HashMap<int, Completer> _completers = HashMap<int, Completer>();

  void _workReadyCallback(int workId) {
    var completer = _completers.remove(workId);
    if (completer == null) {
      return;
    }
    var response = ScriptingWorkspaceResponseResult(
      _scriptingWorkspaceResponse.callAsFunction(
        null,
        _nativePtr.toJS,
        workId.toJS,
      ) as js.JSObject,
    );

    assert(response.available);
    if (completer is Completer<ScriptProblemResult>) {
      _completeProblemReport(completer, response);
    } else if (completer is Completer<HighlightResult>) {
      _completeHighlight(completer, response);
    } else if (completer is Completer<FormatResult>) {
      _completeFormat(completer, response);
    } else if (completer is Completer<AutocompleteResult>) {
      // _completeAutocomplete(completer, response);
    }
  }

  @override
  void dispose() {
    _deleteScriptingWorkspace.callAsFunction(null, _nativePtr.toJS);
    _nativePtr = 0;
    _finalizer.detach(this);
  }

  @override
  Future<AutocompleteResult> autocomplete(
      String scriptName, ScriptPosition position) {
    print('--> autocomplete');
    // TODO: implement autocomplete
    throw UnimplementedError();
  }

  @override
  InsertionCompletion completeInsertion(
      String scriptName, ScriptPosition position) {
    final completionType = (_scriptingWorkspaceCompleteInsertion.callAsFunction(
            null,
            _nativePtr.toJS,
            scriptName.toJS,
            position.line.toJS,
            position.column.toJS) as js.JSNumber)
        .toDartInt;
    print('completion type: $completionType');
    return InsertionCompletion.values[completionType];
  }

  @override
  Future<FormatResult> format(String scriptName) {
    final workId = (_scriptingWorkspaceFormat.callAsFunction(
            null, _nativePtr.toJS, scriptName.toJS) as js.JSNumber)
        .toDartInt;

    var response = ScriptingWorkspaceResponseResult(
      _scriptingWorkspaceResponse.callAsFunction(
        null,
        _nativePtr.toJS,
        workId.toJS,
      ) as js.JSObject,
    );
    final completer = Completer<FormatResult>();
    if (response.available) {
      _completeFormat(completer, response);
    } else {
      assert(!_completers.containsKey(workId));
      _completers[workId] = completer;
    }
    return completer.future;
  }

  @override
  Future<List<ScriptProblemResult>> fullProblemReport() {
    print('--> full problem report');
    // TODO: implement fullProblemReport
    throw UnimplementedError();
  }

  @override
  Future<ScriptProblemResult> problemReport(String scriptName) async {
    final completer = Completer<ScriptProblemResult>();
    var workId = (_requestProblemReport.callAsFunction(
            null, _nativePtr.toJS, scriptName.toJS) as js.JSNumber)
        .toDartInt;
    var response = ScriptingWorkspaceResponseResult(
      _scriptingWorkspaceResponse.callAsFunction(
        null,
        _nativePtr.toJS,
        workId.toJS,
      ) as js.JSObject,
    );
    if (response.available) {
      _completeProblemReport(completer, response);
    } else {
      assert(!_completers.containsKey(workId));
      _completers[workId] = completer;
    }
    return completer.future;
  }

  @override
  Uint32List rowHighlight(String scriptName, int row) {
    var result = _scriptingWorkspaceHighlightRow.callAsFunction(
        null, _nativePtr.toJS, scriptName.toJS, row.toJS) as js.JSUint32Array;
    return result.toDart;
  }

  @override
  Future<HighlightResult> setScriptSource(String scriptName, String source,
      {bool highlight = false}) async {
    final workId = (_setScriptSource.callAsFunction(null, _nativePtr.toJS,
            scriptName.toJS, source.toJS, highlight.toJS) as js.JSNumber)
        .toDartInt;
    if (!highlight) {
      return HighlightResult.unknown;
    }
    var response = ScriptingWorkspaceResponseResult(
      _scriptingWorkspaceResponse.callAsFunction(
        null,
        _nativePtr.toJS,
        workId.toJS,
      ) as js.JSObject,
    );
    final completer = Completer<HighlightResult>();
    if (response.available) {
      _completeHighlight(completer, response);
    } else {
      assert(!_completers.containsKey(workId));
      _completers[workId] = completer;
    }
    return completer.future;
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

  void _completeProblemReport(Completer<ScriptProblemResult> completer,
      ScriptingWorkspaceResponseResult result) {
    assert(result.available);
    var data = result.data;
    if (data == null) {
      return;
    }

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

  void _completeFormat(Completer<FormatResult> completer,
      ScriptingWorkspaceResponseResult result) {
    assert(result.available);
    var data = result.data;
    if (data == null) {
      return;
    }

    var reader = BinaryReader.fromList(data);

    completer.complete(FormatResult.read(reader));
  }
}

ScriptingWorkspace makeScriptingWorkspace() => ScriptingWorkspaceWasm();
