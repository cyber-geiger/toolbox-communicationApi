package eu.cybergeiger.communication;

import android.app.Service;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Binder;
import android.os.IBinder;
import android.util.Log;

import androidx.annotation.Nullable;

import java.io.IOException;
import java.util.concurrent.ExecutionException;

import eu.cybergeiger.api.GeigerApi;
import eu.cybergeiger.api.PluginApi;
import eu.cybergeiger.api.plugin.Declaration;

public class GeigerService extends Service {
    static final String PLUGIN_ID = "java-plugin";
    private static final String PLUGIN_EXECUTOR = "com.example.master_app;" +
            "com.example.master_app.MainActivity;" +
            "TODO";

    private static PluginApi plugin;
    private static Thread startThread;

    public static void startPlugin() {
        if (startThread != null) return;
        startThread = new Thread(() -> {
            try {
                plugin = new PluginApi(
                        PLUGIN_EXECUTOR,
                        PLUGIN_ID,
                        Declaration.DO_NOT_SHARE_DATA
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
        startPlugin();
        return new Binder();
    }
}
