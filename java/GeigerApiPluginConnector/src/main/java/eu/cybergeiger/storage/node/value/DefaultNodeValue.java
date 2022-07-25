package eu.cybergeiger.storage.node.value;


import eu.cybergeiger.serialization.SerializerHelper;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.*;

/**
 * <p>This abstract class defines the common attributes for all NodeValueObjects.</p>
 *
 * @author Sacha
 * @version 0.1
 */
public class DefaultNodeValue implements NodeValue {

  private static final long serialVersionUID = 871283188L;

  public static final Locale DEFAULT_LOCALE = Locale.ENGLISH;

  /**
   * The key is used to identify the NodeValueObject inside a StorageNode,
   * therefore, the key is unique within one StorageNode.
   */
  private String key;

  private final Map<String, String> value = new HashMap<>();

  /**
   * <p>The type of the value.</p>>
   */
  private String type;

  /**
   * Description of this value, can be used for translation.
   */
  private final Map<String, String> description = new HashMap<>();

  /**
   * Defines the epoch when this value was last modified.
   */
  private long lastModified;

  /**
   * <p>Default constructor to create a new key/value pair.</p>
   *
   * <p>Type and description of the key/value pair are set to null. This
   * Constructor should only be used for private values (visibility RED).</p>
   *
   * @param key   the name of the key
   * @param value the value of the key
   */
  public DefaultNodeValue(String key, String value) {
    this(key, value, null, null, 0);
  }

  /**
   * <p>A fully fledged constructor for creating key/value pairs suitable for sharing.</p>
   *
   * @param key          the name of the key/value pair
   * @param value        the value to be set
   * @param type         a searchable type field
   * @param description  the description to be shown when asking for consent of sharing
   * @param lastModified the last modified date to be set
   */
  public DefaultNodeValue(String key, String value, String type, String description,
                          long lastModified) {
    if (key == null || value == null) {
      throw new NullPointerException("Neither key nor value may be null (" + key + "=" + value + ")");
    }
    this.key = key;
    this.type = type;
    setLocalizedString(this.value, value, DEFAULT_LOCALE);
    if (description != null) {
      setLocalizedString(this.description, description, DEFAULT_LOCALE);
    }
    this.lastModified = lastModified;
  }

  @Override
  public String getKey() {
    return key;
  }

  private void setKey(String key) {
    this.key = key;
    touch();
  }

  @Override
  public String getValue() {
    return getValue(DEFAULT_LOCALE.toLanguageTag());
  }

  @Override
  public String getValue(String languageRange) {
    return getLocalizedString(this.value, languageRange);
  }

  @Override
  public Map<Locale, String> getAllValueTranslations() {
    Map<Locale, String> m = new HashMap<>();
    for (Map.Entry<String, String> e : value.entrySet()) {
      m.put(Locale.forLanguageTag(e.getKey()), e.getValue());
    }
    return m;
  }

  @Override
  public void setValue(String value, Locale locale) throws MissingResourceException {
    setLocalizedString(this.value, value, locale);
    touch();
  }

  @Override
  public void setValue(String value) {
    setValue(value, DEFAULT_LOCALE);
  }

  @Override
  public String getType() {
    return type;
  }

  @Override
  public String setType(String type) {
    String ret = this.type;
    this.type = type;
    touch();
    return ret;
  }

  @Override
  public String getDescription() {
    return getDescription(DEFAULT_LOCALE.toLanguageTag());
  }

  @Override
  public String getDescription(String languageRange) {
    return getLocalizedString(description, languageRange);
  }

  @Override
  public Map<Locale, String> getAllDescriptionTranslations() {
    Map<Locale, String> m = new HashMap<>();
    for (Map.Entry<String, String> e : description.entrySet()) {
      m.put(Locale.forLanguageTag(e.getKey()), e.getValue());
    }
    return m;
  }

  private static Locale lookupLocale(Map<String, String> map, String languageRange) {
    String bestMatch = Locale.lookupTag(Locale.LanguageRange.parse(languageRange), map.keySet());
    if (bestMatch == null) return DEFAULT_LOCALE;
    return Locale.forLanguageTag(bestMatch);
  }

  private static String getLocalizedString(Map<String, String> map, String languageRange) {
    return map.get(lookupLocale(map, languageRange).toLanguageTag());
  }

  private static void setLocalizedString(Map<String, String> map, String value, Locale locale)
    throws MissingResourceException {
    if (getLocalizedString(map, DEFAULT_LOCALE.toLanguageTag()) == null
      && !locale.toLanguageTag().equals(DEFAULT_LOCALE.toLanguageTag())) {
      throw new MissingResourceException(
        "Undefined string for locale: \"" + DEFAULT_LOCALE + "\"",
        "Locale", locale.toLanguageTag()
      );
    }
    map.put(locale.toLanguageTag(), value);
  }

