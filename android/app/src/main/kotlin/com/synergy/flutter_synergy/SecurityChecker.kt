package com.synergy.flutter_synergy

import android.content.Context
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.provider.Settings
import java.io.File

/**
 * Native Android signals for anti–fake-GPS / tamper hints.
 *
 * Exposed to Flutter via MethodChannel `com.attendance.security/check`.
 * These checks are **heuristics** — combine with server-side validation.
 */
object SecurityChecker {

    /** Ignore very old last-known fixes (they may still carry mock=true after Fake GPS is off). */
    private const val MAX_LAST_KNOWN_AGE_MS = 3 * 60 * 1000L

    /**
     * Uses last known fixes from GPS / network providers and applies:
     * - API 31+ [Location.isMock]
     * - API < 31 [Location.isFromMockProvider]
     *
     * Only considers fixes newer than [MAX_LAST_KNOWN_AGE_MS] so a stale mock-tagged
     * cached location does not block the user forever after disabling spoof apps.
     */
    fun isMockLocation(context: Context): Boolean {
        val lm = context.applicationContext.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
            ?: return false

        val now = System.currentTimeMillis()
        val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
        for (provider in providers) {
            try {
                val loc = lm.getLastKnownLocation(provider) ?: continue
                if (now - loc.time > MAX_LAST_KNOWN_AGE_MS) continue
                if (loc.isMockCompat()) return true
            } catch (_: SecurityException) {
                // Permission not granted — treat as non-mock; Flutter layer still validates.
            }
        }
        return false
    }

    private fun Location.isMockCompat(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            isMock
        } else {
            @Suppress("DEPRECATION")
            isFromMockProvider
        }
    }

    /**
     * Developer options enabled (users often enable this alongside mock-location apps).
     */
    fun isDeveloperModeEnabled(context: Context): Boolean {
        return try {
            Settings.Global.getInt(
                context.contentResolver,
                Settings.Global.DEVELOPMENT_SETTINGS_ENABLED,
                0,
            ) != 0
        } catch (_: Exception) {
            false
        }
    }

    fun isRooted(): Boolean {
        val tags = Build.TAGS
        if (tags != null && tags.contains("test-keys")) return true

        val suPaths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su",
        )
        for (path in suPaths) {
            if (File(path).exists()) return true
        }

        return try {
            val process = Runtime.getRuntime().exec(arrayOf("/system/xbin/which", "su"))
            val reader = process.inputStream.bufferedReader()
            val line = reader.readLine()
            reader.close()
            process.destroy()
            line != null && line.isNotEmpty()
        } catch (_: Exception) {
            false
        }
    }

    fun isEmulator(): Boolean {
        return (Build.FINGERPRINT.startsWith("generic")
            || Build.FINGERPRINT.startsWith("unknown")
            || Build.MODEL.contains("google_sdk", ignoreCase = true)
            || Build.MODEL.contains("Emulator", ignoreCase = true)
            || Build.MODEL.contains("Android SDK built for x86")
            || Build.MANUFACTURER.contains("Genymotion")
            || (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic"))
            || "google_sdk" == Build.PRODUCT)
    }
}
