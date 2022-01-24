/// The type of message transferred.
class MessageType {
  // TODO(mgwerder): replace with introspection
  static final List<MessageType> _values = <MessageType>[
    registerPlugin,
    deregisterPlugin,
    activatePlugin,
    deactivatePlugin,
    registerMenu,
    menuPressed,
    enableMenu,
    disableMenu,
    deregisterMenu,
    scanPressed,
    scanCompleted,
    registerMenu,
    returningControl,
    allEvents,
    ping,
    pong,
    storageEvent,
    storageSuccess,
    storageError,
    comapiSuccess,
    comapiError
  ];

  final String _value;
  final int _num;

  /* Events related to plugin registration */
  static const registerPlugin = MessageType._('REGISTER_PLUGIN', 100);
  static const deregisterPlugin = MessageType._('DEREGISTER_PLUGIN', 130);

  /* Activate plugin events */
  static const activatePlugin = MessageType._('ACTIVATE_PLUGIN', 150);
  static const deactivatePlugin = MessageType._('DEACTIVATE_PLUGIN', 151);

  /* Events related to menu items */
  static const registerMenu =
      MessageType._('REGISTER_MENU', 210); // Register a new menu entry
  static const menuPressed =
      MessageType._('MENU_PRESSED', 220); // Menu item selected by user
  static const enableMenu = MessageType._(
      'ENABLE_MENU', 221); // Menu entry is active (a user may select it)
  static const disableMenu = MessageType._(
      'DISABLE_MENU', 222); // Menu entry is inactive (a user may not select it)
  static const deregisterMenu = MessageType._(
      'DEREGISTER_MENU', 230); // der-register a registered menu entry

  /* Messages related to out of bound messages */
  static const scanPressed =
      MessageType._('SCAN_PRESSED', 310); // Scan Button is pressed
  static const scanCompleted = MessageType._(
      'SCAN_COMPLETED', 320); // Scan has been finished by the plugin

  /* Messages related to the visual stack control */
  static const returningControl = MessageType._('RETURNING_CONTROL', 410);

  /* Messages related to listeners*/
  static const registerListener = MessageType._('REGISTER_LISTENER', 500);
  static const deregisterListener = MessageType._('DEREGISTER_LISTENER', 530);

  /* internal messages to the API */
  static const allEvents = MessageType._('ALL_EVENTS', 1000);

  /* internal keep alive messages */
  static const ping = MessageType._('PING', 10001);
  static const pong = MessageType._('PONG', 10002);

  /* Messages related to the storage */
  static const storageEvent = MessageType._('STORAGE_EVENT', 20000);
  static const storageSuccess = MessageType._('STORAGE_SUCESS', 20100);
  static const storageError = MessageType._('STORAGE_ERROR', 20400);

  /* response messages*/
  static const comapiSuccess = MessageType._('COMAPI_SUCCESS', 30100);
  static const comapiError = MessageType._('COMAPI_ERROR', 30400);

  const MessageType._(final this._value, final this._num);

  @override
  toString() => _value;

  int get id {
    return _num;
  }

  /// Get [MessageType] by its ASN.1 ID.
  ///
  /// Will return `null` if not found.
  static MessageType? getById(int id) {
    for (MessageType mt in _values) {
      if (mt.id == id) {
        return mt;
      }
    }
    return null;
  }

  static List<MessageType> getAllValues() {
    List<MessageType> ret = <MessageType>[];
    for (MessageType mt in _values) {
      if (mt.id < 1000) {
        ret.add(mt);
      }
    }
    return ret;
  }
}
