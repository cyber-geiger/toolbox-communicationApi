package eu.cybergeiger.communication

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result


class GeigerPlugin : FlutterPlugin, MethodCallHandler {
    companion object {
        var flutterEngine: FlutterEngine? = null
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
        channel = MethodChannel(
            binding.binaryMessenger,
            "cyber-geiger.eu/communication"
        )
        channel.setMethodCallHandler(this)
        flutterEngine = binding.flutterEngine
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        val packageName = call.argument<String>("package")!!
        val componentName = call.argument<String>("component")!!
        val intent = Intent().also {
            it.component = ComponentName(packageName, componentName)
        }
        val inBackground = call.argument<Boolean>("inBackground")!!
        if (inBackground) {
            val connectionId = "${intent.`package`} ${intent.component}"
            var connection = connections[connectionId]
            if (connection != null) return
            connection = NoOpConnection()
            connections[connectionId] = connection
            val wasSuccessful = context.bindService(intent, connection, Context.BIND_AUTO_CREATE)
            if (wasSuccessful) result.success(null)
            else result.error("BindFail", "Failed to bind service.", "")
        }

    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        flutterEngine = null
        channel.setMethodCallHandler(null)
        for (connection in connections.values)
            context.unbindService(connection)
    }
}
