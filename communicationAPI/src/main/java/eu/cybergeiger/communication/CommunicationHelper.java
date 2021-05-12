package eu.cybergeiger.communication;

public class CommunicationHelper {

  public static interface MessageFilter {
    boolean filter(Message msg);
  }

  private static class Listener implements PluginListener {

    private MessageFilter filter;
    private LocalApi api;
    private final Object obj = new Object();
    private Message msg = null;


    public Listener(LocalApi api, MessageFilter filter) {
      if(api==null) {
        throw new NullPointerException("api may not be null");
      }
      if(filter==null) {
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

    public void dispose() {
      api.deregisterListener(new MessageType[]{MessageType.ALL_EVENTS}, this);
    }

    public Message waitForResult() {
      while(msg != null) {
        try{
          synchronized (obj) {
            obj.wait(100);
          }
        } catch (InterruptedException e) {
          //safe to ignore
        }
      }
      return msg;
    }
  }

  public static Message sendAndWait(LocalApi api, Message msg, MessageFilter filter) {
    Listener l = new Listener(api, filter);
    api.sendMessage(msg.getTargetId(),msg);
    Message result = l.waitForResult();
    l.dispose();
    return result;
  }



}
