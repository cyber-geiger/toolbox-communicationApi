package eu.cybergeiger.communication

import android.app.Service
import android.content.Intent
import android.os.*
import android.util.Log

import io.flutter.FlutterInjector;

class GeigerService : Service() {

    override fun onBind(intent: Intent): IBinder {
        Log.i("GeigerService", "service was bound");
        return Binder();
    }
}
