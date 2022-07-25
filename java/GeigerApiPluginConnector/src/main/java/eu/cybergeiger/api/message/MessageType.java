package eu.cybergeiger.api.message;

/**
 * <p>The type of message transferred.</p>
 */
public enum MessageType {

  /* Events related to plugin registration */
  REGISTER_PLUGIN(100),
  DEREGISTER_PLUGIN(130),

  /* Activate plugin events */
  ACTIVATE_PLUGIN(150),
  DEACTIVATE_PLUGIN(151),

  /* Events related to menu items */
  REGISTER_MENU(210),       // Register a new menu entry
  MENU_PRESSED(220),        // Menu item selected by user
  ENABLE_MENU(221),         // Menu entry is active (a user may select it)
  DISABLE_MENU(222),       // Menu entry is inactive (a user may not select it)
  DEREGISTER_MENU(230),     // der-register a registered menu entry

  /* Messages related to out of bound messages */
  SCAN_PRESSED(310),        // Scan Button is pressed
  SCAN_COMPLETED(320),      // Scan has been finished by the plugin

  /* Messages related to the visual stack control */
  RETURNING_CONTROL(410),

  CUSTOM_EVENT(999),

  /* internal messages to the API */

  ALL_EVENTS(1000),

  /* internal keep alive messages */
  PING(10001),
  PONG(10001),

  /* Messages related to the storage */
  STORAGE_EVENT(20000),
  STORAGE_SUCCESS(20100),
  STORAGE_ERROR(20400),

  /* response messages*/

  COMAPI_SUCCESS(30100),
  COMAPI_ERROR(30400);

  private final int id;

  MessageType(int id) {
    this.id = id;
  }

  public int getId() {
    return this.id;
  }

  /**
   * Get enumeration element by its ASN.1 ID.
   *
   * @param id the ID of the element to be obtained
   * @return the element or null if the ID is unknown
   */
  public static MessageType getById(int id) {
    for (MessageType e : values()) {
      if (e.id == id)
        return e;
    }
    return null;
  }

  /**
   * Does not include ALL_EVENTS
   */
  public static MessageType[] getAllTypes() {
    return new MessageType[]{
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
      RETURNING_CONTROL,
      CUSTOM_EVENT,
      PING,
      PONG,
      STORAGE_EVENT,
      STORAGE_SUCCESS,
      STORAGE_ERROR,
      COMAPI_SUCCESS,
      COMAPI_ERROR,
    };
  }
}