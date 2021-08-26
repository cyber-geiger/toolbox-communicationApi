package mocks;

import eu.cybergeiger.communication.GeigerUrl;
import eu.cybergeiger.communication.Message;
import eu.cybergeiger.communication.PluginListener;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * A Pluginlistener for test purposes that allows to get all messages received.
 */
public class SimpleEventListener implements PluginListener {

  CopyOnWriteArrayList<Message> events;

  public SimpleEventListener() {
    this.events = new CopyOnWriteArrayList<>();
  }

  @Override
  public synchronized void pluginEvent(GeigerUrl url, Message msg) {
    synchronized (events) {
      events.add(msg);
    }
    System.out.println("## SimpleEventListener received event " + msg.getType() + " it currently has: " + events.size() + " events");
  }

  public List<Message> getEvents() {
    return events;
  }

}
