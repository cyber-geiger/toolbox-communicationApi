package eu.cybergeiger.demo;

/**
 * <p>Enumeration providing selectable features from DemoPlugin.</p>
 */
public enum DemoPluginFeatures {
  FEATURE_HEARTBEAT(1),
  FEATURE_SCAN_DEMO(2),
  FEATURE_RANDOM_BOOLEAN(3),
  FEATURE_ALL(0);

  long id;

  DemoPluginFeatures(long bitNumber) {
    if (bitNumber <= 0) {
      this.id = ~(0L); // set all bits to 1 (regardless of representation)
    } else {
      this.id = (1L << (bitNumber - 1));
    }
  }

  /**
   * <p>The id of the feature in an xor'able way.</p>
   *
   * @return the xor'able/addable feature value
   */
  public long getId() {
    return this.id;
  }

  /**
   * <p>Check if the current feature is in the list of features provided.</p>
   *
   * @param featureList the feature list value to be checked
   * @return true if the featureList contains the feature value
   */
  public boolean containsFeature(long featureList) {
    return (featureList & id) != 0;
  }

}
