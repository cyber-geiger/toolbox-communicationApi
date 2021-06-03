package eu.cybergeiger.communication;

import java.util.ArrayList;

public class MockListener implements PluginListener {

  ArrayList<Message> events;

  public MockListener() {
    this.events = new ArrayList<>();
  }

  @Override
  public void pluginEvent(GeigerUrl url, Message msg) {
    events.add(msg);
  }

  public ArrayList<Message> getEvents() {
    return new ArrayList<>(events);
  }
}
