package eu.cybergeiger.api.utils;

public enum Platform {
  WINDOWS,
  LINUX,
  MAC;

  public static Platform getPlatform() {
    String platform = System.getProperty("os.name").toLowerCase();
    if (platform.contains("win")) return WINDOWS;
    if (platform.contains("nix") ||
      platform.contains("nux") ||
      platform.contains("aix")) return LINUX;
    if (platform.contains("mac")) return MAC;
    throw new RuntimeException("Unknown platform \"" + platform + "\".");
  }
}
