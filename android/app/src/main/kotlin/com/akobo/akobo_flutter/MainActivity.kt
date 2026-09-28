package com.akobo.akobo_flutter

import android.content.Intent
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.akobo.akobo_flutter/video_thumbnail"
    private val executor = Executors.newFixedThreadPool(4)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getVideoThumbnail") {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("INVALID_PATH", "Path cannot be null", null)
                    return@setMethodCallHandler
                }
                executor.execute {
                    var retriever: MediaMetadataRetriever? = null
                    try {
                        retriever = MediaMetadataRetriever()
                        if (path.startsWith("http://") || path.startsWith("https://")) {
                            retriever.setDataSource(path, HashMap<String, String>())
                        } else {
                            retriever.setDataSource(path)
                        }
                        val bitmap = retriever.getFrameAtTime(1000000, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                            ?: retriever.frameAtTime

                        if (bitmap != null) {
                            val stream = ByteArrayOutputStream()
                            bitmap.compress(Bitmap.CompressFormat.JPEG, 80, stream)
                            val byteArray = stream.toByteArray()
                            bitmap.recycle()
                            runOnUiThread { result.success(byteArray) }
                        } else {
                            runOnUiThread { result.success(null) }
                        }
                    } catch (e: Exception) {
                        runOnUiThread { result.success(null) }
                    } finally {
                        try {
                            retriever?.release()
                        } catch (_: Exception) {}
                    }
                }
            } else {
                result.notImplemented()
            }
        }

        val mediaChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.akobo.akobo_flutter/media_notification")
        MediaNotificationService.onMediaActionCallback = { action ->
            runOnUiThread {
                mediaChannel.invokeMethod("onAction", action)
            }
        }

        mediaChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startNotification", "updateNotification" -> {
                    val title = call.argument<String>("title") ?: "Akobo Media"
                    val artist = call.argument<String>("artist") ?: "Playing"
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: true
                    val duration = (call.argument<Number>("duration") ?: 0).toLong()
                    val position = (call.argument<Number>("position") ?: 0).toLong()
                    val artworkBytes = call.argument<ByteArray>("artwork")

                    val intent = Intent(this, MediaNotificationService::class.java).apply {
                        action = if (call.method == "startNotification") MediaNotificationService.ACTION_START else MediaNotificationService.ACTION_UPDATE
                        putExtra(MediaNotificationService.EXTRA_TITLE, title)
                        putExtra(MediaNotificationService.EXTRA_ARTIST, artist)
                        putExtra(MediaNotificationService.EXTRA_IS_PLAYING, isPlaying)
                        putExtra(MediaNotificationService.EXTRA_DURATION, duration)
                        putExtra(MediaNotificationService.EXTRA_POSITION, position)
                        putExtra(MediaNotificationService.EXTRA_ARTWORK_BYTES, artworkBytes)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                "stopNotification" -> {
                    val intent = Intent(this, MediaNotificationService::class.java).apply {
                        action = MediaNotificationService.ACTION_STOP
                    }
                    stopService(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }


    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }
}
