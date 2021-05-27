package eu.cybergeiger.totalcross;

import java.io.IOException;
import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

/**
 * <p>A cross platform wrapper class for reading and writing byte streams.</p>
 */
public class File implements TcFile {

  private class TcWrapper implements TcFile {

    @Override
    public byte[] readAllBytes(String fname) throws IOException {
      try {
        Class cls = Class.forName("totalcross.io.File");
        int mode = cls.getField("READ_ONLY").getInt(cls);
        Object[] arglist = new Object[]{fname, mode};
        Class[] partypes = new Class[]{String.class, int.class};
        Constructor ct = cls.getConstructor(partypes);
        Object obj = (ct.newInstance(arglist));
        return (byte[]) (cls.getMethod("readAndClose").invoke(obj));
      } catch (InvocationTargetException | IllegalAccessException | InstantiationException
          | NoSuchMethodException | NoSuchFieldException | ClassNotFoundException e) {
        // FIXME insert proper logging/error handling (but should not be called)
        e.printStackTrace();
      }
      return null;
    }

    @Override
    public void writeAllBytes(String fname, byte[] buf) throws IOException {
      try {
        Class cls = Class.forName("totalcross.io.File");
        Class[] partypes = new Class[]{String.class, int.class};
        Constructor ct = cls.getConstructor(partypes);
        Object[] arglist = new Object[]{fname, cls.getField("CREATE_EMPTY")};
        Object obj = (ct.newInstance(arglist));
        cls.getMethod("writeAndClose", byte[].class).invoke(obj, buf);
      } catch (InvocationTargetException | IllegalAccessException | InstantiationException
          | NoSuchMethodException | NoSuchFieldException | ClassNotFoundException e) {
        // FIXME insert proper logging/error handling (but should not be called)
        e.printStackTrace();
      }
    }
  }

  private class JavaWrapper implements TcFile {

    @Override
    public byte[] readAllBytes(String fname) throws IOException {
      try {
        Object path = Class.forName("java.io.Paths").getMethod("get", String.class)
            .invoke(null, fname);
        Method ct = Class.forName("java.io.Files")
            .getMethod("readAllBytes", Class.forName("java.io.Path"));
        return (byte[]) (ct.invoke(null, path));
      } catch (Exception e) {
        // FIXME insert proper logging/error handling (but should not be called)
        e.printStackTrace();
      }
      return null;
    }

    @Override
    public void writeAllBytes(String fname, byte[] buf) throws IOException {
      try {
        Object path = Class.forName("java.io.Paths").getMethod("get", String.class)
            .invoke(null, fname);
        Method ct = Class.forName("java.io.Files")
            .getMethod("write", Class.forName("java.io.Path"), byte[].class);
        ct.invoke(null, path, buf);
      } catch (Exception e) {
        // FIXME insert proper logging/error handling (but should not be called)
        e.printStackTrace();
      }
    }

  }

  TcFile file;

  /**
   * Creates either a TotalCross-wrapper or a Java-wrapper.
   */
  public File() {
    if (isTotalCross()) {
      file = new File.TcWrapper();
    } else {
      file = new File.JavaWrapper();
    }
  }

  @Override
  public byte[] readAllBytes(String fname) throws IOException {
    return file.readAllBytes(fname);
  }

  @Override
  public void writeAllBytes(String fname, byte[] buf) throws IOException {
    file.writeAllBytes(fname, buf);
  }

  /**
   * Checks if it runs inside a TotalCross environment.
   *
   * @return true if it is a TotalCross environment, false otherwise
   */
  public static boolean isTotalCross() {
    try {
      Class.forName("totalcross.io.ByteArrayStream");
      return true;
    } catch (Exception e) {
      return false;
    }
  }


}
