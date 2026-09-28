package com.akobo.akobo_flutter

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.IBinder
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat.MediaStyle

class MediaNotificationService : Service() {

    companion object {
        const val CHANNEL_ID = "akobo_media_playback_channel"
        const val NOTIFICATION_ID = 1001

        const val ACTION_START = "com.akobo.akobo_flutter.START"
        const val ACTION_UPDATE = "com.akobo.akobo_flutter.UPDATE"
        const val ACTION_STOP = "com.akobo.akobo_flutter.STOP"

        const val ACTION_PLAY = "com.akobo.akobo_flutter.PLAY"
        const val ACTION_PAUSE = "com.akobo.akobo_flutter.PAUSE"
        const val ACTION_NEXT = "com.akobo.akobo_flutter.NEXT"
        const val ACTION_PREVIOUS = "com.akobo.akobo_flutter.PREVIOUS"

        const val EXTRA_TITLE = "extra_title"
        const val EXTRA_ARTIST = "extra_artist"
        const val EXTRA_IS_PLAYING = "extra_is_playing"
        const val EXTRA_DURATION = "extra_duration"
        const val EXTRA_POSITION = "extra_position"
        const val EXTRA_ARTWORK_BYTES = "extra_artwork_bytes"

        var onMediaActionCallback: ((String) -> Unit)? = null
    }

    private var mediaSession: MediaSessionCompat? = null
    private var isPlaying = false
    private var currentTitle = "Akobo Media"
    private var currentArtist = "Playing"
    private var currentArtwork: Bitmap? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()

        mediaSession = MediaSessionCompat(this, "AkoboMediaSession").apply {
            isActive = true
            setCallback(object : MediaSessionCompat.Callback() {
                override fun onPlay() {
                    onMediaActionCallback?.invoke("play")
                }

                override fun onPause() {
                    onMediaActionCallback?.invoke("pause")
                }

                override fun onSkipToNext() {
                    onMediaActionCallback?.invoke("next")
                }

                override fun onSkipToPrevious() {
                    onMediaActionCallback?.invoke("previous")
                }

                override fun onStop() {
                    onMediaActionCallback?.invoke("stop")
                    stopSelf()
                }
            })
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START, ACTION_UPDATE -> {
                val title = intent.getStringExtra(EXTRA_TITLE) ?: currentTitle
                val artist = intent.getStringExtra(EXTRA_ARTIST) ?: currentArtist
                val playing = intent.getBooleanExtra(EXTRA_IS_PLAYING, isPlaying)
                val duration = intent.getLongExtra(EXTRA_DURATION, 0L)
                val position = intent.getLongExtra(EXTRA_POSITION, 0L)
                val artworkBytes = intent.getByteArrayExtra(EXTRA_ARTWORK_BYTES)

                currentTitle = title
                currentArtist = artist
                isPlaying = playing

                if (artworkBytes != null && artworkBytes.isNotEmpty()) {
                    try {
                        currentArtwork = BitmapFactory.decodeByteArray(artworkBytes, 0, artworkBytes.size)
                    } catch (_: Exception) {}
                }

                updateMediaSessionState(playing, position, duration)
                val notification = buildNotification()
                startForeground(NOTIFICATION_ID, notification)
            }
            ACTION_PLAY -> {
                isPlaying = true
                onMediaActionCallback?.invoke("play")
                updateMediaSessionState(true, 0L, 0L)
                val notification = buildNotification()
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.notify(NOTIFICATION_ID, notification)
            }
            ACTION_PAUSE -> {
                isPlaying = false
                onMediaActionCallback?.invoke("pause")
                updateMediaSessionState(false, 0L, 0L)
                val notification = buildNotification()
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.notify(NOTIFICATION_ID, notification)
            }
            ACTION_NEXT -> {
                onMediaActionCallback?.invoke("next")
            }
            ACTION_PREVIOUS -> {
                onMediaActionCallback?.invoke("previous")
            }
            ACTION_STOP -> {
                onMediaActionCallback?.invoke("stop")
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    private fun updateMediaSessionState(playing: Boolean, position: Long, duration: Long) {
        val state = if (playing) PlaybackStateCompat.STATE_PLAYING else PlaybackStateCompat.STATE_PAUSED
        val actions = PlaybackStateCompat.ACTION_PLAY or
                PlaybackStateCompat.ACTION_PAUSE or
                PlaybackStateCompat.ACTION_PLAY_PAUSE or
                PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
                PlaybackStateCompat.ACTION_STOP

        mediaSession?.setPlaybackState(
            PlaybackStateCompat.Builder()
                .setActions(actions)
                .setState(state, position, 1.0f)
                .build()
        )

        val metadataBuilder = MediaMetadataCompat.Builder()
            .putString(MediaMetadataCompat.METADATA_KEY_TITLE, currentTitle)
            .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, currentArtist)
            .putString(MediaMetadataCompat.METADATA_KEY_ALBUM, "Akobo 4K Quantum Player")
            .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, duration)

        if (currentArtwork != null) {
            metadataBuilder.putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, currentArtwork)
            metadataBuilder.putBitmap(MediaMetadataCompat.METADATA_KEY_ART, currentArtwork)
        }

        mediaSession?.setMetadata(metadataBuilder.build())
    }

    private fun buildNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentPendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val prevIntent = Intent(this, MediaNotificationService::class.java).apply { action = ACTION_PREVIOUS }
        val prevPending = PendingIntent.getService(this, 1, prevIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val playPauseAction = if (isPlaying) ACTION_PAUSE else ACTION_PLAY
        val playPauseIntent = Intent(this, MediaNotificationService::class.java).apply { action = playPauseAction }
        val playPausePending = PendingIntent.getService(this, 2, playPauseIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val nextIntent = Intent(this, MediaNotificationService::class.java).apply { action = ACTION_NEXT }
        val nextPending = PendingIntent.getService(this, 3, nextIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val stopIntent = Intent(this, MediaNotificationService::class.java).apply { action = ACTION_STOP }
        val stopPending = PendingIntent.getService(this, 4, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(currentTitle)
            .setContentText(currentArtist)
            .setSubText("Akobo 4K")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(contentPendingIntent)
            .setOngoing(isPlaying)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .addAction(android.R.drawable.ic_media_previous, "Previous", prevPending)
            .addAction(
                if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
                if (isPlaying) "Pause" else "Play",
                playPausePending
            )
            .addAction(android.R.drawable.ic_media_next, "Next", nextPending)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Close", stopPending)

        if (currentArtwork != null) {
            builder.setLargeIcon(currentArtwork)
        }

        mediaSession?.let {
            builder.setStyle(
                MediaStyle()
                    .setMediaSession(it.sessionToken)
                    .setShowActionsInCompactView(0, 1, 2)
                    .setShowCancelButton(true)
                    .setCancelButtonIntent(stopPending)
            )
        }

        return builder.build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Akobo 4K Media Playback"
            val descriptionText = "Lock screen playback controls and media notifications"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        mediaSession?.release()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
