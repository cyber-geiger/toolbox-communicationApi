package eu.cybergeiger.storage.utils;

/**
 * <p>A boolean valuable offering atomic toggling.</p>
 */
public class SwitchableBoolean {

  private final Object semaphore = new Object();

  private boolean value;

  public SwitchableBoolean(boolean value) {
    this.value = value;
  }

  /**
   * <p>sets the value of the boolean.</p>
   *
   * @param newValue the new value to be set
   * @return the previously set value
   */
  public boolean set(boolean newValue) {
    boolean ret;
    synchronized (semaphore) {
      ret = get();
      value = newValue;
    }
    return ret;
  }

  /**
   * <p>gets the currently set value.</p>
   *
   * @return the currently set value
   */
  public boolean get() {
    synchronized (semaphore) {
      return value;
    }
  }

  /**
   * <p>Toggles the currently set value.</p>
   *
   * @return the previously set value
   */
  public boolean toggle() {
    boolean ret;
    synchronized (semaphore) {
      ret = get();
      value = !ret;
    }
    return ret;
  }

}
