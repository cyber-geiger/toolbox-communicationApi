package eu.cybergeiger.storage.node;

import eu.cybergeiger.serialization.Serializable;
import eu.cybergeiger.storage.StorageController;
import eu.cybergeiger.storage.StorageException;
import eu.cybergeiger.storage.Visibility;
import eu.cybergeiger.storage.node.value.NodeValue;

import java.util.Map;

/**
 * <p>Interface representing a single node in the storage.</p>
 */
public interface Node extends Serializable {
  /**
   * <p>Gets the name of the current node.</p>
   *
   * @return the name of the current node without the path prefix
   */
  String getName();

  /**
   * <p>Gets the parent path of the node.</p>
   *
   * @return the parent path of the current node
   */
  String getParentPath();

  /**
   * <p>Gets the full path with name of the current node.</p>
   *
   * @return the fully qualified name of the current node
   */
  String getPath();

  /**
   * <p>Gets the owner of the current object.</p>
   *
   * @return string representation of the owner
   */
  String getOwner();

  /**
   * <p>Sets the owner string.</p>
   *
   * @param newOwner the string representation of the previously set owner
   * @return the previously set owner
   */
  String setOwner(String newOwner) throws StorageException;

  /**
   * <p>Gets the current visibility according to the TLP protocol.</p>
   *
   * @return the current visibility
   */
  Visibility getVisibility();

  /**
   * <p>Sets the visibility of the node.</p>
   *
   * @param newVisibility the new visibility
   * @return the visibility set previously
   */
  Visibility setVisibility(Visibility newVisibility);

  long getLastModified();
  void setLastModified(long newLastModified);
  String getExtendedLastModified();

  /**
   * <p>Add a key/value pair to the node.</p>
   *
   * <p>Adds a K/V tuple to the node. The key must not
   * exist prior adding.</p>
   *
   * @param value a NodeValue object representing the K/V pair
   * @throws StorageException if key already exists
   */
  void addValue(NodeValue value) throws StorageException;

  /**
   * <p>Get a specific value of the node.</p>
   *
   * @param key the key to be looked up
   * @return the requested value or null if not found
   * @throws StorageException if the storage backend encounters a problem
   */
  NodeValue getValue(String key) throws StorageException;

  /**
   * <p>Update a specific value of the node.</p>
   *
   * @param value the key to be updated
   * @return the requested value or null if not found
   * @throws StorageException if the storage backend encounters a problem
   */
  NodeValue updateValue(NodeValue value) throws StorageException;

  /**
   * <p>Removes a value from the node.</p>
   *
   * @param key the key of the value to be removed
   * @return the removed node value or null if not found
   * @throws StorageException if the storage backend encounters a problem
   */
  NodeValue removeValue(String key) throws StorageException;

  /**
   * <p>Get a deep copy of all values stored in the node.</p>
   *
   * @return a map of all values
   */
  Map<String, NodeValue> getValues();

  /***
   * <p>Adds a child node to this node.</p>
   *
   * @param node the child node to be added
   *
   * @throws StorageException if the storage backend encounters a problem
   */
  void addChild(Node node) throws StorageException;

  /***
   * <p>Gets a child node from the current node.</p>
   *
   * @param name the name of the child node to fetch
   * @return the requested child node or null if the node does not exist
   *
   * @throws StorageException if the storage backend encounters a problem
   */
  Node getChild(String name) throws StorageException;


  /***
   * <p>Removes a child node from this node.</p>
   *
   * @param name the name of the child node to be removed
   */
  void removeChild(String name);

  /**
   * <p>Get a map of all existing child nodes.</p>
   *
   * @return the map containing all child nodes
   * @throws StorageException if the storage backend encounters a problem
   */
  Map<String, Node> getChildren() throws StorageException;

  /**
   * <p>Gets the child nodes as CVS export.</p>
   *
   * @return A string representing the nodes as CVS
   * @throws StorageException if the storage backend encounters a problem
   */
  String getChildNodesCsv() throws StorageException;

  /**
   * <p>Returns true if the current node is not yet materialized.</p>
   *
   * @return true if the current node is a skeleton only
   */
  boolean isSkeleton();

  /**
   * <p>Returns true if the node was there in the past but deleted.</p>
   *
   * @return true if the node was deleted
   */
  boolean isTombstone();

  /**
   * <p>get the controller needed for materializing the node if required.</p>
   *
   * @return the controller
   */
  StorageController getController();

  /**
   * <p>Sets the controller needed for materializing the node if required.</p>
   *
   * @param controller the controller to be set
   * @return the previously set controller
   */
  StorageController setController(StorageController controller);

  /**
   * <p>Update all data of the node with the data of the given node.</p>
   *
   * @param n2 the node whose values should be copied
   * @throws StorageException if the storage backend encounters a problem
   */
  void update(Node n2) throws StorageException;

  /**
   * <p>Sets last modified to now.</p>
   */
  void touch();

  /**
   * <p>Create a deep clone of the current node.</p>
   *
   * @return the cloned node
   * @throws StorageException if the storage backend encounters a problem
   */
  Node deepClone() throws StorageException;

  /**
   * <p>Create a shallow clone of the current node.</p>
   *
   * <p>any children of the node are included skeletoized.</p>
   *
   * @return the cloned node
   * @throws StorageException if the storage backend encounters a problem
   */
  Node shallowClone() throws StorageException;

}
