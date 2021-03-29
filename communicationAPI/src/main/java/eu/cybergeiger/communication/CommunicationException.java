package eu.cybergeiger.communication;

import java.io.IOException;

/**
 * <p>Exception signalling wrong communication.</p>
 */
public class CommunicationException extends IOException {

  /**
   * <p>Standard exception constructor for including a causing exception.</p>
   *
   * @param txt the exception message
   * @param e   the root cause
   */
  public CommunicationException(String txt, Throwable e) {
    super(txt, e);
  }

  /**
   * <p>Standard exception constructor.</p>
   *
   * @param txt the exception message.
   */
  public CommunicationException(String txt) {
    this(txt, null);
  }
}
