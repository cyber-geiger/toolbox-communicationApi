package eu.cybergeiger.communication;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Binder;
import android.os.IBinder;

import androidx.annotation.Nullable;

import java.io.IOException;

import eu.cybergeiger.api.GeigerApi;
import eu.cybergeiger.api.PluginApi;
import eu.cybergeiger.api.plugin.Declaration;
import eu.cybergeiger.api.plugin.PluginStarter;

public class GeigerService extends Service {
    static final String PLUGIN_ID = "java-plugin";
    static final String PLUGIN_EXECUTOR = "com.example.client;" +
            "com.example.client.MainActivity;" +
            "TODO";
    static final String MASTER_EXECUTOR = "com.example.master_app;" +
            "com.example.master_app.MainActivity;" +
            "TODO";

    private static PluginApi plugin;
    private static Thread startThread;

    public static void startPlugin(Context context) {
        if (startThread != null) return;
        PluginStarter.setContext(context);
        startThread = new Thread(() -> {
            try {
                plugin = new PluginApi(
                        PLUGIN_EXECUTOR,
                        PLUGIN_ID,
                        Declaration.DO_NOT_SHARE_DATA,
                        MASTER_EXECUTOR,
                        false,
                        false
                );
            } catch (IOException e) {
                throw new RuntimeException("Failed to initialize plugin.", e);
            }
        });
        startThread.start();
    }

    public static GeigerApi getPlugin() {
        if (plugin == null)
            try {
                startThread.join();
            } catch (InterruptedException e) {
                throw new RuntimeException("Waiting for plugin to start was interrupted.", e);
            }
        return plugin;
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        startPlugin(getApplicationContext());
        return new Binder();
    }
}
