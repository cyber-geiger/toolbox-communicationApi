import 'package:communicationapi/src/communication/geiger_url.dart';
import 'package:communicationapi/src/communication/menu_item.dart';
import 'package:test/test.dart';

void main() {
  String menuName = "testMenu";
  GeigerUrl url = GeigerUrl(null, "geigerAPI.master", "geiger://plugin/path");

  group('testConstructorGetterSetter', () {
    group('MenuItem default', () {
      MenuItem menu = MenuItem(menuName, url);
      test("Checking menu Item", () {
        expect(menuName, menu.menu);
      });
      test("Checking stored GeigerUrl", () {
        expect(url, menu.action);
      });
      test("Is Menu enabled", () {
        expect(menu.enabled, true);
      });
    });

    group("MenuItem Enabled", () {
      MenuItem menu = MenuItem(menuName, url, true);
      test("Checking menu Item", () {
        expect(menuName, menu.menu);
      });
      test("Checking stored GeigerUrl", () {
        expect(url, menu.action);
      });
      test("Is Menu enabled", () {
        expect(menu.enabled, true);
      });
    });

    group("MenuItem Disabled", () {
      MenuItem menu = MenuItem(menuName, url, false);
      test("Checking menu Item", () {
        expect(menuName, menu.menu);
      });
      test("Checking stored GeigerUrl", () {
        expect(url, menu.action);
      });
      test("Is Menu enabled", () {
        expect(menu.enabled, false);
      });
      menu.enabled = true;
      test("Is Menu enabled after set True", () {
        expect(menu.enabled, true);
      });
      menu.enabled = false;
      test("Is Menu enabled after set False", () {
        expect(menu.enabled, false);
      });
    });
  });

  group("testToString", () {
    test("checking toString", () {
      MenuItem menu = MenuItem(menuName, url);
      String expectedValue = "\"testMenu\"->" + url.toString() + "(enabled)";
      expect(menu.toString(), expectedValue);
    });

    test("checking toString", () {
      MenuItem menu = MenuItem(menuName, url, true);
      String expectedValue = "\"testMenu\"->" + url.toString() + "(enabled)";
      expect(menu.toString(), expectedValue);
    });

    test("checking toString", () {
      MenuItem menu = MenuItem(menuName, url, false);
      String expectedValue = "\"testMenu\"->" + url.toString() + "(disabled)";
      expect(menu.toString(), expectedValue);
    });
  });

  group("testEquals", () {
    MenuItem menu = new MenuItem(menuName, url);
    MenuItem menu2 = new MenuItem(menuName, url);
    MenuItem menu3 = new MenuItem(menuName, url, true);
    MenuItem menu4 = new MenuItem(menuName, url, false);
    test("1: true, 2: false", () {
      expect(menu, menu2);
      expect(menu, menu3);
      expect(menu, menu4);
      menu2.enabled = false;
      expect(menu2, menu4);
    });
  });

  group("testHashCode", () {
    MenuItem menu = new MenuItem(menuName, url);
    MenuItem menu2 = new MenuItem(menuName, url);
    test("", () {
      expect(menu.hashCode, menu2.hashCode);
    });
    MenuItem menu3 = new MenuItem(menuName, url, true);
    MenuItem menu4 = new MenuItem(menuName, url, false);
    test("", () {
      expect(menu3.hashCode, menu4.hashCode);
      menu3.enabled = false;
      expect(menu3.hashCode, menu4.hashCode);
    });
  });
}
