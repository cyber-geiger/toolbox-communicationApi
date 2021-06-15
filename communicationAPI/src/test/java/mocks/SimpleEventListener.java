package mocks;

import eu.cybergeiger.communication.GeigerUrl;
import eu.cybergeiger.communication.Message;
import eu.cybergeiger.communication.PluginListener;

import java.util.ArrayList;

public class SimpleEventListener implements PluginListener {

  ArrayList<Message> events;

  public SimpleEventListener() {
    this.events = new ArrayList<>();
  }

  @Override
  public void pluginEvent(GeigerUrl url, Message msg) {
    events.add(msg);
  }

  @Override
  public byte[] toByteArray() {
    // TODO
    return new byte[0];
  }

  public ArrayList<Message> getEvents() {
    return new ArrayList<>(events);
  }
}
