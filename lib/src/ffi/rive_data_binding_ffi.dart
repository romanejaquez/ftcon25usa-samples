import 'dart:ffi';

import 'package:ffi/ffi.dart';

final class ViewModelPropertyDataFFI extends Struct {
  @Int32()
  external int type;

  external Pointer<Utf8> name;
}

final class ViewModelPropertyDataArray extends Struct {
  external Pointer<ViewModelPropertyDataFFI> data;

  @Int32()
  external int length;
}

final class DataEnumFFI extends Struct {
  external Pointer<Utf8> name;

  external Pointer<Pointer<Utf8>> values;

  @Int32()
  external int length;
}

final class DataEnumArray extends Struct {
  external Pointer<DataEnumFFI> data;

  @Int32()
  external int length;
}
