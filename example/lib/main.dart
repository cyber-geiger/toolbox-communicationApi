// ignore_for_file: avoid_print

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

void main() async {
  GeigerApi? api = await getGeigerApi('<unspecified>', 'myPluginIdentifier');
  StorageController? controller = api!.getStorage();
  print(
      'Current user: ${(await controller!.getValue(':Local', 'currentUser'))!.toSimpleString()}');
}
