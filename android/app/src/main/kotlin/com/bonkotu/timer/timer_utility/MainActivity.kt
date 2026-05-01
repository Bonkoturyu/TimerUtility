package com.bonkotu.timer.timer_utility

import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Flutter engine and registers MethodChannel handlers for
 * permissions that `permission_handler` does not cover. See
 * `docs/platform-channels.md` for the channel spec.
 */
class MainActivity : FlutterActivity() {
    companion object {
        private const val PERMISSION_CHANNEL = "com.bonkotu.timer/permission"
    }

    /**
     * Mark the activity to display over the keyguard and to turn the screen
     * on when launched. AndroidManifest's `showOnLockScreen` / `turnScreenOn`
     * attributes work for older API levels, but on Android 8.1+ Google
     * recommends calling these runtime APIs as well — without them, a
     * full-screen intent on Android 14+ may light up the screen but stay
     * behind the keyguard. See:
     * https://developer.android.com/develop/ui/views/notifications/time-sensitive
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canUseFullScreenIntent" -> result.success(canUseFullScreenIntentInternal())
                    "openFullScreenIntentSettings" -> {
                        openFullScreenIntentSettingsInternal()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Returns whether the OS will honor a full-screen intent. The runtime
     * gate `NotificationManager.canUseFullScreenIntent()` exists from
     * Android 14 (API 34); earlier versions auto-grant the permission, so
     * we report `true` there.
     */
    private fun canUseFullScreenIntentInternal(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            return true
        }
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return nm.canUseFullScreenIntent()
    }

    /**
     * Opens the OS settings page for USE_FULL_SCREEN_INTENT. On Android 14+
     * the dedicated `ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT` is used; on
     * older versions or when the dedicated screen can't be resolved we fall
     * back to the generic app-details page.
     */
    private fun openFullScreenIntentSettingsInternal() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val dedicated = Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            try {
                startActivity(dedicated)
                return
            } catch (_: ActivityNotFoundException) {
                // Fall through to the generic app-details settings.
            }
        }
        val fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(fallback)
    }
}
