package eu.cybergeiger.communication;

public enum MessageType {

  /* Events related to plugin registration */
  REGISTER_PLUGIN(100),
  DEREGISTER_PLUGIN(110),

  /* Activate plugin events */
  ACTIVATE_PLUGIN(150),
  DEACTIVATE_PLUGIN(151),

  /* Events related to menu items */
  REGISTER_MENU(210),       // Register a new menu entry
  MENU_PRESSED(220),        // Menu item selected by user
  MENU_ACTIVE(221),         // Menu entry is active (a user may select it)
  MENU_INACTIVE(222),       // Menu entry is inactive (a user may not select
  DEREGISTER_MENU(230),     //

  /* Messages related to out of bound messages */
  SCAN_PRESSED(310),
  SCAN_COMPLETED(320),

  /* Messages related to the visual stack control */
  RETURNING_CONTROL(410),

  /* internal messages to the API */

  ALL_EVENTS(1000),

  /* internal keep alive messages */
  PING(10000),
  PONG(10001),

  STORAGE_EVENT(20000);

  private int id;

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
      if (e.id == id) {
        return e;
      }
    }
    return null;
  }


}