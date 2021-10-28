library geiger_api;

import 'package:geiger_localstorage/geiger_localstorage.dart';

/// Read an object from ByteArrayInputStream.
/// @param in the byteArrayInputStream to use
/// @return return the object read
/// @throws IOException if object cannot be read
Future <Serializer> readObject(ByteStream in_) async {
  throw Exception('not implemented');
}

/// Write an object to ByteArrayOutputStream.
/// @param out the ByteArrayOutputStream to use
/// @param o the Object to write
/// @throws IOException if object cannot be written
void writeObject(ByteSink out, Serializer o) {
  throw Exception('not implemented');
}
