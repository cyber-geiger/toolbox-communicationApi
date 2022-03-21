import 'package:geiger_api/src/message/geiger_url.dart';
import 'package:geiger_api/src/exceptions/malformed_url_exception.dart';
import 'package:test/test.dart';

import 'print_logger.dart';

const List<String> protocols = <String>[
  'geiger',
  'some-protocol',
  'protocol/subprotocol',
  'protocol°+*ç%&/()=?`èà£!é_:;'
];

const List<String> plugins = <String>[
  'plugin',
  'some-plugin',
  'plugin-?!subplugin',
  'plugin°+*ç%&()=?`èà£!é_:;',
  'plugin?some-plugin+some%path'
];
const List<String?> paths = <String?>[
  'path',
  'some-path',
  'path/subpath',
  'some/path/to/something',
  'path°+*ç%&/()=?`èà£!é_:;',
  'path://somepath/subpath',
  '',
  null
];

void main() {
  printLogger();

  test('specification sonstructor', () {
    try {
      for (final String protocol in protocols) {
        for (final String plugin in plugins) {
          for (String? path in paths) {
            final GeigerUrl url =
                GeigerUrl.fromSpec("$protocol://$plugin/${path ?? 'null'}");
            expect(protocol, url.protocol, reason: 'checking protocol');
            expect(plugin, url.plugin, reason: 'checking plugin');
            // handle special case where path = null
            path ??= '';
            expect(path, url.path, reason: 'checking path');
          }
        }
      }
    } on MalformedUrlException {
      fail('MalformedUrlException was thrown');
    }

    // Negative tests
    // missing colon
    const String protocol = 'geiger';
    const String plugin = 'plugin';
    const String path = 'path';
    expect(() => GeigerUrl.fromSpec('$protocol//$plugin/$path'),
        throwsA(isA<MalformedUrlException>()));
    // missing slash
    expect(() => GeigerUrl.fromSpec('$protocol:/$plugin/$path'),
        throwsA(isA<MalformedUrlException>()));
    // missing protocol
    expect(() => GeigerUrl.fromSpec('://$plugin/$path'),
        throwsA(isA<MalformedUrlException>()));
    // missing plugin + path
    expect(() => GeigerUrl.fromSpec('$protocol://'),
        throwsA(isA<MalformedUrlException>()));
  });

  test('plugin path constructor', () {
    try {
      const String protocol = 'geiger';
      for (final String plugin in plugins) {
        for (String? path in paths) {
          final GeigerUrl url = GeigerUrl(null, plugin, path ?? 'null');
          expect(protocol, url.protocol, reason: 'checking protocol');
          expect(plugin, url.plugin, reason: 'checking plugin');
          // handle special case where path = null
          path ??= '';
          expect(path, url.path, reason: 'checking path');
        }
      }
    } on MalformedUrlException {
      fail('MalformerUrlException was thrown');
    }

    // negative tests
    // empty plugin
    const String path = 'path';
    const String longPath = 'some/path/to/something';
    expect(
        () => GeigerUrl(null, '', path), throwsA(isA<MalformedUrlException>()));
    expect(() => GeigerUrl(null, '', longPath),
        throwsA(isA<MalformedUrlException>()));
  });

  test('protocol plugin path constructor', () {
    try {
      for (final String protocol in protocols) {
        for (final String plugin in plugins) {
          for (String? path in paths) {
            final GeigerUrl url = GeigerUrl(protocol, plugin, path ?? 'null');
            expect(protocol, url.protocol, reason: 'checking protocol');
            expect(plugin, url.plugin, reason: 'checking plugin');
            // handle special case where path = null
            path ??= '';
            expect(path, url.path, reason: 'checking path');
          }
        }
      }
    } on MalformedUrlException {
      fail('MalformerUrlException was thrown');
    }

    // negative tests
    const String protocol = 'geiger';
    const String plugin = 'plugin';
    const String path = 'path';
    // protocol null or empty
    expect(() => GeigerUrl('', plugin, path),
        throwsA(isA<MalformedUrlException>()));
    // plugin null or empty
    expect(() => GeigerUrl(protocol, '', path),
        throwsA(isA<MalformedUrlException>()));
  });

  test('testToString', () {
    try {
      for (final String protocol in protocols) {
        for (final String plugin in plugins) {
          for (String? path in paths) {
            final GeigerUrl url = GeigerUrl(protocol, plugin, path ?? 'null');
            // handle special case where path = null
            path ??= '';
            final String expectedFormat = '$protocol://$plugin/$path';
            expect(expectedFormat, url.toString(), reason: 'checking toString');

            final GeigerUrl url2 = GeigerUrl.fromSpec(expectedFormat);
            expect(expectedFormat, url2.toString(),
                reason: 'checking toString');
          }
        }
      }
      // checking toString of constructor without protocol
      for (final String plugin in plugins) {
        for (String? path in paths) {
          final GeigerUrl url = GeigerUrl(null, plugin, path ?? 'null');
          // handle special case where path = null
          path ??= '';
          final String expectedFormat = 'geiger://$plugin/$path';
          expect(expectedFormat, url.toString(), reason: 'checking toString');
        }
      }
    } on MalformedUrlException {
      fail('MalformerUrlException was thrown');
    }
  });

  test('testEquals', () {
    try {
      for (final String protocol in protocols) {
        for (final String plugin in plugins) {
          for (String? path in paths) {
            final GeigerUrl url = GeigerUrl(protocol, plugin, path ?? 'null');
            // handle special case where path = null
            path ??= '';
            final String expectedFormat = '$protocol://$plugin/$path';
            final GeigerUrl url2 = GeigerUrl.fromSpec(expectedFormat);
            expect(url, url2);
          }
        }
      }
      // checking equals with fixed protocol
      for (final String plugin in plugins) {
        for (String? path in paths) {
          final GeigerUrl url = GeigerUrl(null, plugin, path ?? 'null');
          // handle special case where path = null
          path ??= '';
          final String expectedFormat = 'geiger://$plugin/$path';
          final GeigerUrl url2 = GeigerUrl.fromSpec(expectedFormat);
          expect(url, url2);
        }
      }
      // Negative tests
      // varying protocol
      final GeigerUrl url = GeigerUrl.fromSpec('geiger://plugin/path');
      final GeigerUrl url2 = GeigerUrl.fromSpec('gei-ger://plugin/path');
      expect(url, isNot(equals(url2)));
      // varying plugin
      final GeigerUrl url3 = GeigerUrl.fromSpec('geiger://plugin/path');
      final GeigerUrl url4 = GeigerUrl.fromSpec('geiger://plug-in/path');
      expect(url3, isNot(equals(url4)));
      // varying path
      final GeigerUrl url5 = GeigerUrl.fromSpec('geiger://plugin/path');
      final GeigerUrl url6 =
          GeigerUrl.fromSpec('geiger://plugin/path/something/else');
      expect(url5, isNot(equals(url6)));
    } on MalformedUrlException {
      fail('MalformerUrlException was thrown');
    }
  });

  test('testHashCode', () {
    try {
      for (final String protocol in protocols) {
        for (final String plugin in plugins) {
          for (String? path in paths) {
            final GeigerUrl url = GeigerUrl(protocol, plugin, path ?? 'null');
            // handle special case where path = null
            path ??= '';
            final String expectedFormat = '$protocol://$plugin/$path';
            final GeigerUrl url2 = GeigerUrl.fromSpec(expectedFormat);
            expect(url.hashCode, url2.hashCode);
          }
        }
      }
      // checking equals with fixed protocol
      for (final String plugin in plugins) {
        for (String? path in paths) {
          final GeigerUrl url = GeigerUrl(null, plugin, path ?? 'null');
          // handle special case where path = null
          path ??= '';
          final String expectedFormat = 'geiger://$plugin/$path';
          final GeigerUrl url2 = GeigerUrl.fromSpec(expectedFormat);
          expect(url.hashCode, url2.hashCode);
        }
      }
      // Negative tests
      // varying protocol
      final GeigerUrl url = GeigerUrl.fromSpec('geiger://plugin/path');
      final GeigerUrl url2 = GeigerUrl.fromSpec('gei-ger://plugin/path');
      expect(url.hashCode, isNot(equals(url2.hashCode)));
      // varying plugin
      final GeigerUrl url3 = GeigerUrl.fromSpec('geiger://plugin/path');
      final GeigerUrl url4 = GeigerUrl.fromSpec('geiger://plug-in/path');
      expect(url3.hashCode, isNot(equals(url4.hashCode)));
      // varying path
      final GeigerUrl url5 = GeigerUrl.fromSpec('geiger://plugin/path');
      final GeigerUrl url6 =
          GeigerUrl.fromSpec('geiger://plugin/path/something/else');
      expect(url5.hashCode, isNot(equals(url6.hashCode)));
    } on MalformedUrlException {
      fail('MalformerUrlException was thrown');
    }
  });
}
