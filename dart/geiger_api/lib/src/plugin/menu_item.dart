library geiger_api;

import 'package:geiger_localstorage/geiger_localstorage.dart';

import '../message/geiger_url.dart';

/// Represents a menu item for a list of items.
class MenuItem implements Serializer {
  static const int serialVersionUID = 481231212;
  final Node _menu;
  final GeigerUrl _action;
  bool enabled;

  /// Creates a new [MenuItem] for [_menu] and assigns an [_action] URL.
  ///
  /// Whether the menu item is [enabled] or not can also be specified.
  MenuItem(this._menu, this._action, [this.enabled = true]);

  /// Returns the menu node.
  Node get menu {
    return _menu;
  }

  /// Fetches the name entry of the menu in the specified language
  Future<String> name({String? languageRange}) async {
    languageRange ??= NodeValueImpl.defaultLocale.toLanguageTag();
    NodeValue? nv = await _menu.getValue('name');
    if (nv == null) {
      throw StorageException(
          'a menu node should always have a menu name but ${_menu.path} has an empty "name" key');
    }
    return nv.getValue(languageRange) ?? '';
  }

  /// Fetches the tooltip entry of the menu in the specified language
  Future<String?> tooltip({String? languageRange}) async {
    languageRange ??= NodeValueImpl.defaultLocale.toLanguageTag();
    NodeValue? nv = await _menu.getValue('tooltip');
    if (nv == null) {
      return null;
    }
    return nv.getValue(languageRange);
  }

  /// Returns the action URL.
  GeigerUrl get action {
    return _action;
  }

  @override
  void toByteArrayStream(ByteSink out) {
    SerializerHelper.writeLong(out, serialVersionUID);
    _menu.toByteArrayStream(out);
    _action.toByteArrayStream(out);
    SerializerHelper.writeInt(out, enabled ? 1 : 0);
    SerializerHelper.writeLong(out, serialVersionUID);
  }

  /// Reads objects from ByteArrayInputStream and stores them in map.
  /// @param in ByteArrayInputStream to be used
  /// @return the deserialized Storable String
  /// @throws IOException if value cannot be read
  static Future<MenuItem> fromByteArrayStream(ByteStream in_) async {
    SerializerHelper.castTest(
        'MenuItem', serialVersionUID, await SerializerHelper.readLong(in_), 1);
    final Node menu = await NodeImpl.fromByteArrayStream(in_);
    final GeigerUrl url = await GeigerUrl.fromByteArrayStream(in_);
    final bool mEnabled = await SerializerHelper.readInt(in_) == 1;
    SerializerHelper.castTest(
        'MenuItem', serialVersionUID, await SerializerHelper.readLong(in_), 2);
    return MenuItem(menu, url, mEnabled);
  }

  @override
  String toString() {
    return '"${_menu.path}"->$_action(${enabled ? 'enabled' : 'disabled'})';
  }

  @override
  bool operator ==(Object other) => equals(other);

  bool equals(Object? o) {
    if (identical(this, o)) {
      return true;
    }
    if (o == null || o is! MenuItem) {
      return false;
    }
    MenuItem menuItem = o;
    return enabled == menuItem.enabled &&
        _menu == menuItem._menu &&
        _action == menuItem._action;
  }

  @override
  int get hashCode {
    return (_menu.hashCode.toString() +
            _action.hashCode.toString() +
            enabled.toString())
        .hashCode;
  }

  /// Wrapper function to simplify serialization.
  /// @return the serializer object as byte array
  Future<List<int>> toByteArray() async {
    ByteSink out = ByteSink();
    toByteArrayStream(out);
    out.close();
    return out.bytes;
  }

  /// Wrapper function to simplify deserialization.
  /// @param buf the buffer to be read
  /// @return the deserialized object
  static Future<MenuItem> fromByteArray(List<int> buf) {
    ByteStream in_ = ByteStream(null, buf);
    return fromByteArrayStream(in_);
  }

  /// creates a clone of the MenuItem.
  Future<MenuItem> clone() async {
    List<int> arr = await toByteArray();
    return await fromByteArray(arr);
  }
}
