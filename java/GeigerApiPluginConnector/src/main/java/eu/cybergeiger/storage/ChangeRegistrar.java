package eu.cybergeiger.storage;

/**
 * <p>Interface for registrar support for change listeners.</p>
 */
public interface ChangeRegistrar {

  /***
   * <p>Registers a listener for a specific search criteria.</p>
   *
   * @param listener the listener to be added
   * @param criteria the criteria triggering calls to the listener
   *
   * @throws StorageException in case of any communication or storage problem
   */
  void registerChangeListener(StorageListener listener, SearchCriteria criteria)
    throws StorageException;

  /***
   * <p>Removes a registered listener.</p>
   *
   * @param listener the listener to be removed
   * @return the removed search criteria
   *
   * @throws StorageException in case of any communication or storage problem
   */
  SearchCriteria[] deregisterChangeListener(StorageListener listener) throws StorageException;
}
