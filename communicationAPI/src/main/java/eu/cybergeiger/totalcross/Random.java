package eu.cybergeiger.totalcross;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

public class Random {

  private static Class rcls = null;
  private static Object robj = null;


  public static int nextInt(int border) {
    try {
      if (robj == null) {
        if (Detector.isTotalCross()) {
          rcls = Class.forName("totalcross.util.Random");
        } else {
          rcls = Class.forName("java.util.Random");
        }
        Constructor ct = rcls.getConstructor(new Class[0]);
        robj = (ct.newInstance(new Object[0]));
      }
      Method m = rcls.getMethod("nextInt", new Class[]{int.class});
      return (int) (m.invoke(robj, new Object[]{border}));
    } catch (ClassNotFoundException | NoSuchMethodException | IllegalAccessException | InvocationTargetException | InstantiationException e) {
      throw new RuntimeException("OOPS! That is bad", e);
    }
  }

}
