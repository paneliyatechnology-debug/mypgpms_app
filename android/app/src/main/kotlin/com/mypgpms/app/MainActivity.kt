package com.mypgpms.app

import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mypgpms.app/upi"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledUpiApps" -> {
                    try {
                        val apps = getInstalledUpiApps()
                        result.success(apps)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "launchUpiApp" -> {
                    val uriString = call.argument<String>("uri")
                    val packageName = call.argument<String>("packageName")
                    if (uriString.isNullOrEmpty()) {
                        result.error("INVALID_URI", "URI cannot be empty", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val intent = Intent(Intent.ACTION_VIEW)
                        intent.data = Uri.parse(uriString)
                        if (!packageName.isNullOrEmpty()) {
                            intent.setPackage(packageName)
                        }
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("LAUNCH_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getInstalledUpiApps(): List<Map<String, Any?>> {
        val packageManager = packageManager
        val resultList = mutableListOf<Map<String, Any?>>()
        val seenPackages = mutableSetOf<String>()

        // 1. Direct package verification for top UPI apps (100% reliable across all Android OEM skins & versions)
        val knownUpiPackages = listOf(
            "com.phonepe.app" to "PhonePe",
            "com.google.android.apps.nbu.paisa.user" to "Google Pay",
            "net.one97.paytm" to "Paytm",
            "in.org.npci.upiapp" to "BHIM",
            "com.dreamplug.androidapp" to "CRED",
            "in.amazon.mShop.android.shopping" to "Amazon Pay",
            "com.whatsapp" to "WhatsApp",
            "com.mobikwik_new" to "MobiKwik",
            "com.navi.passport" to "Navi",
            "com.freecharge.android" to "Freecharge",
            "com.sbi.upi" to "BHIM SBI Pay",
            "com.csam.icici.bank.imobile" to "iMobile",
            "com.msf.kbank.mobile" to "Kotak Bank"
        )

        for ((pkg, defaultName) in knownUpiPackages) {
            try {
                val appInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    packageManager.getApplicationInfo(pkg, PackageManager.ApplicationInfoFlags.of(0L))
                } else {
                    @Suppress("DEPRECATION")
                    packageManager.getApplicationInfo(pkg, 0)
                }

                seenPackages.add(pkg)
                val appName = try {
                    appInfo.loadLabel(packageManager).toString()
                } catch (_: Exception) {
                    defaultName
                }
                val iconDrawable = try {
                    appInfo.loadIcon(packageManager)
                } catch (_: Exception) {
                    null
                }
                val iconBase64 = drawableToBase64(iconDrawable)

                resultList.add(mapOf(
                    "packageName" to pkg,
                    "appName" to if (appName.isNotEmpty()) appName else defaultName,
                    "icon" to iconBase64
                ))
            } catch (_: Exception) {
                // Not installed, continue
            }
        }

        // 2. Query any other installed apps handling upi://pay
        try {
            val upiIntent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("upi://pay")
            }

            val resolveInfoList = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.queryIntentActivities(
                    upiIntent,
                    PackageManager.ResolveInfoFlags.of(0L)
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.queryIntentActivities(upiIntent, 0)
            }

            for (info in resolveInfoList) {
                val pkg = info.activityInfo?.packageName ?: continue
                if (seenPackages.contains(pkg)) continue
                seenPackages.add(pkg)

                val appName = info.loadLabel(packageManager).toString()
                val iconDrawable = info.loadIcon(packageManager)
                val iconBase64 = drawableToBase64(iconDrawable)

                resultList.add(mapOf(
                    "packageName" to pkg,
                    "appName" to appName,
                    "icon" to iconBase64
                ))
            }
        } catch (_: Exception) {}

        return resultList
    }

    private fun drawableToBase64(drawable: Drawable?): String? {
        if (drawable == null) return null
        return try {
            val bitmap = when (drawable) {
                is BitmapDrawable -> drawable.bitmap
                else -> {
                    val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
                    val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
                    val b = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    val canvas = Canvas(b)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                    b
                }
            }
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            val byteArray = stream.toByteArray()
            Base64.encodeToString(byteArray, Base64.NO_WRAP)
        } catch (e: Exception) {
            null
        }
    }
}
