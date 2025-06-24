import 'dart:ffi';

import 'package:ffi/ffi.dart';

final class ReportedEventStruct extends Struct {
  external Pointer<Void> event;

  @Float()
  external double secondsDelay;

  @Uint16()
  external int type;
}

final class CustomPropertyStruct extends Struct {
  external Pointer<Void> property;

  external Pointer<Utf8> name;

  @Uint16()
  external int type;
}
