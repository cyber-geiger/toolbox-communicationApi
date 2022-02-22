package eu.cybergeiger.communication

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

class GeigerService : Service() {
    private var engine: FlutterEngine? = null

    override fun onBind(intent: Intent): IBinder {
        engine = FlutterEngine(this)
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, arrayOf())
        engine!!.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        return Binder()
    }

    override fun onDestroy() {
        super.onDestroy()
        engine?.destroy()
    }
}
