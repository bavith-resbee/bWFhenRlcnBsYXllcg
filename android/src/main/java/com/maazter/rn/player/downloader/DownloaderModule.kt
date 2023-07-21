package com.maazter.rn.player.downloader

import android.util.Log
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule.RCTDeviceEventEmitter
import com.google.android.exoplayer2.DefaultRenderersFactory
import com.google.android.exoplayer2.Format
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.offline.*
import com.google.android.exoplayer2.source.TrackGroupArray
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector
import com.google.android.exoplayer2.trackselection.MappingTrackSelector.MappedTrackInfo
import com.google.android.exoplayer2.upstream.DataSource
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import com.maazter.rn.player.datasource.CustomHlsDataSourceFactory
import java.io.IOException
import java.nio.charset.StandardCharsets


class DownloaderModule(reactContext: ReactApplicationContext?) :
  ReactContextBaseJavaModule(reactContext) {

  override fun getName() = "MaazterDownloader"

  override fun initialize() {
    super.initialize()

    setDownloadListener()
  }

  @ReactMethod
  fun add(contentId: String, contentUri: String, encKey: String?, quality: ReadableMap, data: String?, promise: Promise) {

    var dataSourceFactory: DataSource.Factory = DefaultDataSourceFactory(reactApplicationContext)
    if (encKey != null) {
      dataSourceFactory = CustomHlsDataSourceFactory(dataSourceFactory, getEncKey(encKey))
    }

    val downloadHelper: DownloadHelper = DownloadHelper.forMediaItem(
      reactApplicationContext,
      MediaItem.fromUri(contentUri),
      DefaultRenderersFactory(reactApplicationContext),
      dataSourceFactory
    )

    downloadHelper.prepare(object : DownloadHelper.Callback {
      override fun onPrepared(helper: DownloadHelper) {

        val width = quality.getInt("width")
        val height = quality.getInt("height")
        val bitrate = quality.getInt("bitrate")

        Log.d("track", height.toString())

        val qualityParams: DefaultTrackSelector.Parameters =
          DefaultTrackSelector(reactApplicationContext).parameters.buildUpon()
            .setMaxVideoSize(width, height)
            .setMaxVideoBitrate(bitrate)
            .build()

        for (periodIndex in 0 until downloadHelper.periodCount) {
          val mappedTrackInfo: MappedTrackInfo = downloadHelper.getMappedTrackInfo(periodIndex)
          downloadHelper.clearTrackSelections(periodIndex)
          for (i in 0 until mappedTrackInfo.rendererCount) {
            downloadHelper.addTrackSelection(periodIndex, qualityParams)
          }
        }

        startDownload(downloadHelper.getDownloadRequest(contentId, data?.toByteArray()))
        promise.resolve(null)
      }

      override fun onPrepareError(helper: DownloadHelper, e: IOException) {
        promise.reject("Preparation Error", e)
      }
    })
  }

  private fun startDownload(downloadRequest: DownloadRequest) {
    DownloadService.sendAddDownload(
      reactApplicationContext,
      MaazterDownloadService::class.java,
      downloadRequest,
      false)
  }

  private fun getEncKey(encKey: String): ByteArray {
    return encKey.toByteArray(StandardCharsets.UTF_8)
  }

  @ReactMethod
  fun getTracks(contentUri: String, encKey: String?, promise: Promise) {
    var dataSourceFactory: DataSource.Factory = DefaultDataSourceFactory(reactApplicationContext)
    if (encKey != null) {
      dataSourceFactory = CustomHlsDataSourceFactory(dataSourceFactory, getEncKey(encKey))
    }

    val downloadHelper: DownloadHelper = DownloadHelper.forMediaItem(
      reactApplicationContext,
      MediaItem.fromUri(contentUri),
      DefaultRenderersFactory(reactApplicationContext),
      dataSourceFactory
    )

    downloadHelper.prepare(object : DownloadHelper.Callback {
      override fun onPrepared(helper: DownloadHelper) {
        val tracks: ArrayList<Track> = arrayListOf()
        for (i in 0 until downloadHelper.periodCount) {
          val trackGroups: TrackGroupArray = downloadHelper.getTrackGroups(i)
          for (j in 0 until trackGroups.length) {
            val trackGroup = trackGroups[j]
            for (k in 0 until trackGroup.length) {
              val track: Format = trackGroup.getFormat(k)
              if (track.sampleMimeType.equals("video/avc", ignoreCase = true)) {
                tracks.add(Track(track, i, j, k))
              }
            }
          }
        }

        val arg = Arguments.createArray()
        tracks.forEach { arg.pushMap(it.toWritableMap()) }
        promise.resolve(arg)
        downloadHelper.release()
      }

      override fun onPrepareError(helper: DownloadHelper, e: IOException) {
        promise.reject("Preparation Error", e)
      }
    })
  }

  @ReactMethod
  fun remove(contentId: String) {
    DownloadService.sendRemoveDownload(
      reactApplicationContext,
      MaazterDownloadService::class.java,
      contentId,
      false)
  }

  @ReactMethod
  fun pause(contentId: String, reason: Int = 1) {
    DownloadService.sendSetStopReason(
      reactApplicationContext,
      MaazterDownloadService::class.java,
      contentId,
      reason,
      false
    )
  }

  @ReactMethod
  fun resume(contentId: String) {
    DownloadService.sendSetStopReason(
      reactApplicationContext,
      MaazterDownloadService::class.java,
      contentId,
      Download.STOP_REASON_NONE,
      false
    )
  }

  @ReactMethod
  fun pauseAll() {
    DownloadService.sendPauseDownloads(
      reactApplicationContext,
      MaazterDownloadService::class.java,
      false
    )
  }

  @ReactMethod
  fun resumeAll() {
    DownloadService.sendResumeDownloads(
      reactApplicationContext,
      MaazterDownloadService::class.java,
      false
    )
  }

  @ReactMethod
  fun listDownloads(promise: Promise) {
    val downloadManager = DownloadUtil.getDownloadManager(reactApplicationContext)
    val downloads = downloadManager?.downloadIndex?.getDownloads()

    if (downloads == null) {
      promise.resolve(Arguments.createArray())
      return
    }

    val arg = Arguments.createArray()

    downloads.moveToFirst()
    while (!downloads.isAfterLast) {
      val download = downloads.download
      arg.pushMap(downloadToMap(download))

      downloads.moveToNext()
    }

    promise.resolve(arg)
  }

  private fun downloadToMap(download: Download): WritableMap {
    val request = Arguments.createMap()
    request.putString("customCacheKey", download.request.customCacheKey)
    request.putString("id", download.request.id)
    request.putString("mimeType", download.request.mimeType)
    request.putString("data", download.request.data.toString())
    request.putString("uri", download.request.uri.toString())

    val map = Arguments.createMap()
    map.putInt("failureReason", download.failureReason)
    map.putInt("state", download.state)
    map.putInt("stopReason", download.stopReason)
    map.putInt("bytesDownloaded", download.bytesDownloaded.toInt())
    map.putInt("contentLength", download.contentLength.toInt())
    map.putBoolean("isTerminalState", download.isTerminalState)
    map.putInt("percentDownloaded", download.percentDownloaded.toInt())
    map.putInt("startTimeMs", download.startTimeMs.toInt())
    map.putInt("updateTimeMs", download.updateTimeMs.toInt())
    map.putMap("request", request)

    return map
  }

  private fun emitEvent(name: String, data: Any? = null) {
    reactApplicationContext
      .getJSModule(RCTDeviceEventEmitter::class.java)
      .emit(name, data)
  }

  private fun setDownloadListener() {
    val downloadManager = DownloadUtil.getDownloadManager(reactApplicationContext)
    downloadManager?.addListener(object: DownloadManager.Listener {
      override fun onDownloadChanged(
        downloadManager: DownloadManager,
        download: Download,
        finalException: Exception?
      ) {
        super.onDownloadChanged(downloadManager, download, finalException)

        emitEvent("onDownloadChanged", downloadToMap(download))
      }

      override fun onDownloadRemoved(downloadManager: DownloadManager, download: Download) {
        super.onDownloadRemoved(downloadManager, download)

        emitEvent("onDownloadRemoved", downloadToMap(download))
      }

      override fun onIdle(downloadManager: DownloadManager) {
        super.onIdle(downloadManager)
        emitEvent("onIdle")
      }
    })
  }

  companion object {
    class Track(private val format: Format, private val periodIndex: Int, private val trackGroupIndex: Int, private val trackIndex: Int) {
      fun toWritableMap() : WritableMap {
        val map: WritableMap = Arguments.createMap()
        map.putInt("periodIndex", periodIndex)
        map.putInt("trackGroupIndex", trackGroupIndex)
        map.putInt("trackIndex", trackIndex)

        map.putString("quality", format.height.toString() + "p")
        map.putInt("height", format.height)
        map.putInt("width", format.width)
        map.putInt("bitrate", format.bitrate)

        return map
      }
    }
  }
}
