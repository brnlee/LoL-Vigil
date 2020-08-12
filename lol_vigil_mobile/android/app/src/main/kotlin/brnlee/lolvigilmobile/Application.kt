package brnlee.lolvigilmobile

import com.tekartik.sqflite.SqflitePlugin
import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback
import io.flutter.plugins.androidintent.AndroidIntentPlugin
import io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin
import io.flutter.plugins.firebasemessaging.FlutterFirebaseMessagingService
import io.flutter.plugins.pathprovider.PathProviderPlugin

class Application : FlutterApplication(), PluginRegistrantCallback {
    override fun onCreate() {
        super.onCreate()
        FlutterFirebaseMessagingService.setPluginRegistrant(this)
    }

    override fun registerWith(registry: PluginRegistry?) {
        FirebaseMessagingPlugin.registerWith(registry?.registrarFor("io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin"))
        AndroidIntentPlugin.registerWith(registry?.registrarFor("io.flutter.plugins.androidintent.AndroidIntentPlugin"))
        PathProviderPlugin.registerWith(registry?.registrarFor("io.flutter.plugins.pathprovider.PathProviderPlugin"))
        SqflitePlugin.registerWith(registry?.registrarFor("com.tekartik.sqflite.SqflitePlugin"))
    }

}