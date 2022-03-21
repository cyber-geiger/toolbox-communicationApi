import 'package:logging/logging.dart';

void printLogger() {
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.time} ${record.level.name}: ${record.message}');
  });
}
