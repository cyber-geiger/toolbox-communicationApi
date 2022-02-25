library geiger_api;

import 'package:geiger_api/src/communication/parameter_list.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

import '../../geiger_api.dart';

/// Read an object from ByteArrayInputStream.
/// @param in the byteArrayInputStream to use
/// @return return the object read
/// @throws IOException if object cannot be read
Future<Serializer> readObject(final ByteStream inStream) async {
  final uidBytes = await inStream.peekBytes(SerializerHelper.longSize * 2);
  final uid = SerializerHelper.byteArrayToInt(
      // trim of long uid bytes
      uidBytes.sublist(SerializerHelper.longSize),
      SerializerHelper.longSize);
  switch (uid) {
    case StorableString.serialVersionUID:
      return StorableString.fromByteArrayStream(inStream);
    case StorableHashMap.serialVersionUID:
      return StorableHashMap.fromByteArrayStream(inStream, StorableHashMap());
    case PluginInformation.serialVersionUID:
      return PluginInformation.fromByteArrayStream(inStream);
    case ParameterList.serialVersionUID:
      return ParameterList.fromByteArrayStream(inStream);
    case MenuItem.serialVersionUID:
      return MenuItem.fromByteArrayStream(inStream);
    case GeigerUrl.serialVersionUID:
      return GeigerUrl.fromByteArrayStream(inStream);
    default:
      throw StorageException('unable to parse $uid');
  }
}

/// Write an object to ByteArrayOutputStream.
/// @param out the ByteArrayOutputStream to use
/// @param o the Object to write
/// @throws IOException if object cannot be written
void writeObject(ByteSink out, Serializer o) {
  o.toByteArrayStream(out);
}
