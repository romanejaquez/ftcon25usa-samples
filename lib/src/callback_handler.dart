import 'dart:ui';

abstract class CallbackHandler {
  const CallbackHandler();
  void dispose();
}

class EmptyCallbackHandler extends CallbackHandler {
  const EmptyCallbackHandler();
  @override
  void dispose() {}
}

class ClosureCallbackHandler extends CallbackHandler {
  VoidCallback? callback;
  ClosureCallbackHandler(this.callback);

  @override
  void dispose() {
    callback?.call();
    callback = null;
  }
}
