package mocks;

import eu.cybergeiger.api.message.Message;
import eu.cybergeiger.api.plugin.PluginListener;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

/**
 * A Pluginlistener for test purposes that allows to get all messages received.
 */
public class MessageCollector implements PluginListener {
  final ArrayList<Message> messages = new ArrayList<>();
  private final Set<CountDownLatch> listeners = new HashSet<>();

  public List<Message> getMessages() {
    return messages;
  }

  @Override
  public void pluginEvent(Message msg) {
    synchronized (messages) {
      synchronized (listeners) {
        messages.add(msg);
        for (CountDownLatch listener : listeners)
          listener.countDown();
      }
    }
  }

  public void awaitCount(int count) throws TimeoutException, InterruptedException {
    awaitCount(count, 30000);
  }

  public void awaitCount(int count, long msTimeout) throws TimeoutException, InterruptedException {
    int remaining = count - messages.size();
    if (remaining <= 0) return;
    CountDownLatch listener = new CountDownLatch(remaining);
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
