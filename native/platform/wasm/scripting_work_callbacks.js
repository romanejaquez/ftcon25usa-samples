var previousInit = Module["onRuntimeInitialized"];
Module["onRuntimeInitialized"] = function () {
  previousInit();
  // We do some work here to connect our own messaging protocol between worker
  // threads and this main thread because emscripten_async_run_in_main_thread
  // and MAIN_THREAD_ASYNC_EM_ASM cause deadlocks.
  var scriptingCallbacks = (Module.scriptingWorkCallbacks = new Map());
  // Requires pre-allocating workers.
  var workers = PThread.unusedWorkers;
  for (var k in workers) {
    workers[k].addEventListener("message", function (event) {
      var data = event.data;
      var workspace = data.scriptingWorkspace;
      if (workspace) {
        var id = data.workId;
        var cb = scriptingCallbacks.get(workspace);
        if (cb) {
          cb(id);
        }
      }
    });
  }
};
