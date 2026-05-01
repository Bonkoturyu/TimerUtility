package com.bonkotu.timer.timer_utility

import android.app.KeyguardManager
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
     * Sets the keyguard-override flags when the device is currently
     * locked. Called from both `onCreate` (cold-launch via FSI) and
     * `onNewIntent` (warm-launch into a pre-existing singleTop Activity
     * via FSI). Without the `onNewIntent` hook the flags only get set on
     * cold-launch FSI, so a background-app + lock-screen alarm just
     * flashes the alarm screen and bounces back to the keyguard.
     *
     * For non-locked launches we leave the flags off so the Activity
     * stays in the regular task stack — otherwise lock/unlock cycles
     * strand it in "lock-screen overlay" mode and the recents (■)
     * navigation button disappears for the rest of the process lifetime.
     *
     * The flags are released in `clearShowWhenLockedInternal` once the
     * user dismisses the alarm.
     */
    private fun applyKeyguardOverrideIfLocked() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            val km = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            if (km.isKeyguardLocked) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyKeyguardOverrideIfLocked()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        applyKeyguardOverrideIfLocked()
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
                    "clearShowWhenLocked" -> {
                        clearShowWhenLockedInternal()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Releases the keyguard-override state set by Android when the
     * Activity was launched via FullScreenIntent. Without this the
     * Activity stays in "lock-screen overlay" mode after the user
     * dismisses the alarm, which keeps the recents (■) navigation
     * button suppressed until the process is killed.
     */
    private fun clearShowWhenLockedInternal() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(false)
            setTurnScreenOn(false)
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
