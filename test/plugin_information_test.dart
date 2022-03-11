import 'package:geiger_api/src/plugin/communication_secret.dart';
import 'package:geiger_api/src/plugin/plugin_information.dart';
import 'package:test/test.dart';

void main() {
  var ports = [1025, 1700, 8000, 12500, 44555, 65535];
  var executables = [
    'thisApplication.jar',
    './thisAccplication',
    './../path/to/thisApplication',
    'C:/path to/this/application',
    'thisApplication.apk'
  ];
  List<CommunicationSecret> secrets = [
    CommunicationSecret([1, 2, 3]),
    CommunicationSecret([4, 5, 6])
  ];

  group('ConstructorGetter', () {
    for (final int port in ports) {
      for (final String executable in executables) {
        for (CommunicationSecret secret in secrets) {
          group(
              'Testing with port=$port; executable=$executable; secret=$secret',
              () {
            //Constructor without secret
            PluginInformation info =
                PluginInformation('plugin1', executable, port);
            test('checking Executable', () {
              expect(info.getExecutable(), executable);
            });
            test('checking Port', () {
              expect(info.getPort(), port);
            });
            //Constructor with secret
            PluginInformation info2 =
                PluginInformation('plugin1', executable, port, secret);
            test('checking Executable', () {
              expect(info.getExecutable(), executable);
            });
            test('checking Port', () {
              expect(info.getPort(), port);
            });
            test('checking Secret', () {
              expect(info2.getSecret().secret, secret.secret);
            });
          });
        }
      }
    }
  });
  group('Hash Code', () {
    test('checking Hashcode for equality', () {
      for (final int port in ports) {
        for (final String executable in executables) {
          for (final CommunicationSecret secret in secrets) {
            final PluginInformation info =
                PluginInformation('plugin1', executable, port, secret);
            final PluginInformation info2 =
                PluginInformation('plugin1', executable, port, secret);
            expect(info.hashCode, info2.hashCode,
                reason: 'Test failed with secret=$secret;');
          }
        }
      }
    });
  });
}
