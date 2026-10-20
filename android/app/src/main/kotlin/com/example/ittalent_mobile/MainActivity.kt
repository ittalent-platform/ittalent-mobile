package com.example.ittalent_mobile

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val EMAIL_CHANNEL = "com.example.ittalent_mobile/email_launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EMAIL_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openEmailApp") {
                val email = call.argument<String>("email")
                val pm = packageManager
                var launched = false

                // 1. Try domain-matched provider app first
                val targetPackage = when {
                    email != null && (email.endsWith("@gmail.com") || email.contains("google")) -> "com.google.android.gm"
                    email != null && (email.endsWith("@outlook.com") || email.endsWith("@hotmail.com") || email.endsWith("@live.com") || email.contains("microsoft")) -> "com.microsoft.office.outlook"
                    email != null && email.endsWith("@yahoo.com") -> "com.yahoo.mobile.client.android.mail"
                    else -> null
                }

                if (targetPackage != null) {
                    val intent = pm.getLaunchIntentForPackage(targetPackage)
                    if (intent != null) {
                        try {
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            launched = true
                        } catch (_: Exception) {}
                    }
                }

                // 2. Fallback to generic system email app (ACTION_MAIN + CATEGORY_APP_EMAIL)
                if (!launched) {
                    try {
                        val emailIntent = Intent(Intent.ACTION_MAIN).apply {
                            addCategory(Intent.CATEGORY_APP_EMAIL)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        if (emailIntent.resolveActivity(pm) != null) {
                            startActivity(emailIntent)
                            launched = true
                        }
                    } catch (_: Exception) {}
                }

                // 3. Fallback to Gmail package if installed
                if (!launched) {
                    val gmailIntent = pm.getLaunchIntentForPackage("com.google.android.gm")
                    if (gmailIntent != null) {
                        try {
                            gmailIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(gmailIntent)
                            launched = true
                        } catch (_: Exception) {}
                    }
                }

                result.success(launched)
            } else {
                result.notImplemented()
            }
        }
    }
}
