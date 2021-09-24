
import 'java.dart';
/// <p>Interface for compatibility class for file access.</p>
abstract class TcFile with AutoCloseable
{
    /// <p>Reads all bytes of a file into a byte array.</p>
    /// @param fname the file to be read
    /// @return the content as byte array
    /// @throws IOException if anything goes wrong accessing the file
    List<int> readAllBytes(String fname);

    /// <p>Writes a byte array to a file.</p>
    /// @param fname the file to be written
    /// @param buf   the content of the file
    /// @throws IOException if anything goes wrong
    void writeAllBytes(String fname, List<int> buf);

}
