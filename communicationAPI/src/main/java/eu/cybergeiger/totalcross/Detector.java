package eu.cybergeiger.totalcross;

public class Detector {
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
