package eu.cybergeiger.totalcross;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

public class Base64 {

  public static String encodeToString(byte[] arr) {
    try {
      if (Detector.isTotalCross()) {
        Class cls = Class.forName("totalcross.net.Base64");
        Method m = cls.getMethod("encode", new Class[]{byte[].class});
        return (String) (m.invoke(null, new Object[]{arr}));
      } else {
        Class cls = Class.forName("java.util.Base64");
        Method m = cls.getMethod("getEndcoder");
        Object encoder = m.invoke(null);
        m = encoder.getClass().getMethod("encodeToString", new Class[]{byte[].class});
        return (String) (m.invoke(null, new Object[]{arr}));
      }
    } catch (InvocationTargetException | IllegalAccessException | NoSuchMethodException | ClassNotFoundException e) {
      throw new RuntimeException("OOPS! That is bad", e);
    }
  }

  public static byte[] decode(String inStr) {
    try {
      if (Detector.isTotalCross()) {
        // FIXME implementation error in Base64 encoder of totalcross.
        //  Fails with an out of bound exception if inStr is ""
        if(inStr==null || "".equals(inStr)) {
          return new byte[0];
        }
        Class cls = Class.forName("totalcross.net.Base64");
        Method m = cls.getMethod("decode", new Class[]{inStr.getClass()});
        return (byte[]) (m.invoke(null, new Object[]{inStr}));
      } else {
        Class cls = Class.forName("java.util.Base64");
        Method m = cls.getMethod("getDecoder");
        Object decoder = m.invoke(null);
        m = decoder.getClass().getMethod("decode", new Class[]{String.class});
        return (byte[]) (m.invoke(null, new Object[]{inStr}));
      }
    } catch (InvocationTargetException | IllegalAccessException | NoSuchMethodException | ClassNotFoundException e) {
      throw new RuntimeException("OOPS! That is bad", e);
    }
  }
}
