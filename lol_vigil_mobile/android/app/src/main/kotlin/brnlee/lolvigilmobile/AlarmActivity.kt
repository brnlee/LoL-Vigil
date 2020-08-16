package brnlee.lolvigilmobile

import android.app.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.Log
import java.util.concurrent.atomic.AtomicInteger


class AlarmActivity : Activity() {
    companion object {
        const val CHANNEL_ID = "lolVigil"
        private var notificationID = AtomicInteger(0)
        private var listener: AlarmActivity? = null

        private var ringtone: Ringtone? = null
        private var notificationBuilder: NotificationCompat.Builder? = null
        private var notificationTitle: String? = null

        fun getNotificationID(): Int {
            return notificationID.incrementAndGet()
        }

        fun clearVariables() {
            ringtone?.stop()
            ringtone = null
            notificationBuilder = null
            notificationTitle = null

            listener?.finishAndRemoveTask()
            listener = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        Log.d("tag", "Matchup: ${intent.getStringExtra("matchup")}")
        Log.d("", "Trigger: ${intent.getStringExtra("trigger")}")

        init(intent)

        val alarmURI = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
        if (ringtone == null) {
            ringtone = RingtoneManager.getRingtone(this, alarmURI)
            ringtone?.audioAttributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).build()
            ringtone?.play()
        }
    }

    override fun onDestroy() {
        Log.d("", "ON DESTROY")
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        init(intent)
    }

    private fun init(intent: Intent) {
        updateMissedNotification()

        notificationTitle = "${intent.getStringExtra("matchup")} - Game ${intent.getStringExtra("gameNumber")}"

        val id = getNotificationID()
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager

        dispatchNotification(id, intent.getStringExtra("trigger"))

        if (keyguardManager.isKeyguardLocked) {
            listener = this
            setTheme(R.style.LaunchTheme)
            setContentView(R.layout.activity_alarm)

            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setTurnScreenOn(true)
                setShowWhenLocked(true)
            }

            setLayoutTexts(intent)

            val dismissButton = findViewById<Button>(R.id.dismissButton)
            dismissButton.setOnClickListener {
                with(NotificationManagerCompat.from(this)) {
                    cancel(id)
                }
                clearVariables()
            }
        } else
            finish()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "channelName"
            val descriptionText = "channelDescription"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            channel.setSound(null, null)
            val notificationManager: NotificationManager =
                    getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun dispatchNotification(id: Int, trigger: String?) {
        createNotificationChannel()

        val intent = Intent(this, NotificationDismissedBroadcastReceiver::class.java)
                .putExtra("brnlee.lolvigilmobile.id", id)
//        Using action instead of extras because for some reason, extras wasn't being properly passed to the BroadcastReceiver
//        https://stackoverflow.com/questions/38775285/android-7-broadcastreceiver-onreceive-intent-getextras-missing-data
        intent.action = id.toString()
        val pendingIntent = PendingIntent.getBroadcast(this, 0, intent, 0)

        notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_stat_name)
                .setContentTitle(notificationTitle)
                .setContentText(trigger)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setSound(null)
                .setDeleteIntent(pendingIntent)
                .setAutoCancel(true)
                .setOnlyAlertOnce(true)

        with(NotificationManagerCompat.from(this)) {
            notify(id, notificationBuilder?.build()!!)
        }
    }

    private fun updateMissedNotification() {
        if (notificationTitle != null && notificationBuilder != null && !notificationTitle?.startsWith("Missed: ")!!) {
            notificationTitle = "Missed: $notificationTitle"
            notificationBuilder?.setContentTitle(notificationTitle)
            with(NotificationManagerCompat.from(this)) {
                notify(notificationID.toInt(), notificationBuilder?.build()!!)
            }
        }
    }

    private fun setLayoutTexts(intent: Intent) {
        findViewById<TextView>(R.id.alarmTitle).text = intent.getStringExtra("matchup")

        val gameNumber = "Game ${intent.getStringExtra("gameNumber")}"
        findViewById<TextView>(R.id.gameNumber).text = gameNumber

        findViewById<TextView>(R.id.triggerDescription).text = intent.getStringExtra("trigger")
    }

    class NotificationDismissedBroadcastReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val id = intent.action
            if (id == notificationID.toString()) {
                clearVariables()
            }
        }
    }
}

