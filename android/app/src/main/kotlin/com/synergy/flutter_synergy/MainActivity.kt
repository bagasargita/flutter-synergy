package com.synergy.flutter_synergy

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.attendance.security/check",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isMockLocation" ->
                    result.success(SecurityChecker.isMockLocation(this))

                "isDeveloperMode" ->
                    result.success(SecurityChecker.isDeveloperModeEnabled(this))

                "isRooted" ->
                    result.success(SecurityChecker.isRooted())

                "isEmulator" ->
                    result.success(SecurityChecker.isEmulator())

                else -> result.notImplemented()
            }
        }
    }
}
