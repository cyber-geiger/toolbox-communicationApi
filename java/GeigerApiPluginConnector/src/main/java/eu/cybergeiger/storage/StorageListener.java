package eu.cybergeiger.storage;

import eu.cybergeiger.storage.node.Node;

/**
 * <p>Listener interface for storage events.</p>
 */
public interface StorageListener {

  /***
   * <p>Event listener for all storage node changes.</p>
   *
   * @param event the type of event causing the call
   * @param oldNode the old node content
   * @param newNode the new node content
   *
   * @throws StorageException if the storage backend encounters a problem
   */
  void gotStorageChange(ChangeType event, Node oldNode, Node newNode) throws StorageException;

}
