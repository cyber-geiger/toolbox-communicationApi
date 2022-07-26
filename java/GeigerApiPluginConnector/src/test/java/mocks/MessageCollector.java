package mocks;

import eu.cybergeiger.api.GeigerApi;
import eu.cybergeiger.api.message.Message;
import eu.cybergeiger.api.message.MessageType;
import eu.cybergeiger.api.plugin.PluginListener;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

/**
 * A PluginListener that collects all messages it receives.
 */
public class MessageCollector implements PluginListener {
  public static long DEFAULT_TIMEOUT = 30000;

  final ArrayList<Message> messages = new ArrayList<>();
  private final Set<CountDownLatch> listeners = new HashSet<>();

  public MessageCollector(GeigerApi api){
    api.registerListener(MessageType.getAllTypes(), this);
  }

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
    awaitCount(count, DEFAULT_TIMEOUT);
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

  public Message awaitMessage(int index) throws TimeoutException, InterruptedException {
    return awaitMessage(index, DEFAULT_TIMEOUT);
  }

  public Message awaitMessage(int index, long msTimeout) throws TimeoutException, InterruptedException {
    awaitCount(index+1, msTimeout);
    return getMessages().get(index);
  }
}
