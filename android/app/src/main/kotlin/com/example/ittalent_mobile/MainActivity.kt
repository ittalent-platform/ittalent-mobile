package com.example.ittalent_mobile

import android.content.Intent
import android.app.Activity
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import java.util.UUID
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val EMAIL_CHANNEL = "com.example.ittalent_mobile/email_launcher"
    private val DOCUMENT_CHANNEL = "com.example.ittalent_mobile/documents"
    private val createRequestCode = 48712
    private var pendingCreate: MethodChannel.Result? = null
    private val destinations = mutableMapOf<String, Uri>()

    private fun deleteCreated(uri: Uri) {
        try {
            if (DocumentsContract.isDocumentUri(this, uri)) {
                DocumentsContract.deleteDocument(contentResolver, uri)
            } else {
                contentResolver.delete(uri, null, null)
            }
        } catch (_: Exception) {
            // Some document providers do not support deletion.
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != createRequestCode) return
        val callback = pendingCreate ?: return
        pendingCreate = null
        val uri = if (resultCode == Activity.RESULT_OK) data?.data else null
        if (uri == null) {
            callback.success(null)
            return
        }
        val handle = UUID.randomUUID().toString()
        destinations[handle] = uri
        callback.success(handle)
    }

    override fun onDestroy() {
        pendingCreate?.success(null)
        pendingCreate = null
        for (uri in destinations.values) {
            deleteCreated(uri)
        }
        destinations.clear()
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DOCUMENT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "createDestination" -> {
                    if (pendingCreate != null) {
                        result.error("busy", "A document destination is already being selected", null)
                    } else {
                        val name = call.argument<String>("name")
                        val mimeType = call.argument<String>("mimeType")
                        if (name.isNullOrBlank() || mimeType.isNullOrBlank()) {
                            result.error("invalid", "Missing document name or MIME", null)
                        } else {
                            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = mimeType
                                putExtra(Intent.EXTRA_TITLE, name)
                            }
                            try {
                                pendingCreate = result
                                startActivityForResult(intent, createRequestCode)
                            } catch (error: Exception) {
                                pendingCreate = null
                                result.error("unsupported", "No document provider is available", null)
                            }
                        }
                    }
                }
                "writeDestination" -> {
                    val handle = call.argument<String>("handle")
                    val bytes = call.argument<ByteArray>("bytes")
                    val uri = handle?.let { destinations.remove(it) }
                    if (uri == null || bytes == null) {
                        result.error("invalid", "Document destination is unavailable", null)
                    } else {
                        Thread {
                            try {
                                val output = contentResolver.openOutputStream(uri, "wt")
                                    ?: throw IllegalStateException("Cannot open document destination")
                                output.use { it.write(bytes); it.flush() }
                                Handler(Looper.getMainLooper()).post { result.success(uri.toString()) }
                            } catch (error: Exception) {
                                deleteCreated(uri)
                                Handler(Looper.getMainLooper()).post {
                                    result.error(if (error is SecurityException) "permission" else "write",
                                        "Could not save document", null)
                                }
                            }
                        }.start()
                    }
                }
                "abortDestination" -> {
                    val handle = call.argument<String>("handle")
                    val uri = handle?.let { destinations.remove(it) }
                    if (uri != null) {
                        deleteCreated(uri)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

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
