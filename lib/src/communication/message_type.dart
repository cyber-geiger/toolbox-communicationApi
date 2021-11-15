/// The type of message transferred.
class MessageType {

  // TODO(mgwerder): replace with introspection
  static final List<MessageType> _values = <MessageType>[
    REGISTER_PLUGIN,
    DEREGISTER_PLUGIN,
    ACTIVATE_PLUGIN,
    DEACTIVATE_PLUGIN,
    REGISTER_MENU,
    MENU_PRESSED,
    ENABLE_MENU,
    DISABLE_MENU,
    DEREGISTER_MENU,
    SCAN_PRESSED,
    SCAN_COMPLETED,
    REGISTER_MENU,
    DEREGISTER_MENU,
    ALL_EVENTS,
    PING,
    PONG,
    STORAGE_EVENT,
    STORAGE_SUCCESS,
    STORAGE_ERROR,
    COMAPI_SUCCESS,
    COMAPI_ERROR
  ];

  final String _value;
  final int _num;

  /* Events related to plugin registration */
  static const REGISTER_PLUGIN = MessageType._('REGISTER_PLUGIN',100);
  static const DEREGISTER_PLUGIN = MessageType._('DEREGISTER_PLUGIN',130);

  /* Activate plugin events */
  static const ACTIVATE_PLUGIN = MessageType._('ACTIVATE_PLUGIN',150);
  static const DEACTIVATE_PLUGIN = MessageType._('DEACTIVATE_PLUGIN',151);

  /* Events related to menu items */
  static const REGISTER_MENU =
      MessageType._('REGISTER_MENU',210); // Register a new menu entry
  static const MENU_PRESSED = MessageType._('MENU_PRESSED',220); // Menu item selected by user
  static const ENABLE_MENU = MessageType._('ENABLE_MENU',221); // Menu entry is active (a user may select it)
  static const DISABLE_MENU = MessageType._('DISABLE_MENU',220); // Menu entry is inactive (a user may not select it)
  static const DEREGISTER_MENU = MessageType._(
      'DEREGISTER_MENU',230); // der-register a registered menu entry

  /* Messages related to out of bound messages */
  static const SCAN_PRESSED =
      MessageType._('SCAN_PRESSED',310); // Scan Button is pressed
  static const SCAN_COMPLETED = MessageType._(
      'SCAN_COMPLETED',320); // Scan has been finished by the plugin

  /* Messages related to the visual stack control */
  static const RETURNING_CONTROL = MessageType._('RETURNING_CONTROL',410);

  /* Messages related to listeners*/
  static const REGISTER_LISTENER = MessageType._('REGISTER_LISTENER',500);
  static const DEREGISTER_LISTENER =
      MessageType._('DEREGISTER_LISTENER',530);

  /* internal messages to the API */
  static const ALL_EVENTS = MessageType._('ALL_EVENTS',1000);

  /* internal keep alive messages */
  static const PING = MessageType._('PING',10001);
  static const PONG = MessageType._('PONG',10002);

  /* Messages related to the storage */
  static const STORAGE_EVENT = MessageType._('STORAGE_EVENT',20000);
  static const STORAGE_SUCCESS = MessageType._('STORAGE_SUCESS',20100);
  static const STORAGE_ERROR = MessageType._('STORAGE_ERROR',20400);

  /* response messages*/
  static const COMAPI_SUCCESS = MessageType._('COMAPI_SUCCESS',30100);
  static const COMAPI_ERROR = MessageType._('COMAPI_ERROR',30400);

  const MessageType._(final this._value, final this._num);

  toString() => '$_value';

  int get id {
    return _num;
  }

  /// Get [MessageType] by its ASN.1 ID.
  ///
  /// Will return `null` if not found.
  static MessageType? getById(int id) {
    for(MessageType mt in _values) {
      if(mt.id==id) {
        return mt;
      }
    }
    return null;
  }

  static List<MessageType> getAllValues() {
    List<MessageType> ret = <MessageType>[];
    for(MessageType mt in _values ) {
      if(mt.id<1000) {
        ret.add(mt);
      }
    }
    return ret;
  }

}
