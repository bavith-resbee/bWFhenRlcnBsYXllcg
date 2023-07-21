package com.maazter.rn.player.downloader

import android.app.Notification
import android.content.Context
import com.google.android.exoplayer2.offline.Download
import com.google.android.exoplayer2.offline.DownloadManager
import com.google.android.exoplayer2.offline.DownloadService
import com.google.android.exoplayer2.scheduler.PlatformScheduler
import com.google.android.exoplayer2.ui.DownloadNotificationHelper
import com.google.android.exoplayer2.util.NotificationUtil
import com.google.android.exoplayer2.util.Util
import com.maazter.rn.player.R

import com.maazter.rn.player.downloader.DownloadUtil.DOWNLOAD_NOTIFICATION_CHANNEL_ID

class MaazterDownloadService(
  foregroundNotificationId: Int,
  foregroundNotificationUpdateInterval: Long,
  channelId: String?,
  channelNameResourceId: Int,
  channelDescriptionResourceId: Int
) : DownloadService(
  foregroundNotificationId,
  foregroundNotificationUpdateInterval,
  channelId,
  channelNameResourceId,
  channelDescriptionResourceId
) {
  companion object {
    private const val JOB_ID = 1
    private const val FOREGROUND_NOTIFICATION_ID = 1
  }

  constructor() : this(
    FOREGROUND_NOTIFICATION_ID,
    DEFAULT_FOREGROUND_NOTIFICATION_UPDATE_INTERVAL,
    DOWNLOAD_NOTIFICATION_CHANNEL_ID,
    R.string.exo_download_notification_channel_name,
    0)

  override fun getDownloadManager(): DownloadManager {
    val downloadManager: DownloadManager = DownloadUtil.getDownloadManager(this)!!
    val downloadNotificationHelper: DownloadNotificationHelper =
      DownloadUtil.getDownloadNotificationHelper(this)!!
    downloadManager.addListener(
      TerminalStateNotificationHelper(
        this, downloadNotificationHelper, FOREGROUND_NOTIFICATION_ID + 1
      )
    )
    return downloadManager
  }

  override fun getScheduler(): PlatformScheduler? {
    return if (Util.SDK_INT >= 21) PlatformScheduler(this, JOB_ID) else null
  }

  override fun getForegroundNotification(downloads: MutableList<Download>): Notification {
    return DownloadUtil.getDownloadNotificationHelper(this)!!
      .buildProgressNotification(
        this,
        R.drawable.ic_cloud_download,
        null,
        null,
        downloads
      )
  }

  /**
   * Creates and displays notifications for downloads when they complete or fail.
   *
   *
   * This helper will outlive the lifespan of a single instance of [MaazterDownloadService].
   * It is static to avoid leaking the first [MaazterDownloadService] instance.
   */
  private class TerminalStateNotificationHelper(
    context: Context,
    private val notificationHelper: DownloadNotificationHelper, firstNotificationId: Int
  ) :
    DownloadManager.Listener {
    private val context: Context = context.applicationContext
    private var nextNotificationId: Int = firstNotificationId

    override fun onDownloadChanged(
      downloadManager: DownloadManager, download: Download, finalException: Exception?
    ) {
      val notification: Notification = when (download.state) {
        Download.STATE_COMPLETED -> {
          notificationHelper.buildDownloadCompletedNotification(
            context,
            R.drawable.ic_check,
            null,
            Util.fromUtf8Bytes(download.request.data)
          )
        }
        Download.STATE_FAILED -> {
          notificationHelper.buildDownloadFailedNotification(
            context,
            R.drawable.ic_close,
            null,
            Util.fromUtf8Bytes(download.request.data)
          )
        }
        else -> {
          return
        }
      }
      NotificationUtil.setNotification(context, nextNotificationId++, notification)
    }

  }
}
