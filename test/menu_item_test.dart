import 'package:geiger_api/src/communication/geiger_url.dart';
import 'package:geiger_api/src/communication/menu_item.dart';
import 'package:test/test.dart';

void main() {
  String menuName = 'testMenu';
  GeigerUrl url = GeigerUrl(null, 'geigerAPI.master', 'geiger://plugin/path');

  group('testConstructorGetterSetter', () {
    group('MenuItem default', () {
      MenuItem menu = MenuItem(menuName, url);
      test('Checking menu Item', () {
        expect(menuName, menu.menu);
      });
      test('Checking stored GeigerUrl', () {
        expect(url, menu.action);
      });
      test('Is Menu enabled', () {
        expect(menu.enabled, true);
      });
    });

    group('MenuItem Enabled', () {
      MenuItem menu = MenuItem(menuName, url, true);
      test('Checking menu Item', () {
        expect(menuName, menu.menu);
      });
      test('Checking stored GeigerUrl', () {
        expect(url, menu.action);
      });
      test('Is Menu enabled', () {
        expect(menu.enabled, true);
      });
    });

    group('MenuItem Disabled', () {
      MenuItem menu = MenuItem(menuName, url, false);
      test('Checking menu Item', () {
        expect(menuName, menu.menu);
      });
      test('Checking stored GeigerUrl', () {
        expect(url, menu.action);
      });
      test('Is Menu enabled', () {
        expect(menu.enabled, false);
      });
      test('Is Menu enabled after set True', () {
        menu.enabled = true;
        expect(menu.enabled, isTrue, reason:'Menu is not enabled as expected');
      });
      test('Is Menu disabled after set False', () {
        menu.enabled = false;
        expect(menu.enabled, false);
      });
    });
  });

  group('testToString', () {
    test('checking toString', () {
      MenuItem menu = MenuItem(menuName, url);
      String expectedValue = '"testMenu"->' + url.toString() + '(enabled)';
      expect(menu.toString(), expectedValue);
    });

    test('checking toString', () {
      MenuItem menu = MenuItem(menuName, url, true);
      String expectedValue = '"testMenu"->' + url.toString() + '(enabled)';
      expect(menu.toString(), expectedValue);
    });

    test('checking toString', () {
      MenuItem menu = MenuItem(menuName, url, false);
      String expectedValue = '"testMenu"->' + url.toString() + '(disabled)';
      expect(menu.toString(), expectedValue);
    });
  });

  group('testEquals', () {
    MenuItem menu = MenuItem(menuName, url);
    MenuItem menu2 = MenuItem(menuName, url);
    MenuItem menu3 = MenuItem(menuName, url, true);
    MenuItem menu4 = MenuItem(menuName, url, false);
    test('1: true, 2: false', () {
      expect(menu, menu2, reason: 'MenuItem with identical constructor failed');
      expect(menu, menu3, reason: 'MenuItem with default value constructor failed');
      expect(menu.equals(menu4), isFalse,
          reason: 'MenuItem with different constructor failed');
      menu2.enabled = false;
      expect(menu2, menu4,
          reason: 'MenuItem with other constructor (enabling) failed');
    });
  });

  group('testHashCode', () {
    MenuItem menu = MenuItem(menuName, url);
    MenuItem menu2 = MenuItem(menuName, url);
    test('test equality of MenuItem hashcodes', () {
      expect(menu.hashCode, menu2.hashCode);
    });
    MenuItem menu3 = MenuItem(menuName, url, true);
    MenuItem menu4 = MenuItem(menuName, url, false);
    test('Test inequality of HashCode when having a different equality level', () {
      expect(menu3.hashCode!=menu4.hashCode,isTrue);
      menu3.enabled = false;
      expect(menu3.hashCode, menu4.hashCode);
    });
  });
}
