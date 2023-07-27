package eu.cybergeiger.api.communication;

import eu.cybergeiger.api.GeigerApi;
import eu.cybergeiger.api.PluginApi;
import eu.cybergeiger.api.message.Message;
import eu.cybergeiger.serialization.SerializerHelper;

import java.io.*;
import java.net.Socket;
import java.util.logging.Level;

/**
 * Class to handle incoming messages.
 */
public class MessageHandler implements Runnable {
  private final Socket socket;
  private final PluginApi pluginApi;

  public MessageHandler(Socket socket, PluginApi api) {
    this.socket = socket;
    this.pluginApi = api;
  }

  @Override
  public void run() {
    Message message;
    try {
      message = Message.fromByteArrayStream(socket.getInputStream());
    } catch (IOException e) {
      GeigerApi.logger.log(Level.WARNING, "Encountered exception while deserializing message.", e);
      return;
    }
    try {
      pluginApi.receivedMessage(message);
    } catch (IOException e) {
      GeigerApi.logger.log(Level.WARNING, "Encountered exception while processing message.", e);
    }
    try{
      SerializerHelper.writeLong(
        socket.getOutputStream(),
        GeigerCommunicator.RESPONSE_UID
      );
      socket.getOutputStream().flush();
    } catch (IOException e) {
      GeigerApi.logger.log(Level.WARNING, "Failed to send back response UID.", e);
    }
    try {
      socket.close();
    } catch (IOException e) {
      GeigerApi.logger.log(Level.WARNING, "Failed to close socket.", e);
    }
  }
}