  @Override
  public String setDescription(String value, Locale locale) {
    if (value == null)
      throw new NullPointerException("Description may not be null.");
    String ret = getLocalizedString(this.description, locale.toLanguageTag());
    setLocalizedString(this.description, value, locale);
    touch();
    return ret;
  }

  @Override
  public String setDescription(String description) {
    return setDescription(description, DEFAULT_LOCALE);
  }

  @Override
  public long getLastModified() {
    return lastModified;
  }

  @Override
  public void update(NodeValue node) {
    DefaultNodeValue n2 = (DefaultNodeValue) (node);
    this.key = n2.getKey();
    this.value.clear();
    this.value.putAll(n2.value);
    this.type = n2.getType();
    this.description.clear();
    this.description.putAll(n2.description);
    touch();
  }

  public void touch() {
    this.lastModified = System.currentTimeMillis();
  }

  @Override
  public NodeValue deepClone() {
    NodeValue ret = new DefaultNodeValue(getKey(), getValue());
    ret.update(this);
    return ret;
  }

  @Override
  public String toString() {
    return toString("");
  }

  /***
   * <p>prints a space prefixed representation of the NodeValue.</p>
   *
   * @param prefix a prefix (typically a series of spaces
   * @return the string representation
   */
  public String toString(String prefix) {
    StringBuilder sb = new StringBuilder();
    // build head of value
    sb.append(prefix).append(getKey());
    if (getType() != null) {
      sb.append(":").append(getType());
    }
    // build values
    sb.append("={");
    if (value.size() == 1) {
      sb.append(DEFAULT_LOCALE.toLanguageTag()).append("=>\"").append(value.get(DEFAULT_LOCALE.toLanguageTag())).append("\"}");
    } else {
      sb.append(System.lineSeparator());
      int i = 0;
      for (String l : new TreeSet<>(value.keySet())) {
        if (i > 0) {
          sb.append(",").append(System.lineSeparator());
        }
        sb.append(prefix).append("  ").append(Locale.forLanguageTag(l).toLanguageTag()).append("=>\"")
          .append(value.get(l)).append("\"");
        i++;
      }
      sb.append(System.lineSeparator()).append(prefix).append("}");
      // build description

    }
    return sb.toString();
  }

  @Override
  public boolean equals(Object o) {
    if (!(o instanceof DefaultNodeValue)) {
      return false;
    }
    DefaultNodeValue nv = (DefaultNodeValue) o;

    return toString().equals(nv.toString());
  }

  @Override
  public void toByteArrayStream(ByteArrayOutputStream out) throws IOException {
    SerializerHelper.writeMarker(out, serialVersionUID);
    SerializerHelper.writeString(out, key);
    SerializerHelper.writeInt(out, value.size());
    synchronized (value) {
      for (Map.Entry<String, String> e : value.entrySet()) {
        SerializerHelper.writeString(out, e.getKey());
        SerializerHelper.writeString(out, e.getValue());
      }
    }
    SerializerHelper.writeString(out, type);
    SerializerHelper.writeLong(out, lastModified);
    SerializerHelper.writeInt(out, description.size());
    synchronized (description) {
      for (Map.Entry<String, String> e : description.entrySet()) {
        SerializerHelper.writeString(out, e.getKey());
        SerializerHelper.writeString(out, e.getValue());
      }
    }
    SerializerHelper.writeLong(out, serialVersionUID);
  }

  /**
   * <p>Deserializes a NodeValue from a byteStream.</p>
   *
   * @param in the stream to be read
   * @return the deserialized NodeValue
   * @throws IOException if an exception happens deserializing the stream
   */
  public static DefaultNodeValue fromByteArrayStream(ByteArrayInputStream in) throws IOException {
    SerializerHelper.testMarker(in, serialVersionUID);
    DefaultNodeValue value = new DefaultNodeValue(SerializerHelper.readString(in), "");
    int valueCount = SerializerHelper.readInt(in);
    value.value.clear();
    for (int i = 0; i < valueCount; i++) {
      value.value.put(
        Locale.forLanguageTag(Objects.requireNonNull(SerializerHelper.readString(in))).toLanguageTag(),
        SerializerHelper.readString(in)
      );
    }
    value.type = SerializerHelper.readString(in);
    value.lastModified = SerializerHelper.readLong(in);
    int descriptionCount = SerializerHelper.readInt(in);
    for (int i = 0; i < descriptionCount; i++) {
      value.description.put(
        Locale.forLanguageTag(Objects.requireNonNull(SerializerHelper.readString(in))).toLanguageTag(),
        SerializerHelper.readString(in)
      );
    }
    SerializerHelper.testMarker(in, serialVersionUID);
    return value;
  }
}
