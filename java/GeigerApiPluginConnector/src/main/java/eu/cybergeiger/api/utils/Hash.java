package eu.cybergeiger.api.utils;

import eu.cybergeiger.serialization.Serializable;
import eu.cybergeiger.serialization.SerializerHelper;

import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;
import java.util.Arrays;
import java.util.Objects;

public class Hash implements Serializable {
  private static final char[] HEX_CHARS = "0123456789ABCDEF".toCharArray();

  private static final long serialVersionUID = 647930842152L;

  final HashType type;
  final byte[] bytes;

  Hash(HashType type, byte[] bytes) {
    this.type = type;
    this.bytes = bytes;
  }

  public HashType getType() {
    return type;
  }

  public byte[] getBytes() {
    return bytes;
  }

  @Override
  public void toByteArrayStream(OutputStream out) throws IOException {
    SerializerHelper.writeMarker(out, serialVersionUID);
    SerializerHelper.writeString(out, type.getStandardName());
    out.write(bytes);
    SerializerHelper.writeMarker(out, serialVersionUID);
  }

  public static Hash fromByteArrayStream(InputStream in) throws IOException {
    SerializerHelper.testMarker(in, serialVersionUID);

    HashType type = HashType.fromStandardName(
      SerializerHelper.readString(in)
    ).orElseThrow(() -> new ClassCastException("Found unknown hash type."));

    byte[] bytes = new byte[type.getDigestLength()];
    in.read(bytes);

    SerializerHelper.testMarker(in, serialVersionUID);

    return new Hash(type, bytes);
  }

  @Override
  public String toString() {
    char[] chars = new char[bytes.length * 2];
    for (int i = 0; i < bytes.length; i++) {
      int value = bytes[i] & 0xFF;
      chars[i * 2] = HEX_CHARS[value >>> 4];
      chars[i * 2 + 1] = HEX_CHARS[value & 0x0F];
    }
    return new String(chars);
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    Hash hash = (Hash) o;
    return type == hash.type && Arrays.equals(bytes, hash.bytes);
  }

  @Override
  public int hashCode() {
    return Objects.hash(type, Arrays.hashCode(bytes));
  }
}
