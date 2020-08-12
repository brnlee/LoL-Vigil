package brnlee.lolvigilmobile

import android.app.NotificationChannel
import android.app.NotificationManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    private val CHANNEL = "brnlee.lolvigilmobile/alarmScreen"
    private val CHANNEL_ID = "someChannelID"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            // Note: this method is invoked on the main thread.
            call, result ->
            if (call.method == "getBatteryLevel") {
                val batteryLevel = getBatteryLevel()

                if (batteryLevel != -1) {
                    result.success(batteryLevel)
                } else {
                    result.error("UNAVAILABLE", "Battery level not available.", null)
                }
                createNotificationChannel()
                val builder = NotificationCompat.Builder(this, CHANNEL_ID)
                        .setSmallIcon(R.drawable.common_google_signin_btn_icon_dark)
                        .setContentTitle("title")
                        .setContentText("content")
                        .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                with(NotificationManagerCompat.from(this)) {
                    // notificationId is a unique int for each notification that you must define
                    notify(123213, builder.build())
                }
                print("Intent stuff")
//                intent = Intent(this, AlarmActivity::class.java)
//                startActivity(intent)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun createNotificationChannel() {
        // Create the NotificationChannel, but only on API 26+ because
        // the NotificationChannel class is new and not in the support library
        if (VERSION.SDK_INT >= VERSION_CODES.O) {
            val name = "channelName"
            val descriptionText = "channelDescription"
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            // Register the channel with the system
            val notificationManager: NotificationManager =
                    getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun getBatteryLevel(): Int {
        val batteryLevel: Int
        if (VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } else {
            val intent = ContextWrapper(applicationContext).registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            batteryLevel = intent!!.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100 / intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        }

        return batteryLevel
    }
}