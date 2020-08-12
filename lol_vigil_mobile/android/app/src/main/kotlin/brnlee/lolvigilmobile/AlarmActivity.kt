package brnlee.lolvigilmobile

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import io.flutter.Log

class AlarmActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
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
        Log.d("tag", intent.getStringExtra("match"))

        val dismissButton = findViewById<Button>(R.id.dismissButton)
        dismissButton.setOnClickListener{
            finish()
        }

        val alarmTitle = findViewById<TextView>(R.id.alarmTitle)
        alarmTitle.text = intent.getStringExtra("match")
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        val alarmTitle = findViewById<TextView>(R.id.alarmTitle)
        alarmTitle.text = intent?.getStringExtra("match")
    }
}