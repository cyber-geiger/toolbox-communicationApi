/// <p>The type of message transferred.</p>
enum MessageType {
  /* Events related to plugin registration */
  REGISTER_PLUGIN,
  DEREGISTER_PLUGIN,

  /* Activate plugin events */
  ACTIVATE_PLUGIN,
  DEACTIVATE_PLUGIN,

  /* Events related to menu items */
  REGISTER_MENU, // Register a new menu entry
  MENU_PRESSED, // Menu item selected by user
  ENABLE_MENU, // Menu entry is active (a user may select it)
  DISABLE_MENU, // Menu entry is inactive (a user may not select it)
  DEREGISTER_MENU, // der-register a registered menu entry

  /* Messages related to out of bound messages */
  SCAN_PRESSED, // Scan Button is pressed
  SCAN_COMPLETED, // Scan has been finished by the plugin

  /* Messages related to the visual stack control */
  RETURNING_CONTROL,

  /* Messages related to listeners*/
  REGISTER_LISTENER,
  DEREGISTER_LISTENER,

  /* internal messages to the API */
  ALL_EVENTS,

  /* internal keep alive messages */
  PING,
  PONG,

  /* Messages related to the storage */
  STORAGE_EVENT,
  STORAGE_SUCCESS,
  STORAGE_ERROR,

  /* response messages*/
  COMAPI_SUCCESS,
  COMAPI_ERROR
}

extension MessageTypeExtension on MessageType {
  int getId() {
    switch (this) {
      case MessageType.REGISTER_PLUGIN:
        return (100);
      case MessageType.DEREGISTER_PLUGIN:
        return (130);
      case MessageType.ACTIVATE_PLUGIN:
        return (150);
      case MessageType.DEACTIVATE_PLUGIN:
        return (151);
      case MessageType.REGISTER_MENU:
        return (210);
      case MessageType.MENU_PRESSED:
        return (220);
      case MessageType.ENABLE_MENU:
        return (221);
      case MessageType.DISABLE_MENU:
        return (222);
      case MessageType.DEREGISTER_MENU:
        return (230);
      case MessageType.SCAN_PRESSED:
        return (310);
      case MessageType.SCAN_COMPLETED:
        return (320);
      case MessageType.RETURNING_CONTROL:
        return (410);
      case MessageType.REGISTER_LISTENER:
        return (500);
      case MessageType.DEREGISTER_LISTENER:
        return (530);
      case MessageType.ALL_EVENTS:
        return (1000);
      case MessageType.PING:
        return (10000);
      case MessageType.PONG:
        return (10001);
      case MessageType.STORAGE_EVENT:
        return (20000);
      case MessageType.STORAGE_SUCCESS:
        return (20100);
      case MessageType.STORAGE_ERROR:
        return (20400);
      case MessageType.COMAPI_SUCCESS:
        return (30000);
      case MessageType.COMAPI_ERROR:
        return (30200);
    }
  }

  /// Get enumeration element by its ASN.1 ID.
  ///
  /// @param id the ID of the element to be obtained
  /// @return the element or null if the ID is unknown
  static MessageType? getById(int id) {
    for (var e in MessageType.values) {
      if (e.getId() == id) {
        return e;
      }
    }
    return null;
  }
}
