package eu.cybergeiger.storage;

/**
 * <p>Represents the type of event for a storage event.</p>
 */
public enum ChangeType {
  CREATE,
  UPDATE,
  DELETE,
  RENAME;

  public static ChangeType valueOfStandard(String name) {
    return ChangeType.valueOf(name.toUpperCase());
  }

  public String toStringStandard() {
    return super.toString().toLowerCase();
  }
}
