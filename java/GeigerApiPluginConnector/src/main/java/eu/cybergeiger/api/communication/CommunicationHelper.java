package eu.cybergeiger.api.communication;

import eu.cybergeiger.api.GeigerApi;
import eu.cybergeiger.api.message.Message;
import eu.cybergeiger.api.message.MessageType;
import eu.cybergeiger.api.plugin.PluginListener;

import java.io.IOException;
import java.util.Objects;
import java.util.concurrent.TimeoutException;

/**
 * A helper class for sending and waiting on Messages.
 * TODO should this only be used for Testing?
 */
public class CommunicationHelper {
  private static class Listener implements PluginListener {
    private final GeigerApi api;
    private final Message requestMessage;
    private final MessageType[] responseTypes;
    private Message responseMessage = null;
    private final Object receivedResponse = new Object();


    public Listener(GeigerApi api, Message requestMessage, MessageType[] responseTypes) {
      this.api = api;
      this.requestMessage = requestMessage;
      this.responseTypes = responseTypes;
      this.api.registerListener(responseTypes, this);
    }

    @Override
    public void pluginEvent(Message message) {
      if (responseMessage != null ||
        !Objects.equals(requestMessage.getRequestId(), message.getRequestId()) ||
        !Objects.equals(requestMessage.getTargetId(), message.getSourceId()) ||
        !Objects.equals(requestMessage.getSourceId(), message.getTargetId()))
        return;
      synchronized (receivedResponse) {
        responseMessage = message;
        receivedResponse.notifyAll();
      }
    }

    public void dispose() {
      api.deregisterListener(responseTypes, this);
    }

    public Message waitForResult(long timeoutMillis) throws TimeoutException, InterruptedException {
      if (responseMessage == null) {
        synchronized (receivedResponse) {
          receivedResponse.wait(timeoutMillis);
        }
      }
      if (responseMessage == null) {
        throw new TimeoutException("Timeout reached while waiting for reply.");
      }
      return responseMessage;
    }
  }


  /**
   * <p>Sends a message and waits for the first
   * returning message of a specific type with the same requestId.</p>
   *
   * @param api     GeigerAPI to communicate over.
   * @param message Message to send.
   * @return The response Message.
   */
  public static Message sendAndWait(GeigerApi api, Message message)
    throws InterruptedException, TimeoutException, IOException {
    return sendAndWait(api, message, new MessageType[]{MessageType.COMAPI_SUCCESS, MessageType.COMAPI_ERROR});
  }

  /**
   * <p>Sends a message and waits for the first
   * returning message of a specific type with the same requestId.</p>
   *
   * @param api           GeigerAPI to communicate over.
   * @param message       Message to send.
   * @param responseTypes Possible message types of response message.
   * @return The response Message.
   */
  public static Message sendAndWait(GeigerApi api, Message message, MessageType[] responseTypes)
    throws InterruptedException, TimeoutException, IOException {
    return sendAndWait(api, message, responseTypes, 30000);
  }

  /**
   * <p>Sends a message and waits for the first
   * returning message of a specific type with the same requestId.</p>
   *
   * @param api           GeigerAPI to communicate over.
   * @param message       Message to send.
   * @param responseTypes Possible message types of response message.
   * @param timeoutMillis Timeout in milliseconds.
   * @return The response Message.
   */
  public static Message sendAndWait(GeigerApi api, Message message,
                                    MessageType[] responseTypes, long timeoutMillis)
    throws InterruptedException, TimeoutException, IOException {
    Listener listener = new Listener(api, message, responseTypes);
    api.sendMessage(message);
    Message result = listener.waitForResult(timeoutMillis);
    listener.dispose();
    return result;
  }
}
