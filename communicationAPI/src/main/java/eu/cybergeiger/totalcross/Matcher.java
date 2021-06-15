package eu.cybergeiger.totalcross;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

/**
 * Wrapper class to work with java and totalcross Matcher class.
 */
public class Matcher implements TcMatcher {

  private final IntMatcher matcher;
  private final String pattern;
  private final String string;

  interface IntMatcher {

    boolean matches();

    String group(int num);

  }

  private abstract static class AbstractWrapper implements IntMatcher {

    Class mcls = null;
    Object mobj = null;

    @Override
    public boolean matches() {
      try {
        Method m = mcls.getMethod("matches", new Class[]{});
        return (boolean) (m.invoke(mobj, new Object[]{}));
      } catch (InvocationTargetException | NoSuchMethodException | IllegalAccessException e) {
        throw new RuntimeException("OOBS! That is bad (" + mcls + "/" + mobj + ")", e);
      }
    }

    @Override
    public String group(int num) {
      try {
        Method m = mcls.getMethod("group", new Class[]{int.class});
        return (String) (m.invoke(mobj, new Object[]{num}));
      } catch (InvocationTargetException | NoSuchMethodException | IllegalAccessException e) {
        throw new RuntimeException("OOBS! That is bad", e);
      }
    }

  }

  private static class JavaWrapper extends AbstractWrapper {

    public JavaWrapper(String pattern, String s) {
      try {
        Class pcls = Class.forName("java.util.regex.Pattern");
        this.mcls = Class.forName("java.util.regex.Matcher");
        Method m = pcls.getMethod("compile", new Class[]{String.class});
        mobj = (m.invoke(null, new Object[]{pattern}));
        m = pcls.getMethod("matcher", new Class[]{String.class});
        mobj = m.invoke(mobj, new Object[]{s});
      } catch (ClassNotFoundException | InvocationTargetException
          | NoSuchMethodException | IllegalAccessException e) {
        throw new RuntimeException("OOPS! That is bad", e);
      }
    }

  }

  private static class TotalCrossWrapper extends AbstractWrapper {

    public TotalCrossWrapper(String pattern, String s) {
      super();
      try {
        Class pcls = Class.forName("totalcross.util.regex.Pattern");
        this.mcls = Class.forName("totalcross.util.regex.Matcher");
        // compile regex
        Method m = pcls.getMethod("compile", new Class[]{String.class});
        Object pobj = (m.invoke(null, new Object[]{pattern}));
        // get the matcher
        m = pcls.getMethod("matcher", new Class[]{});
        mobj = (m.invoke(pobj, new Object[]{}));
        // set the target string
        m = mcls.getMethod("setTarget", new Class[]{String.class});
        m.invoke(mobj, new Object[]{s});
        // do the matching
        m = mcls.getMethod("matches", new Class[]{});
        m.invoke(mobj, new Object[]{});
      } catch (ClassNotFoundException | InvocationTargetException
          | NoSuchMethodException | IllegalAccessException e) {
        throw new RuntimeException("OOPS! That is bad", e);
      }
    }

  }

  private Matcher(String pattern) {
    this.matcher = null;
    this.pattern = pattern;
    this.string = null;
  }

  private Matcher(String pattern, String s) {
    this.matcher = Detector.isTotalCross() ? new TotalCrossWrapper(pattern, s)
        : new JavaWrapper(pattern, s);
    this.pattern = pattern;
    this.string = s;
  }

  public static Matcher compile(String pattern) {
    return new Matcher(pattern);
  }

  @Override
  public Matcher matcher(String s) {
    return new Matcher(pattern, s);
  }

  @Override
  public boolean matches() {
    return this.string == null && this.matcher != null ? false : matcher.matches();
  }

  @Override
  public String group(int num) {
    return this.string == null && this.matcher != null ? null : matcher.group(num);
  }

  @Override
  public String pattern() {
    return this.pattern;
  }

}
