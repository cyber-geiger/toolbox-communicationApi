package eu.cybergeiger.api;

import eu.cybergeiger.api.plugin.CommunicationSecret;
import org.junit.jupiter.api.Test;

import java.util.Random;

import static org.assertj.core.api.Assertions.assertThat;

public class TestCommunicationSecret {
  @Test
  public void testDefaultConstructor() {
    CommunicationSecret emptySecret = new CommunicationSecret();
    assertThat(emptySecret.getBytes()).isEmpty();
  }

  @Test
  public void testFilledConstructor() {
    Random random = new Random();
    for (int size : new int[]{0, 1, 9999}) {
      byte[] bytes = new byte[size];
      random.nextBytes(bytes);
      CommunicationSecret filledSecret = new CommunicationSecret(bytes);
      assertThat(filledSecret.getBytes()).containsExactly(bytes);
    }
  }

  @Test
  public void testSetter() {
    CommunicationSecret secret = new CommunicationSecret();
    Random random = new Random();
    for (int size : new int[]{0, 1, 9999}) {
      byte[] bytes = new byte[size];
      random.nextBytes(bytes);
      secret.setBytes(bytes);
      assertThat(secret.getBytes()).containsExactly(bytes);
    }
  }
}
