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
        private var notificationChannel = false
        private var notificationID = AtomicInteger(0)

        private var ringtone: Ringtone? = null
        private var previousBuilder: NotificationCompat.Builder? = null
        private var previousNotificationTitle: String? = null

        fun getNotificationID(): Int {
            return notificationID.incrementAndGet()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        Log.d("tag", intent.getStringExtra("match"))

        init(intent)

        val alarmURI = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
        if (ringtone == null) {
            ringtone = RingtoneManager.getRingtone(this, alarmURI)
            ringtone?.audioAttributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).build()
            ringtone?.play()
        }
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        init(intent)
    }

    private fun init(intent: Intent?) {
        updateMissedNotification()

        previousNotificationTitle =
                if (intent != null)
                    intent.getStringExtra("match")
                else
                    ""

        val id = getNotificationID()
        dispatchNotification(id)

        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        if (keyguardManager.isKeyguardLocked) {
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

            val alarmTitle = findViewById<TextView>(R.id.alarmTitle)
            alarmTitle.text = intent?.getStringExtra("match")

            val dismissButton = findViewById<Button>(R.id.dismissButton)
            dismissButton.setOnClickListener {
                with(NotificationManagerCompat.from(this)) {
                    cancel(id)
                }
                ringtone?.stop()
                ringtone = null
                finish()
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
            notificationChannel = true
        }
    }

    private fun dispatchNotification(id: Int) {
        createNotificationChannel()

        val intent = Intent(this, NotificationDismissedBroadcastReceiver::class.java)
                .putExtra("brnlee.lolvigilmobile.id", id)
//        Using action instead of extras because for some reason, extras wasn't being properly passed to the BroadcastReceiver
//        https://stackoverflow.com/questions/38775285/android-7-broadcastreceiver-onreceive-intent-getextras-missing-data
        intent.action = id.toString()
        val pendingIntent = PendingIntent.getBroadcast(this, 0, intent, 0)

        previousBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.drawable.common_google_signin_btn_icon_dark)
                .setContentTitle(previousNotificationTitle)
                .setContentText(id.toString())
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setSound(null)
                .setDeleteIntent(pendingIntent)
                .setAutoCancel(true)
                .setOnlyAlertOnce(true)

        with(NotificationManagerCompat.from(this)) {
            notify(id, previousBuilder?.build()!!)
        }
    }

    fun updateMissedNotification() {
        if (previousNotificationTitle != null && previousBuilder != null && !previousNotificationTitle?.startsWith("Missed: ")!!) {
            previousNotificationTitle = "Missed: $previousNotificationTitle"
            previousBuilder?.setContentTitle(previousNotificationTitle)
            with(NotificationManagerCompat.from(this)) {
                notify(notificationID.toInt(), previousBuilder?.build()!!)
            }
        }
    }

    class NotificationDismissedBroadcastReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val id = intent.action
            if (id == notificationID.toString()) {
                ringtone?.stop()
                ringtone = null
                previousBuilder = null
                previousNotificationTitle = null
            }
        }
    }
}
