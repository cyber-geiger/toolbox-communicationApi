package eu.cybergeiger.totalcross;

import java.io.IOException;

/**
 * Exception class to denote a malformed URL.
 */
public class MalformedUrlException extends IOException {

  public MalformedUrlException(String msg)  {
    super(msg);
  }

  public MalformedUrlException(String msg, Exception e)  {
    super(msg, e);
  }

}
