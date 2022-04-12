package mocks;

import eu.cybergeiger.api.message.GeigerUrl;
import eu.cybergeiger.api.message.Message;
import eu.cybergeiger.api.plugin.PluginListener;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * A Pluginlistener for test purposes that allows to get all messages received.
 */
public class SimpleEventListener implements PluginListener {

  final CopyOnWriteArrayList<Message> events;

  public SimpleEventListener() {
    this.events = new CopyOnWriteArrayList<>();
  }

  @Override
  public synchronized void pluginEvent(Message msg) {
    synchronized (events) {
      events.add(msg);
    }
    System.out.println("## SimpleEventListener received event " + msg.getType() + " it currently has: " + events.size() + " events");
  }

  public List<Message> getEvents() {
    return events;
  }

}
