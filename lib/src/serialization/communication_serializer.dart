library geiger_api;

import 'package:geiger_api/src/communication/geiger_url.dart';
import 'package:geiger_api/src/communication/menu_item.dart';
import 'package:geiger_api/src/communication/parameter_list.dart';
import 'package:geiger_api/src/communication/plugin_information.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

import '../../geiger_api.dart';

/// Read an object from ByteArrayInputStream.
/// @param in the byteArrayInputStream to use
/// @return return the object read
/// @throws IOException if object cannot be read
Future<Serializer?> readObject(final ByteStream inStream) async {
  if (SerializerHelper.byteArrayToInt(
          await inStream.peekBytes(SerializerHelper.longSize)) ==
      StorableString.serialVersionUID) {
    return StorableString.fromByteArrayStream(inStream);
  } else if (SerializerHelper.byteArrayToInt(
          await inStream.peekBytes(SerializerHelper.longSize)) ==
      StorableHashMap.serialVersionUID) {
    return StorableHashMap.fromByteArrayStream(inStream, StorableHashMap());
  } else if (SerializerHelper.byteArrayToInt(
          await inStream.peekBytes(SerializerHelper.longSize)) ==
      PluginInformation.serialVersionUID) {
    return PluginInformation.fromByteArrayStream(inStream);
  } else if (SerializerHelper.byteArrayToInt(
          await inStream.peekBytes(SerializerHelper.longSize)) ==
      ParameterList.serialVersionUID) {
    return ParameterList.fromByteArrayStream(inStream);
  } else if (SerializerHelper.byteArrayToInt(
          await inStream.peekBytes(SerializerHelper.longSize)) ==
      MenuItem.serialVersionUID) {
    return MenuItem.fromByteArrayStream(inStream);
  } else if (SerializerHelper.byteArrayToInt(
          await inStream.peekBytes(SerializerHelper.longSize)) ==
      GeigerUrl.serialVersionUID) {
    return GeigerUrl.fromByteArrayStream(inStream);
  } else {
    return null;
  }
}

/// Write an object to ByteArrayOutputStream.
/// @param out the ByteArrayOutputStream to use
/// @param o the Object to write
/// @throws IOException if object cannot be written
void writeObject(ByteSink out, Serializer o) {
  o.toByteArrayStream(out);
}
