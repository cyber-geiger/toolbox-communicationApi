package eu.cybergeiger.storage.node;

import eu.cybergeiger.storage.SearchCriteria;

/**
 * <p>Field reflects the available ordinals in a node.</p>
 */
public enum Field {
  OWNER(1, SearchCriteria.ComparatorType.STRING),
  NAME(2, SearchCriteria.ComparatorType.STRING),
  PATH(3, SearchCriteria.ComparatorType.STRING),
  KEY(4, SearchCriteria.ComparatorType.STRING),
  VALUE(5, SearchCriteria.ComparatorType.STRING),
  TYPE(6, SearchCriteria.ComparatorType.STRING),
  VISIBILITY(7, SearchCriteria.ComparatorType.STRING),
  LAST_MODIFIED(8, SearchCriteria.ComparatorType.DATETIME),
  EXPIRY(9, SearchCriteria.ComparatorType.DATETIME),
  TOMBSTONE(10, SearchCriteria.ComparatorType.BOOLEAN);

  private final SearchCriteria.ComparatorType comparator;
  private final int id;

  Field(int id, SearchCriteria.ComparatorType comparator) {
    this.comparator = comparator;
    this.id = id;
  }

  public SearchCriteria.ComparatorType getComparator() {
    return comparator;
  }

  public int getId() {
    return id;
  }

}
