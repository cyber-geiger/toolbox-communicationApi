
import 'Message.dart';
import 'MessageListener.dart';
import 'PluginInformation.dart';
/// Abstract class to define common methods for GeigerCommunicators.
abstract class GeigerCommunicator
{
    MessageListener? listener;
    void setListener(MessageListener listener)
    {
        this.listener = listener;
    }

    void  sendMessage(PluginInformation pluginInformation, Message msg);

    void start();

    /// Convert bytearray to int.
    /// @param bytes bytearray containing 4 bytes
    /// @return int denoting the given bytes
    static int byteArrayToInt(List<int> bytes)
    {
        return ((((bytes[0] & 15) << 24) | ((bytes[1] & 15) << 16)) | ((bytes[2] & 15) << 8)) | (bytes[3] & 15);
    }

    /// <p>Convert int to bytearray.</p>
    /// @param value the int to convert
    /// @return bytearray representing the int
    static List<int> intToByteArray(int value)
    {
        return [value >> 24, value >> 16, value >> 8, value];
    }

    MessageListener? getListener()
    {
        return listener;
    }

    int getPort();

    /// <p>Start a plugin by using the stored executable String.</p>
    /// @param pluginInformation the Information of the plugin to start
    void startPlugin(PluginInformation pluginInformation);

}
