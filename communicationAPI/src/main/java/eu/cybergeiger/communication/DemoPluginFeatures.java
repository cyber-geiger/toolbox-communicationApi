package eu.cybergeiger.communication;

public enum DemoPluginFeatures {
  FEATURE_HEARTBEAT(1),
  FEATURE_SCAN_DEMO(2),
  FEATURE_RANDOM_BOOLEAN(3),
  FEATURE_ALL(0);

  long id;

  DemoPluginFeatures(long id) {
    if (id <= 0) {
      this.id = ~(0L); // set all bits to 1 (regardless of representation)
    } else {
      this.id = (1L << (id-1));
    }
  }

  public long getId() {
    return this.id;
  }

  public boolean containsFeature(long featureList) {
    return (featureList & id)!=0;
  }

}
