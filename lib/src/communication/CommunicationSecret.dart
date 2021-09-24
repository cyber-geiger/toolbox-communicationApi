
import 'java.dart';
/// <p>Encapsulates secret parameters for communication and provides methods to employ them.</p>
class CommunicationSecret with ch_fhnw_geiger_serialization_Serializer
{
    static const int serialVersionUID = 8901230;
    static const int DEFAULT_SIZE = 32;
    List<int> secret = new List<int>(0);
    /// <p>Creates a new secret with random content and standard size.</p>
    CommunicationSecret()
    {
        this(DEFAULT_SIZE);
    }

    /// <p>Creates a new secret with random content and specified size.</p>
    /// @param size the size of the secret in bytes
    CommunicationSecret(int size)
    {
        setRandomSecret(size);
    }

    /// <p>Creates a secret which is already known.</p>
    /// @param secret the already known secret
    CommunicationSecret(List<int> secret)
    {
        if ((secret == null) || (secret.length == 0)) {
            setRandomSecret(DEFAULT_SIZE);
        } else {
            this.secret = secret;
        }
    }

    /// <p>Gets the secret.</p>
    /// @return the current secret
    List<int> getSecret()
    {
        return Arrays.copyOf(secret, secret.length);
    }

    /// <p>Sets a new Secret with size.</p>
    /// @param size the size of the new secret
    void setRandomSecret(int size)
    {
        if (size <= 0) {
            throw new IllegalArgumentException("size must be greater than 0");
        }
        secret = new List<int>(size);
        for (int i = 0; i < size; i++) {
            int value = Random.nextInt(Integer.MAX_VALUE);
            secret[i] = value;
        }
    }

    /// <p>Sets the secret.</p>
    /// If new secret is null or its length is 0 a random secret is generated
    /// @param newSecret the new secret bytes
    /// @return the previously set secret
    List<int> setSecret(List<int> newSecret)
    {
        List<int> ret = this.secret;
        if ((newSecret == null) || (newSecret.length == 0)) {
            setRandomSecret(DEFAULT_SIZE);
        } else {
            this.secret = Arrays.copyOf(newSecret, newSecret.length);
        }
        return ret;
    }

    void toByteArrayStream(ch_fhnw_geiger_totalcross_ByteArrayOutputStream out)
    {
        SerializerHelper.writeLong(out, serialVersionUID);
        SerializerHelper.writeString(out, Base64.encodeToString(secret));
        SerializerHelper.writeLong(out, serialVersionUID);
    }

    /// <p>Reads objects from ByteArrayInputStream and stores them in map.</p>
    /// @param in ByteArrayInputStream to be used
    /// @return the deserialized Storable String
    /// @throws IOException if value cannot be read
    static CommunicationSecret fromByteArrayStream(ch_fhnw_geiger_totalcross_ByteArrayInputStream in_)
    {
        if (SerializerHelper.readLong(in_) != serialVersionUID) {
            throw new ClassCastException("Reading start marker fails");
        }
        List<int> secret = Base64.decode(SerializerHelper.readString(in_));
        CommunicationSecret ret = new CommunicationSecret(secret);
        if (SerializerHelper.readLong(in_) != serialVersionUID) {
            throw new ClassCastException("Reading end marker fails");
        }
        return ret;
    }

    String toString()
    {
        return "" + new String(secret, StandardCharsets.UTF_8).hashCode();
    }

}
