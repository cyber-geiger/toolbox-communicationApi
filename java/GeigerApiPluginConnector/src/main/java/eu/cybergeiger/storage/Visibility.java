package eu.cybergeiger.storage;

/**
 * <p>Defines the constants used in the traffic light protocol (TLP).</p>
 *
 * <p>Each constants is a visibility option that needs to be set on a storage object.</p>
 */
public enum Visibility {
  /**
   * <p>for all private values not to be shared with anyone except the devices
   * assigned with the same user/enterprise.</p>
   */
  RED,
  /**
   * <p>for all values to be shared with a specific party (e.g., CERT) only.</p>
   */
  AMBER,
  /**
   * <p>for all values to be shared with the cloud for analysis an consolidation.</p>
   */
  GREEN,
  /**
   * <p>for all values to be shared with all entities of the cloud.</p>
   */
  WHITE;

  public static Visibility valueOfStandard(String name) {
    return Visibility.valueOf(name.toUpperCase());
  }

  public String toStringStandard() {
    return super.toString().toLowerCase();
  }
}
