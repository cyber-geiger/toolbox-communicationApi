package eu.cybergeiger.communication

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result


class GeigerPlugin : FlutterPlugin, MethodCallHandler {
    companion object {
        private const val CHANNEL = "cyber-geiger.eu/communication";
        private const val SERVICE_NAME = "eu.cybergeiger.communication.GeigerService";
    }

    private lateinit var context: Context
    private lateinit var channel: MethodChannel

    private var connections = HashMap<String, NoOpConnection>()

    internal class NoOpConnection : ServiceConnection {
        override fun onServiceConnected(className: ComponentName, service: IBinder) {}
        override fun onServiceDisconnected(className: ComponentName) {}
    }

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        val packageName = call.argument<String>("package")!!
        val inBackground = call.argument<Boolean>("inBackground")!!
        val componentName =
            if (inBackground) SERVICE_NAME
            else call.argument<String>("component")!!
        val intent = Intent().also {
            it.component = ComponentName(packageName, componentName)
        }
        if (inBackground) {
            val connectionId = "${intent.`package`} ${intent.component}"
            if (connections[connectionId] == null) {
                val connection = NoOpConnection()
                val wasSuccessful =
                    context.bindService(intent, connection, Context.BIND_AUTO_CREATE)
                if (!wasSuccessful) {
                    result.error(
                        "BindFail",
                        "Failed to bind service.",
                        ""
                    )
                    return
                }
                connections[connectionId] = connection
            }
        } else {
            context.applicationContext.startActivity(intent);
        }
        result.success(null)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        for (connection in connections.values)
            context.unbindService(connection)
    }
}
