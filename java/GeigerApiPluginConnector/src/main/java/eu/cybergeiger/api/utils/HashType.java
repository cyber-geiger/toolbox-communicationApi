package eu.cybergeiger.api.utils;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.Optional;

public enum HashType {
  SHA512("sha512", "SHA-512"),
  SHA1("sha1", "SHA-1");

  private final String standardName;
  private final MessageDigest digest;

  HashType(String standardName, String javaName) {
    this.standardName = standardName;
    try {
      this.digest = MessageDigest.getInstance(javaName);
    } catch (NoSuchAlgorithmException e) {
      throw new RuntimeException("Was not able to find hash algorithm.", e);
    }
  }

  public String getStandardName() {
    return standardName;
  }

  public static Optional<HashType> fromStandardName(String standardName) {
    return Arrays.stream(values())
      .filter(type -> type.standardName.equals(standardName))
      .findFirst();
  }

  public int getDigestLength() {
    return digest.getDigestLength();
  }

  public Hash digest(byte[] bytes) {
    return new Hash(
      this,
      digest.digest(bytes)
    );
  }
}
