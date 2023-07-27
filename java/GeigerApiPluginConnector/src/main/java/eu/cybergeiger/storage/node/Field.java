package eu.cybergeiger.storage.node;

import eu.cybergeiger.storage.SearchCriteria;

/**
 * <p>Field reflects the available ordinals in a node.</p>
 */
public enum Field {
  OWNER(1, "owner", SearchCriteria.ComparatorType.STRING),
  NAME(2, "name", SearchCriteria.ComparatorType.STRING),
  PATH(3, "path", SearchCriteria.ComparatorType.STRING),
  KEY(4, "key", SearchCriteria.ComparatorType.STRING),
  VALUE(5, "value", SearchCriteria.ComparatorType.STRING),
  TYPE(6, "type", SearchCriteria.ComparatorType.STRING),
  VISIBILITY(7, "visibility", SearchCriteria.ComparatorType.STRING),
  // Missing underscore to be consistent with Dart version
  LASTMODIFIED(8, "lastModified", SearchCriteria.ComparatorType.DATETIME),
  EXPIRY(9, "expiry", SearchCriteria.ComparatorType.DATETIME),
  TOMBSTONE(10, "tombstone", SearchCriteria.ComparatorType.BOOLEAN);

  private final int id;
  private final String standardName;
  private final SearchCriteria.ComparatorType comparator;

  Field(int id, String standardName, SearchCriteria.ComparatorType comparator) {
    this.id = id;
    this.standardName = standardName;
    this.comparator = comparator;
  }

  public SearchCriteria.ComparatorType getComparator() {
    return comparator;
  }

  public int getId() {
    return id;
  }

  public static Field valueOfStandard(String name) {
    for (Field field : Field.values())
      if (field.toStringStandard().equals(name))
        return field;
    throw new ClassCastException("\"" + name + "\" is not a valid standard Field name.");
  }

  public String toStringStandard() {
    return standardName;
  }
}
