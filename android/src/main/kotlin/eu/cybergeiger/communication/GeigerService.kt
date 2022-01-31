package eu.cybergeiger.communication.geiger_api

import android.app.Service
import android.content.Intent
import android.os.*

import io.flutter.FlutterInjector;

class GeigerService : Service() {

    override fun onCreate() {
        super.onCreate()
        if (GeigerPlugin.flutterEngine != null) return;
        FlutterInjector.instance().flutterLoader().startInitialization(this);
    }

    override fun onBind(intent: Intent): IBinder {
        return Binder();
    }
}
