
import 'java.dart';
/// <p>Represents a menu item for a list of items.</p>
/// . * FIXME: Menu texts are not internationalizable
class MenuItem with ch_fhnw_geiger_serialization_Serializer
{
    static const int serialVersionUID = 481231212;
    final String menu;
    final GeigerUrl action;
    bool enabled;
    /// <p>Creates a new,enabled menu item and assigns an action URL.</p>
    /// @param menu   the menu name
    /// @param action the action url
    MenuItem(String menu, GeigerUrl action)
    {
        this(menu, action, true);
    }

    /// <p>Creates a new menu item and assigns an action URL.</p>
    /// @param menu    the menu name
    /// @param action  the action url
    /// @param enabled is the menu entry currently enabled
    MenuItem(String menu, GeigerUrl action, bool enabled)
    {
        if ((menu == null) || ("" == menu)) {
            throw new IllegalArgumentException("menu may not be null nor empty");
        }
        if (action == null) {
            throw new IllegalArgumentException("action may not be null");
        }
        this.menu = menu;
        this.action = action;
        this.enabled = enabled;
    }

    /// <p>Returns the menu string.</p>
    /// @return the menu string
    String getMenu()
    {
        return this.menu;
    }

    /// <p>Returns the action URL.</p>
    /// @return the action url
    GeigerUrl getAction()
    {
        return this.action;
    }

    /// <p>Returns the menu state.</p>
    /// @return true if the menu entry is currently enabled
    bool isEnabled()
    {
        return this.enabled;
    }

    /// <p>Enables or disables the menu entry.</p>
    /// @param enabled the new state of the menu entry
    /// @return the previously set state
    bool setEnabled(bool enabled)
    {
        bool old = this.enabled;
        this.enabled = enabled;
        return old;
    }

    void toByteArrayStream(ch_fhnw_geiger_totalcross_ByteArrayOutputStream out)
    {
        SerializerHelper.writeLong(out, serialVersionUID);
        SerializerHelper.writeString(out, menu);
        action.toByteArrayStream(out);
        SerializerHelper.writeInt(out, enabled ? 1 : 0);
        SerializerHelper.writeLong(out, serialVersionUID);
    }

    /// <p>Reads objects from ByteArrayInputStream and stores them in map.</p>
    /// @param in ByteArrayInputStream to be used
    /// @return the deserialized Storable String
    /// @throws IOException if value cannot be read
    static MenuItem fromByteArrayStream(ch_fhnw_geiger_totalcross_ByteArrayInputStream in_)
    {
        if (SerializerHelper.readLong(in_) != serialVersionUID) {
            throw new ClassCastException();
        }
        String menu = SerializerHelper.readString(in_);
        GeigerUrl url = GeigerUrl_.fromByteArrayStream(in_);
        bool enabled = (SerializerHelper.readInt(in_) == 1);
        if (SerializerHelper.readLong(in_) != serialVersionUID) {
            throw new ClassCastException();
        }
        return new MenuItem(menu, url, enabled);
    }

    String toString()
    {
        return ((((('"'.codeUnitAt(0) + menu) + "\"->") + action) + "(") + (enabled ? "enabled" : "disabled")) + ")";
    }

    bool equals(Object o)
    {
        if (this == o) {
            return true;
        }
        if ((o == null) || (getClass() != o.getClass())) {
            return false;
        }
        MenuItem menuItem = o;
        return ((enabled == menuItem.enabled) && Objects.equals(menu, menuItem.menu)) && Objects.equals(action, menuItem.action);
    }

    int hashCode()
    {
        return Objects.hash(menu, action, enabled);
    }

    /// <p>Wrapper function to simplify serialization.</p>
    /// @return the serializer object as byte array
    List<int> toByteArray()
    {
        try {
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream out = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
            toByteArrayStream(out);
            return out.toByteArray();
        } on java_io_IOException catch (e) {
            return null;
        }
    }

    /// <p>Wrapper function to simplify deserialization.</p>
    /// @param buf the buffer to be read
    /// @return the deserialized object
    static MenuItem fromByteArray(List<int> buf)
    {
        try {
            ch_fhnw_geiger_totalcross_ByteArrayInputStream in_ = new ch_fhnw_geiger_totalcross_ByteArrayInputStream(buf);
            return fromByteArrayStream(in_);
        } on java_io_IOException catch (ioe) {
            ioe.printStackTrace();
            return null;
        }
    }

}
