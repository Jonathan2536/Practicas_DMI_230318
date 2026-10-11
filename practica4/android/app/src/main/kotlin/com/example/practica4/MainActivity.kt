package com.example.practica4

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LAUNCHER_ICON_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "setSeasonalLauncherIcon") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val alias = call.argument<String>("theme")?.let(launcherAliases::get)
            if (alias == null) {
                result.error("invalid_theme", "Unknown seasonal launcher icon.", null)
                return@setMethodCallHandler
            }

            try {
                val packageManager = packageManager
                val enabledComponent = ComponentName(this, "$packageName.$alias")
                packageManager.setComponentEnabledSetting(
                    enabledComponent,
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                    PackageManager.DONT_KILL_APP,
                )
                launcherAliases.values
                    .filterNot { it == alias }
                    .forEach { otherAlias ->
                        packageManager.setComponentEnabledSetting(
                            ComponentName(this, "$packageName.$otherAlias"),
                            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                            PackageManager.DONT_KILL_APP,
                        )
                    }
                result.success(null)
            } catch (error: Exception) {
                result.error(
                    "launcher_icon_update_failed",
                    error.message ?: "Unable to update launcher icon.",
                    null,
                )
            }
        }
    }

    private companion object {
        const val LAUNCHER_ICON_CHANNEL = "practica4/seasonal_launcher_icon"
        val launcherAliases = mapOf(
            "normal" to "LauncherNormal",
            "halloween" to "LauncherHalloween",
            "christmas" to "LauncherChristmas",
            "valentine" to "LauncherValentine",
        )
    }
}
