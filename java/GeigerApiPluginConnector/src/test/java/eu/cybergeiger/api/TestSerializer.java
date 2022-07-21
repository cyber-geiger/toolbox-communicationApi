package eu.cybergeiger.api;

import eu.cybergeiger.serialization.SerializerHelper;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;

import static org.assertj.core.api.Assertions.assertThat;

public class TestSerializer {
  @Test
  public void testWriteIntByteOrder() throws IOException {
    ByteArrayOutputStream out = new ByteArrayOutputStream();
    SerializerHelper.writeInt(out, 257);
    assertThat(out.toByteArray()).containsExactly(
      0, 0, 0, 28, 111, -55, -97, 89, 0, 0, 1, 1
    );
  }

  @Test
  public void testWriteReadInt() throws IOException {
    for (int value : new int[]{0, 1, -1, (1 << 31) - 1}) {
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      SerializerHelper.writeInt(out, value);
      byte[] bytes = out.toByteArray();
      assertThat(bytes).hasSize(12);
      ByteArrayInputStream in = new ByteArrayInputStream(bytes);
      assertThat(SerializerHelper.readInt(in)).isEqualTo(value);
      assertThat(in).isEmpty();
    }
  }

  @Test
  public void testWriteReadLong() throws IOException {
    for (long value : new long[]{0, 1, -1, (1L << 63) - 1}) {
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      SerializerHelper.writeLong(out, value);
      byte[] bytes = out.toByteArray();
      assertThat(bytes).hasSize(16);
      ByteArrayInputStream in = new ByteArrayInputStream(bytes);
      assertThat(SerializerHelper.readLong(in)).isEqualTo(value);
      assertThat(in).isEmpty();
    }
  }

  @Test
  public void testWriteReadString() throws IOException {
    for (String value : new String[]{"", "string", "testMessage öäü^"}) {
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      SerializerHelper.writeString(out, value);
      byte[] bytes = out.toByteArray();
      ByteArrayInputStream in = new ByteArrayInputStream(bytes);
      assertThat(SerializerHelper.readString(in)).isEqualTo(value);
      assertThat(in).isEmpty();
    }
  }

  // TODO: test exception serialization
}
