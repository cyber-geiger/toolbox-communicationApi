package eu.cybergeiger.communication;

//import java.util.concurrent.TimeoutException;

import java.io.IOException;

/**
 * A helper class for sending and waiting on Messages.
 * TODO should this only be used for Testing?
 */
public class CommunicationHelper {

  /**
   * Interface to denote a MessageFilter.
   */
  public static interface MessageFilter {
    boolean filter(Message msg);
  }

  private static class Listener implements PluginListener {

    private MessageFilter filter;
    private LocalApi api;
    private final Object obj = new Object();
    private Message msg = null;


    public Listener(LocalApi api, MessageFilter filter) {
      if (api == null) {
        throw new NullPointerException("api may not be null");
      }
      if (filter == null) {
        throw new NullPointerException("message filter may not be null");
      }
      this.filter = filter;
      this.api = api;
      this.api.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, this);
    }

    @Override
    public void pluginEvent(GeigerUrl url, Message msg) {
      if (filter.filter(msg)) {
        this.msg = msg;
        synchronized (obj) {
          obj.notifyAll();
        }
      }
    }

    @Override
    public byte[] toByteArray() {
      // TODO
      return new byte[0];
    }

    public void dispose() {
      api.deregisterListener(new MessageType[]{MessageType.ALL_EVENTS}, this);
    }

    public Message waitForResult(long timeout) throws IOException {
      //long starttime = (new Time()).getTime();
      long starttime = ch.fhnw.geiger.totalcross.System.currentTimeMillis();
      while (msg == null && (timeout < 0
          || (ch.fhnw.geiger.totalcross.System.currentTimeMillis() - starttime < timeout))) {
        try {
          synchronized (obj) {
            obj.wait(100);
          }
        } catch (InterruptedException e) {
          //safe to ignore
        }
      }
      if (msg == null) {
        throw new IOException("timeout reached");
      }
      return msg;
    }
  }

  /**
   * <p>Sends a message and waits for the first message matching the provided message filter.</p>
   *
   * @param api    the API to be used as communication endpoint
   * @param msg    the message to be sent
   * @param filter the filter matching the expected reply
   * @return the response Message
   */
  public static Message sendAndWait(LocalApi api, Message msg, MessageFilter filter)
      throws IOException {
    return sendAndWait(api, msg, filter, 10000);
  }

  /**
   * <p>Sends a message and waits for the first message matching the provided message filter.</p>
   *
   * @param api     the API to be used as communication endpoint
   * @param msg     the message to be sent
   * @param filter  the filter matching the expected reply
   * @param timeout the timeout in miliseconds (-1 for infinite)
   * @return the response Message
   */
  public static Message sendAndWait(LocalApi api, Message msg, MessageFilter filter, long timeout)
      throws IOException {
    Listener l = new Listener(api, filter);
    api.sendMessage(msg.getTargetId(), msg);
    Message result = l.waitForResult(timeout);
    l.dispose();
    return result;
  }


}
