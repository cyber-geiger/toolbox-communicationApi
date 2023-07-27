import 'package:logging/logging.dart';

void printLogger() {
  Logger.root.onRecord.listen((record) {
    print('${record.time} ${record.level.name}: ${record.message}');
  });
}
