package eu.cybergeiger.storage;

/**
 * <p>Represents the type of event for a storage event.</p>
 */
public enum ChangeType {
  CREATE,
  UPDATE,
  DELETE,
  RENAME;

  public static Visibility valueOfStandard(String name) {
    return Visibility.valueOf(name.toUpperCase());
  }

  public String toStringStandard() {
    return super.toString().toLowerCase();
  }
}
