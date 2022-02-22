package eu.cybergeiger.communication

import android.app.Service
import android.content.Intent
import android.os.*
import android.util.Log

import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.embedding.engine.plugins.util.GeneratedPluginRegister

class GeigerService : Service() {
    var engine: FlutterEngine? = null

    override fun onBind(intent: Intent): IBinder {
        engine = FlutterEngine(this)
        val loader = FlutterInjector.instance().flutterLoader();
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, arrayOf())
        engine!!.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        return Binder();
    }
}
