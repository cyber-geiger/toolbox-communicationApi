package eu.cybergeiger.storage.node.value;

import eu.cybergeiger.serialization.Serializable;

import java.util.Locale;
import java.util.Map;
import java.util.MissingResourceException;

/**
 * <p>Interface for accessing key/value pairs in nodes.</p>
 *
 * <p>All values supporting locales must have at least an english (@see Locale.ENGLISH) locale.</p>
 */
public interface NodeValue extends Serializable {

  /**
   * <p>Gets the key of the K/V tuple.</p>
   *
   * @return the string representation of the key
   */
  String getKey();

  /**
   * <p>Gets the string representation of the value in the default locale (Locale.ENGLISH).</p>
   *
   * @return the string representation of the value
   */
  String getValue();

  /**
   * <p>Gets the string representation of the value.</p>
   *
   * @param languageRange the set of languages requested
   * @return the string representation of the value
   */
  String getValue(String languageRange);

  /**
   * <p>Gets all translations of the value.</p>
   *
   * @return a Map containing all translations for the value and their locale
   */
  Map<Locale, String> getAllValueTranslations();

  /**
   * <p>Sets the string representation of the value.</p>
   *
   * @param value  the string representation of the value
   * @param locale the locale to be fetched
   * @throws MissingResourceException if the text for the default locale (ENGLISH) is missing
   */
  void setValue(String value, Locale locale) throws MissingResourceException;

  /**
   * <p>Sets the string representation of the value.</p>
   *
   * @param value the string representation of the value
   */
  void setValue(String value);

  /**
   * <p>Gets the type of value.</p>
   *
   * @return the string representation of the type
   */
  String getType();

  /**
   * <p>Sets the type of value.</p>
   *
   * @param type the string representation of the type to be set
   * @return the string representation of the previously set type
   */
  String setType(String type);

  /**
   * <p>Gets the description of the value.</p>
   *
   * <p>This description is used when asking for the users consent to share this data.</p>
   *
   * @return the string of the currently set description
   */
  String getDescription();

  /**
   * <p>Gets the description of the value.</p>
   *
   * <p>This description is used when asking for the users consent to share this data.</p>
   *
   * @param languageRange the set of languages requested
   * @return the string of the currently set description
   */
  String getDescription(String languageRange);

  /**
   * <p>Gets all translations of the description of the value.</p>
   *
   * @return a Map containing all translations for the description and their locale
   */
  Map<Locale, String> getAllDescriptionTranslations();

  /**
   * <p>Sets the description of the value.</p>
   *
   * <p>This description is used when asking for the users consent to share this data.</p>
   *
   * @param description the description to be set
   * @param locale      the locale to be written
   * @return the string of the previously set description.
   * @throws MissingResourceException if the default locale is missing
   */
  String setDescription(String description, Locale locale) throws MissingResourceException;

  /**
   * <p>Sets the description of the value.</p>
   *
   * <p>This description is used when asking for the users consent to share this data.</p>
   *
   * @param description the description to be set
   * @return the string of the previously set description.
   */
  String setDescription(String description);

  /**
   * <p>Gets the epoch of the last modification of the value.</p>
   *
   * @return a value reflecting the epoch of the last change
   */
  long getLastModified();

  /**
   * <p>Copies the all values of the given node to the current node.</p>
   *
   * @param n2 the K/V tuple to be copie  d
   */
  void update(NodeValue n2);

  /**
   * <p>Sets last modified to now.</p>
   */
  void touch();

  /**
   * <p>Creates a deep clone of the K/V tuple.</p>
   *
   * @return a copy of the current node value
   */
  NodeValue deepClone();

  /***
   * <p>prints a space prefixed representation of the NodeValue.</p>
   *
   * @param prefix a prefix (typically a series of spaces
   * @return the string representation
   */
  String toString(String prefix);

}
