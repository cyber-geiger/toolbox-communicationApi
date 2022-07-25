package mocks;

import eu.cybergeiger.api.message.Message;
import eu.cybergeiger.api.plugin.PluginListener;

import java.util.*;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

/**
 * A Pluginlistener for test purposes that allows to get all messages received.
 */
public class MessageCollector implements PluginListener {
  final CopyOnWriteArrayList<Message> events = new CopyOnWriteArrayList<>();
  private final Set<CountDownLatch> listeners = new HashSet<>();

  public List<Message> getEvents() {
    return events;
  }

  @Override
  public void pluginEvent(Message msg) {
    synchronized (events) {
      synchronized (listeners) {
        events.add(msg);
        for (CountDownLatch listener : listeners)
          listener.countDown();
      }
    }
  }

  public void awaitCount(int count) throws TimeoutException, InterruptedException {
    awaitCount(count, 30000);
  }

  public void awaitCount(int count, long msTimeout) throws TimeoutException, InterruptedException {
    if (events.size() >= count) return;
    CountDownLatch listener = new CountDownLatch(count);
    synchronized (listeners) {
      listeners.add(listener);
    }
    try {
      if (!listener.await(msTimeout, TimeUnit.MILLISECONDS))
        throw new TimeoutException("Did not receive enough messages before timeout.");
    } finally {
      synchronized (listeners) {
        listeners.remove(listener);
      }
    }
  }
}
