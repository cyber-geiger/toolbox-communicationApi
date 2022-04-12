package eu.cybergeiger.api.communication;

import eu.cybergeiger.api.*;
import eu.cybergeiger.api.exceptions.CommunicationException;
import eu.cybergeiger.api.message.GeigerUrl;
import eu.cybergeiger.api.message.Message;
import eu.cybergeiger.api.message.MessageType;
import eu.cybergeiger.api.plugin.PluginListener;

import java.util.Objects;

/**
 * A helper class for sending and waiting on Messages.
 * TODO should this only be used for Testing?
 */
public class CommunicationHelper {


  private static class Listener implements PluginListener {

    private final GeigerApi api;
    private final Object receivedResponse = new Object();
    private final Message requestMessage;
    private final MessageType[] responseTypes;
    private Message responseMessage = null;


    public Listener(GeigerApi api, Message requestMessage, MessageType[] responseTypes) {
      this.api = api;
      this.requestMessage = requestMessage;
      this.responseTypes = responseTypes;
      this.api.registerListener(responseTypes, this);
    }

    @Override
    public void pluginEvent(Message message) {
      if (responseMessage != null ||
        !requestMessage.getRequestId().equals(message.getRequestId()) ||
        !Objects.equals(requestMessage.getTargetId(), message.getSourceId()) ||
        !Objects.equals(requestMessage.getSourceId(), message.getTargetId()))
        return;
      responseMessage = message;
      synchronized (receivedResponse) {
        receivedResponse.notifyAll();
      }
    }

    public void dispose() {
      api.deregisterListener(responseTypes, this);
    }

    public Message waitForResult(long timeoutMillis) throws CommunicationException {
      if (responseMessage == null) {
        try {
          synchronized (receivedResponse) {
            receivedResponse.wait(timeoutMillis);
          }
        } catch (InterruptedException e) {
          throw new CommunicationException("Timeout reached while waiting for reply.");
        }
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
   * @throws CommunicationException if communication with master fails
   */
  public static Message sendAndWait(GeigerApi api, Message message)
    throws CommunicationException {
    return sendAndWait(api, message, new MessageType[]{MessageType.COMAPI_SUCCESS});
  }

  /**
   * <p>Sends a message and waits for the first
   * returning message of a specific type with the same requestId.</p>
   *
   * @param api           GeigerAPI to communicate over.
   * @param message       Message to send.
   * @param responseTypes Possible message types of response message.
   * @return The response Message.
   * @throws CommunicationException if communication with master fails
   */
  public static Message sendAndWait(GeigerApi api, Message message, MessageType[] responseTypes)
    throws CommunicationException {
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
   * @throws CommunicationException if communication with master fails
   */
  public static Message sendAndWait(GeigerApi api, Message message,
                                    MessageType[] responseTypes, long timeoutMillis)
    throws CommunicationException {
    Listener listener = new Listener(api, message, responseTypes);
    api.sendMessage(message);
    Message result = listener.waitForResult(timeoutMillis);
    listener.dispose();
    return result;
  }


}
