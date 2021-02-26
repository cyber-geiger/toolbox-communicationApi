package eu.cybergeiger.communication;

public enum MessageType {

  /* Events related to plugin registration */
  REGISTER_PLUGIN(100),
  DEREGISTER_PLUGIN(110),

  /* Events related to menu items */
  REGISTER_MENU(210),
  MENU_PRESSED(220),
  DEREGISTER_MENU(230),

  /* Messages related to out of bound messages */
  SCAN_PRESSED(310),

  /* Messages related to the visual stack control */
  RETURNING_CONTROL(410),

  /* internal messages to the API */

  STORAGE_EVENT(1010),

  PING(10000),

  PONG(10001);

  private int id;

  MessageType(int id) {
    this.id = id;
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