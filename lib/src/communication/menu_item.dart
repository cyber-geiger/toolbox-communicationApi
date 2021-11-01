library geiger_api;

import 'package:geiger_localstorage/geiger_localstorage.dart';

import 'geiger_url.dart';

/// Represents a menu item for a list of items.
/// . * FIXME: Menu texts are not internationalizable
class MenuItem implements Serializer {
  static const int serialVersionUID = 481231212;
  final String _menu;
  final GeigerUrl _action;
  bool _enabled;

  /// Creates a new [MenuItem] for [_menu] and assigns an [_action] URL.
  ///
  /// Whether the menu item is [_enabled] or not can also be specified.
  MenuItem(this._menu, this._action, [this._enabled = true]) {
    if ('' == _menu) {
      throw ArgumentError('menu may not be empty');
    }
  }

  /// Returns the menu string.
  String get menu {
    return _menu;
  }

  /// Returns the action URL.
  GeigerUrl get action {
    return _action;
  }

  /// Returns the menu state.
  bool get enabled {
    return _enabled;
  }

  /// Enables or disables the menu entry and returns the previous state.
  set enabled(bool enabled) {
    this._enabled = enabled;
  }

  @override
  void toByteArrayStream(ByteSink out) {
    SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeString(out, _menu);
    _action.toByteArrayStream(out);
    SerializerHelper.writeInt(out, enabled ? 1 : 0);
    SerializerHelper.writeLong(out, serialVersionUID);
  }

  /// Reads objects from ByteArrayInputStream and stores them in map.
  /// @param in ByteArrayInputStream to be used
  /// @return the deserialized Storable String
  /// @throws IOException if value cannot be read
  @override
  static Future<MenuItem> fromByteArrayStream(ByteStream in_) async {
    if (await SerializerHelper.readLong(in_) != serialVersionUID) {
      throw Exception('cannot cast');
    }
    String menu = await SerializerHelper.readString(in_) ?? '';
    GeigerUrl url = await GeigerUrl.fromByteArrayStream(in_);
    bool enabled = SerializerHelper.readInt(in_) == 1;
    if (await SerializerHelper.readLong(in_) != serialVersionUID) {
      throw Exception('cannot cast');
    }
    return new MenuItem(menu, url, enabled);
  }

  @override
  String toString() {
    return '"'.codeUnitAt(0).toString() +
        _menu +
        '\"->' +
        _action.toString() +
        '(' +
        (_enabled ? 'enabled' : 'disabled') +
        ')';
  }

  @override
  bool operator ==(Object other) => equals(other);

  bool equals(Object? o) {
    if (identical(this, o)) {
      return true;
    }
    if (o == null || !(o is MenuItem)) {
      return false;
    }
    var menuItem = o;
    return _enabled == menuItem._enabled &&
        _menu == menuItem._menu &&
        _action == menuItem._action;
  }

  @override
  int get hashCode {
    return (_menu.hashCode.toString() +
            _action.hashCode.toString() +
            _enabled.toString())
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
}
