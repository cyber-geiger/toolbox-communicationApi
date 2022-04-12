package eu.cybergeiger.api;

import java.security.SecureRandom;
import java.util.Arrays;

import eu.cybergeiger.api.communication.GeigerCommunicator;
import eu.cybergeiger.api.plugin.CommunicationSecret;
import eu.cybergeiger.serialization.SerializerHelper;
import org.junit.Assert;
import org.junit.Test;

/**
 * Class to test CommunicationSecret implementation.
 * TODO change once CommunicationSecret has been fully specified
 */
public class TestCommunicationSecret {

  @Test
  public void testConstructorGetterSetter() {
    // default constructor
    for (int i = 0; i < 20; ++i) {
      CommunicationSecret secret = new CommunicationSecret();
      Assert.assertNotNull("checking existence", secret.getSecret());
      Assert.assertEquals("checking size", 32, secret.getSecret().length);
    }

    // constructor with size
    int[] sizes = new int[]{1, 5, 50, 250, 2600, 10000};
    for (int size : sizes) {
      CommunicationSecret secret2 = new CommunicationSecret(size);
      Assert.assertNotNull("checking existence", secret2.getSecret());
      Assert.assertEquals("checking size", size, secret2.getSecret().length);
    }

    // constructor with secret
    for (int i = 0; i < 20; ++i) {
      byte[] sec = SerializerHelper.intToByteArray(new SecureRandom().nextInt(Integer.MAX_VALUE));
      CommunicationSecret secret3 = new CommunicationSecret(sec);
      Assert.assertNotNull("checking existence", secret3.getSecret());
      Assert.assertEquals("checking size", sec.length, secret3.getSecret().length);
      Assert.assertArrayEquals("checking content", sec, secret3.getSecret());
    }
    // should be caught and generate a Randomsecret
    byte[] value = new byte[0];
    CommunicationSecret secret3b =  new CommunicationSecret(value);
    Assert.assertNotNull("checking existence", secret3b.getSecret());
    Assert.assertEquals("checking size", 32, secret3b.getSecret().length);

    byte[] value2 = null;
    CommunicationSecret secret3c =  new CommunicationSecret(value2);
    Assert.assertNotNull("checking existence", secret3c.getSecret());
    Assert.assertEquals("checking size", 32, secret3c.getSecret().length);

    // setter
    for (int i = 0; i < 20; ++i) {
      CommunicationSecret secret4 = new CommunicationSecret();
      byte[] secretValue = secret4.getSecret();
      byte[] newSecretValue = SerializerHelper.intToByteArray(new SecureRandom().nextInt(Integer.MAX_VALUE));
      secret4.setSecret(newSecretValue);
      Assert.assertNotNull("checking existence", secret4.getSecret());
      Assert.assertFalse("checking if secret changed", Arrays.equals(secretValue,
          secret4.getSecret()));
      Assert.assertArrayEquals("checking if secret is set correctly", newSecretValue,
          secret4.getSecret());
    }
    byte[] value3 = new byte[0];
    CommunicationSecret secret4b =  new CommunicationSecret();
    final byte[] prevSecret = secret4b.getSecret();
    secret4b.setSecret(value3);
    Assert.assertNotNull("checking existence", secret4b.getSecret());
    Assert.assertEquals("checking size", 32, secret4b.getSecret().length);
    Assert.assertFalse("checking if secret changed", Arrays.equals(prevSecret,
        secret4b.getSecret()));

    byte[] value4 = null;
    final byte[] prevSecret2 = secret4b.getSecret();
    secret4b.setSecret(value4);
    Assert.assertNotNull("checking existence", secret4b.getSecret());
    Assert.assertEquals("checking size", 32, secret4b.getSecret().length);
    Assert.assertFalse("checking if secret changed", Arrays.equals(prevSecret2,
        secret4b.getSecret()));

    // negative tests
    // constructor with size
    int[] incorrectSizes = new int[]{-1, -5, 0};
    for (int size : incorrectSizes) {
      Assert.assertThrows(IllegalArgumentException.class, () -> new CommunicationSecret(size));
    }
  }

}
