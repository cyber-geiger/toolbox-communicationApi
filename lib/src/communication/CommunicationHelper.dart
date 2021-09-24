
import 'java.dart';
/// A helper class for sending and waiting on Messages.
/// TODO should this only be used for Testing?
class CommunicationHelper
{
    /// Interface to denote a MessageFilter.
    /// public interface MessageFilter {
    /// boolean filter(Message msg);
    /// }
    /// private static class Listener implements PluginListener {
    /// private final MessageFilter filter;
    /// private final LocalApi api;
    /// private final Object obj = new Object();
    /// private Message msg = null;
    /// public Listener(LocalApi api, MessageFilter filter) {
    /// if (api == null) {
    /// throw new NullPointerException("api may not be null");
    /// }
    /// if (filter == null) {
    /// throw new NullPointerException("message filter may not be null");
    /// }
    /// this.filter = filter;
    /// this.api = api;
    /// this.api.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, this);
    /// }
    /// public void pluginEvent(GeigerUrl url, Message msg) {
    /// if (filter.filter(msg)) {
    /// this.msg = msg;
    /// synchronized (obj) {
    /// obj.notifyAll();
    /// }
    /// }
    /// }
    /// public void dispose() {
    /// api.deregisterListener(new MessageType[]{MessageType.ALL_EVENTS}, this);
    /// }
    /// public Message waitForResult(long timeout) throws CommunicationException {
    /// long startTime = System.currentTimeMillis();
    /// while (msg == null && (timeout < 0
    /// || (ch.fhnw.geiger.totalcross.System.currentTimeMillis() - startTime < timeout))) {
    /// try {
    /// synchronized (obj) {
    /// obj.wait(100);
    /// }
    /// } catch (InterruptedException e) {
    /// //
    /// safe to ignore
    /// }
    /// }
    /// if (msg == null) {
    /// throw new CommunicationException("timeout reached");
    /// }
    /// return msg;
    /// }
    /// }
    /// <p>Sends a message and waits for the first message matching the provided message filter.</p>
    /// @param api    the API to be used as communication endpoint
    /// @param msg    the message to be sent
    /// @param filter the filter matching the expected reply
    /// @return the response Message
    /// @throws CommunicationException if communication with master fails
    static Message sendAndWait(LocalApi api, Message msg, MessageFilter filter)
    {
        return sendAndWait(api, msg, filter, 10000);
    }

    /// <p>Sends a message and waits for the first message matching the provided message filter.</p>
    /// @param api     the API to be used as communication endpoint
    /// @param msg     the message to be sent
    /// @param filter  the filter matching the expected reply
    /// @param timeout the timeout in milliseconds (-1 for infinite)
    /// @return the response Message
    /// @throws CommunicationException if communication with master fails
    static Message sendAndWait(LocalApi api, Message msg, MessageFilter filter, int timeout)
    {
        Listener l = new Listener(api, filter);
        api.sendMessage(msg.getTargetId(), msg);
        Message result = l.waitForResult(timeout);
        l.dispose();
        return result;
    }

}