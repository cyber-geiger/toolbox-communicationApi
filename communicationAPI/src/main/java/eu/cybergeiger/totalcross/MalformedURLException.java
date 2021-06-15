package eu.cybergeiger.totalcross;

import java.io.IOException;

/**
 * Exception class to denote a malformed URL.
 */
public class MalformedURLException extends IOException {

  public MalformedURLException(String msg)  {
    super(msg);
  }

  public MalformedURLException(String msg, Exception e)  {
    super(msg, e);
  }

}
