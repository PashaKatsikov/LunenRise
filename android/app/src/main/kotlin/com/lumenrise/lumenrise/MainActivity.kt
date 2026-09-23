package com.lumenrise.lumenrise

import android.app.Activity
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.core.view.WindowCompat
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val fileChannel = "lr.pick/files"
    private val boardChannel = "lr.hw/board"
    private val vaultChannel = "lr.vault/box"
    private val rimChannel = "lr.rim/edge"
    private val fileRequest = 0x4C21
    private var pendingResult: MethodChannel.Result? = null
    private var vaultPrefs: SharedPreferences? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        holdKeyboard()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        holdKeyboard()
    }

    // The window does not pan for the IME. On API 30+ the mode is
    // ADJUST_NOTHING so the inset still arrives for measurement. Older
    // releases keep the manifest adjustResize, which is how the engine
    // reports that inset there.
    private fun holdKeyboard() {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val rim = RimReader(this)

        MethodChannel(messenger, rimChannel).setMethodCallHandler { call, result ->
            if (call.method == "read") {
                result.success(rim.edges())
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(messenger, fileChannel).setMethodCallHandler { call, result ->
            if (call.method == "grab") {
                val multi = call.argument<Boolean>("multi") ?: false
                val mimes = call.argument<List<String>>("mimes") ?: emptyList()
                openPicker(multi, mimes, result)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(messenger, boardChannel).setMethodCallHandler { call, result ->
            if (call.method == "scan") {
                result.success(
                    mapOf(
                        "rel" to (Build.VERSION.RELEASE ?: ""),
                        "make" to (Build.BRAND ?: ""),
                        "sku" to (Build.MODEL ?: ""),
                        "tag" to (Build.DISPLAY ?: ""),
                    ),
                )
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(messenger, vaultChannel).setMethodCallHandler { call, result ->
            val prefs = openVault()
            if (prefs == null) {
                result.success(null)
                return@setMethodCallHandler
            }
            val slot = call.argument<String>("slot")
            if (slot == null) {
                result.success(null)
                return@setMethodCallHandler
            }
            when (call.method) {
                "get" -> result.success(prefs.getString(slot, null))
                "put" -> {
                    val text = call.argument<String>("text") ?: ""
                    prefs.edit().putString(slot, text).apply()
                    result.success(null)
                }
                "cut" -> {
                    prefs.edit().remove(slot).apply()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openVault(): SharedPreferences? {
        vaultPrefs?.let { return it }
        return try {
            val master = MasterKey.Builder(applicationContext, "lr_lock_key")
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()
            val prefs = EncryptedSharedPreferences.create(
                applicationContext,
                "lr_lock_store",
                master,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
            )
            vaultPrefs = prefs
            prefs
        } catch (_: Exception) {
            null
        }
    }

    private fun openPicker(
        multi: Boolean,
        mimes: List<String>,
        result: MethodChannel.Result,
    ) {
        pendingResult?.success(emptyList<String>())
        pendingResult = result

        val valid = mimes.filter { it.contains("/") }
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, multi)
            when {
                valid.isEmpty() -> type = "*/*"
                valid.size == 1 -> type = valid[0]
                else -> {
                    type = "*/*"
                    putExtra(Intent.EXTRA_MIME_TYPES, valid.toTypedArray())
                }
            }
        }

        try {
            startActivityForResult(Intent.createChooser(intent, null), fileRequest)
        } catch (_: Exception) {
            pendingResult = null
            result.success(emptyList<String>())
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != fileRequest) return

        val result = pendingResult
        pendingResult = null
        if (result == null) return

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(emptyList<String>())
            return
        }

        val uris = ArrayList<String>()
        val clip = data.clipData
        if (clip != null) {
            for (i in 0 until clip.itemCount) {
                uris.add(clip.getItemAt(i).uri.toString())
            }
        } else {
            data.data?.let { uris.add(it.toString()) }
        }
        result.success(uris)
    }
}
