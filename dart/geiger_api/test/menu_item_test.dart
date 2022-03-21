import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:test/test.dart';

import 'print_logger.dart';

void main() async {
  printLogger();

  String menuName = 'testMenu';
  GeigerUrl url = GeigerUrl(null, GeigerApi.masterId, 'testMenu');
  final MenuItem menu = MenuItem(
      await NodeImpl.fromPath(':menu:1111-1111-111111-111113:testMenu', 'pid',
          nodeValues: [NodeValueImpl('name', 'testMenu')]),
      url,
      true);

  group('testConstructorGetterSetter', () {
    group('MenuItem default', () {
      test('Checking menu Item', () async {
        expect(menuName, await menu.name());
      });
      test('Checking stored GeigerUrl', () {
        expect(url, menu.action);
      });
      test('Is Menu enabled', () {
        expect(menu.enabled, true);
      });
    });

    group('MenuItem Enabled', () {
      test('Checking menu Item', () async {
        expect(menuName, await menu.name());
      });
      test('Checking stored GeigerUrl', () {
        expect(url, menu.action);
      });
      test('Is Menu enabled', () {
        expect(menu.enabled, true);
      });
    });

    group('MenuItem Disabled', () {
      test('Checking menu Item', () async {
        MenuItem menu2 = await menu.clone();
        menu2.enabled = false;
        expect(await menu.name(), await menu2.name());
      });
      test('Checking stored GeigerUrl', () async {
        MenuItem menu2 = await menu.clone();
        menu2.enabled = false;
        expect(url, menu.action);
      });
      test('Is Menu enabled', () async {
        MenuItem menu2 = await menu.clone();
        menu2.enabled = false;
        expect(menu2.enabled, false);
      });
      test('Is Menu enabled after set True', () async {
        MenuItem menu2 = await menu.clone();
        menu2.enabled = false;
        menu2.enabled = true;
        expect(menu2.enabled, isTrue,
            reason: 'Menu is not enabled as expected');
      });
      test('Is Menu disabled after set False', () async {
        MenuItem menu2 = await menu.clone();
        menu2.enabled = false;
        menu2.enabled = true;
        menu2.enabled = false;
        expect(menu2.enabled, false);
      });
    });
  });

  group('testToString', () {
    test('checking toString', () async {
      String expectedValue =
          '"${menu.menu.path}"->' + url.toString() + '(enabled)';
      expect(menu.toString(), expectedValue);
    });

    test('checking toString', () async {
      MenuItem menu2 = await menu.clone();
      menu2.enabled = false;
      String expectedValue =
          '"${menu.menu.path}"->' + url.toString() + '(disabled)';
      expect(menu2.toString(), expectedValue);
    });
  });

  group('testEquals', () {
    test('1: true, 2: false', () async {
      MenuItem menu2 = await menu.clone();
      MenuItem menu3 = await menu.clone();
      menu3.enabled = true;
      MenuItem menu4 = await menu.clone();
      menu4.enabled = false;
      expect(menu, menu2, reason: 'MenuItem with identical constructor failed');
      expect(menu, menu3,
          reason: 'MenuItem with default value constructor failed');
      expect(menu.equals(menu4), isFalse,
          reason: 'MenuItem with different constructor failed');
      menu2.enabled = false;
      expect(menu2, menu4,
          reason: 'MenuItem with other constructor (enabling) failed');
    });
  });

  group('testHashCode', () {
    test('test equality of MenuItem hashcodes', () async {
      MenuItem menu2 = await menu.clone();
      expect(menu.hashCode, menu2.hashCode);
    });
    test('Test inequality of HashCode when having a different equality level',
        () async {
      MenuItem menu3 = await menu.clone();
      menu3.enabled = true;
      MenuItem menu4 = await menu.clone();
      menu4.enabled = false;
      expect(menu3.hashCode != menu4.hashCode, isTrue);
      menu3.enabled = false;
      expect(menu3.hashCode, menu4.hashCode);
    });
  });
}
