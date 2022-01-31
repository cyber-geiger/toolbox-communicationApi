package eu.cybergeiger.communication.geiger_api

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class GeigerPlugin : FlutterPlugin, MethodCallHandler {
    companion object {
        var flutterEngine: FlutterEngine? = null;
    }

    private lateinit var context: Context;
    private lateinit var channel: MethodChannel;

    private var connections = HashMap<String, NoOpConnection>()

    internal class NoOpConnection : ServiceConnection {
        override fun onServiceConnected(className: ComponentName, service: IBinder) {}
        override fun onServiceDisconnected(className: ComponentName) {}
    }

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.getApplicationContext();
        channel = MethodChannel(
            binding.binaryMessenger,
            "cyber-geiger.eu/communication"
        )
        channel.setMethodCallHandler(this)
        flutterEngine = binding.getFlutterEngine();
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        val packageName = call.argument<String>("package")!!;
        val componentName = call.argument<String>("component")!!;
        val intent = Intent().also {
            it.`package` = packageName;
            it.component = ComponentName(packageName, componentName);
        }
        val inBackground = call.argument<Boolean>("inBackground")!!
        if (inBackground) {
            val connectionId = "${intent.`package`} ${intent.component}"
            var connection = connections[connectionId]
            if (connection != null) return
            connection = NoOpConnection()
            connections[connectionId] = connection
            context.bindService(intent, connection, Context.BIND_AUTO_CREATE)
        }
        result.success(null)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        flutterEngine = null;
        channel.setMethodCallHandler(null)
        for (connection in connections.values)
            context.unbindService(connection)
    }
}
