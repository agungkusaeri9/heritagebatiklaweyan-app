package com.example.heritage_batik

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.heritagebatik.app/launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    val type = call.argument<String>("type") ?: ""

                    if (!url.isNullOrBlank()) {
                        val launched = launchChannel(type, url)
                        if (launched) {
                            result.success(true)
                        } else {
                            result.error("UNAVAILABLE", "Cannot launch application", null)
                        }
                    } else {
                        result.error("INVALID_URL", "URL is empty", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun launchChannel(type: String, webUrl: String): Boolean {
        when (type.lowercase()) {
            "whatsapp" -> {
                var cleanNumber = webUrl.replace(Regex("[^0-9]"), "")
                if (cleanNumber.startsWith("0")) {
                    cleanNumber = "62" + cleanNumber.substring(1)
                }
                val waUri = Uri.parse("whatsapp://send?phone=$cleanNumber")
                try {
                    val waIntent = Intent(Intent.ACTION_VIEW, waUri).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        setPackage("com.whatsapp")
                    }
                    startActivity(waIntent)
                    return true
                } catch (e: Exception) {
                    try {
                        val waIntentAlt = Intent(Intent.ACTION_VIEW, waUri).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(waIntentAlt)
                        return true
                    } catch (e2: Exception) {
                        try {
                            val waWebUri = Uri.parse("https://wa.me/$cleanNumber")
                            val browserIntent = Intent(Intent.ACTION_VIEW, waWebUri).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(browserIntent)
                            return true
                        } catch (e3: Exception) {
                            // Fallback ke Web Browser di bawah
                        }
                    }
                }
            }
            "facebook" -> {
                val cleanUrl = webUrl.trimEnd('/')
                val pageName = cleanUrl.substringAfterLast("/")
                try {
                    val fbUri = Uri.parse("fb://facename/$pageName")
                    val fbIntent = Intent(Intent.ACTION_VIEW, fbUri).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        setPackage("com.facebook.katana")
                    }
                    startActivity(fbIntent)
                    return true
                } catch (e: Exception) {
                    try {
                        val fbUri = Uri.parse("fb://page/$pageName")
                        val fbIntent = Intent(Intent.ACTION_VIEW, fbUri).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(fbIntent)
                        return true
                    } catch (e2: Exception) {
                        // Fallback ke Web Browser jika aplikasi Facebook tidak terpasang
                    }
                }
            }
            "twitter" -> {
                val username = webUrl.trimEnd('/').substringAfterLast("/").removePrefix("@")
                try {
                    val twUri = Uri.parse("twitter://user?screen_name=$username")
                    val twIntent = Intent(Intent.ACTION_VIEW, twUri).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        setPackage("com.twitter.android")
                    }
                    startActivity(twIntent)
                    return true
                } catch (e: Exception) {
                    try {
                        val twUri = Uri.parse("twitter://user?screen_name=$username")
                        val twIntent = Intent(Intent.ACTION_VIEW, twUri).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(twIntent)
                        return true
                    } catch (e2: Exception) {
                        // Fallback ke Web Browser jika aplikasi Twitter tidak terpasang
                    }
                }
            }
            "instagram" -> {
                val username = webUrl.trimEnd('/').substringAfterLast("/").removePrefix("@")
                try {
                    val igUri = Uri.parse("instagram://user?username=$username")
                    val igIntent = Intent(Intent.ACTION_VIEW, igUri).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        setPackage("com.instagram.android")
                    }
                    startActivity(igIntent)
                    return true
                } catch (e: Exception) {
                    try {
                        val igUri = Uri.parse("http://instagram.com/_u/$username")
                        val igIntent = Intent(Intent.ACTION_VIEW, igUri).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(igIntent)
                        return true
                    } catch (e2: Exception) {
                        // Fallback ke Web Browser jika aplikasi Instagram tidak terpasang
                    }
                }
            }
        }

        // Untuk Web (atau jika aplikasi sosmed belum terpasang), buka langsung ke Browser
        return try {
            val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(webUrl)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(browserIntent)
            true
        } catch (e: Exception) {
            false
        }
    }
}
