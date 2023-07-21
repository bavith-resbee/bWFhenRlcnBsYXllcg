package com.maazter.rn.player

import android.content.Context
import android.content.res.Configuration
import android.content.res.Resources
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Point
import android.graphics.drawable.BitmapDrawable
import android.net.Uri
import android.util.Log
import android.view.WindowManager
import androidx.core.content.ContentProviderCompat
import com.facebook.react.bridge.*
import com.facebook.react.common.MapBuilder
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.uimanager.events.RCTEventEmitter
import com.google.android.exoplayer2.*
import com.google.android.exoplayer2.database.DatabaseProvider
import com.google.android.exoplayer2.database.ExoDatabaseProvider
import com.google.android.exoplayer2.offline.DownloadRequest
import com.google.android.exoplayer2.source.DefaultMediaSourceFactory
import com.google.android.exoplayer2.source.MediaSource
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.source.dash.DashMediaSource
import com.google.android.exoplayer2.source.hls.HlsMediaSource
import com.google.android.exoplayer2.source.rtsp.RtspMediaSource
import com.google.android.exoplayer2.source.smoothstreaming.SsMediaSource
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout
import com.google.android.exoplayer2.upstream.BandwidthMeter
import com.google.android.exoplayer2.upstream.DataSource
import com.google.android.exoplayer2.upstream.DefaultBandwidthMeter
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import com.google.android.exoplayer2.util.Util
import com.maazter.rn.player.datasource.CustomHlsDataSourceFactory
import com.maazter.rn.player.downloader.DownloadUtil
import com.maazter.rn.player.listeners.PlayerListener
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import java.nio.charset.StandardCharsets
import java.io.File

import com.google.android.exoplayer2.SimpleExoPlayer
import com.google.android.exoplayer2.ExoPlayer
import androidx.core.content.ContentProviderCompat.requireContext
import com.google.android.exoplayer2.upstream.cache.*


class MaazterPlayerViewManager : SimpleViewManager<PlayerView?>() {
  private var player: SimpleExoPlayer? = null

  private var url: String? = null
  private var encKey: String? = null
  private var thumbUrl: String? = null
  private var resumeFrom: Float? = null
  private var downloadId: String? = null
  private var title: String? = null
  private var buttons: String? = null
  private var theme: String? = null

  override fun getName() = "MaazterPlayerView"

  override fun createViewInstance(reactContext: ThemedReactContext): PlayerView {
    val view = PlayerView(reactContext)
    initListeners(view)

    reactContext.addLifecycleEventListener(object : LifecycleEventListener {
      override fun onHostResume() {}
      override fun onHostPause() {
        view.pause()
      }
      override fun onHostDestroy() {}
    })

    return view
  }

  override fun onDropViewInstance(view: PlayerView) {
    super.onDropViewInstance(view)

    view.release();
  }

  private fun initListeners(view: PlayerView) {
    view.addListener(object : PlayerListener {
      override fun onCreate() {
        (view.context as ReactContext).getJSModule(RCTEventEmitter::class.java)
          .receiveEvent(view.id, "onCreate", null)
      }

      override fun onDestroy() {
        (view.context as ReactContext).getJSModule(RCTEventEmitter::class.java)
          .receiveEvent(view.id, "onDestroy", null)
      }

      override fun onFullscreenClick(isFullscreen: Boolean) {
        val event: WritableMap = Arguments.createMap()
        event.putBoolean("isFullscreen", isFullscreen)
        (view.context as ReactContext).getJSModule(RCTEventEmitter::class.java)
          .receiveEvent(view.id, "onFullscreenChange", event)
      }

      override fun onPlayStateChange(state: Int) {
        val event: WritableMap = Arguments.createMap()
        event.putInt("state", state)
        (view.context as ReactContext).getJSModule(RCTEventEmitter::class.java)
          .receiveEvent(view.id, "onPlayStateChange", event)
      }

      override fun onProgress(progress: Long, percent: Float, duration: Long) {
        val event: WritableMap = Arguments.createMap()
        event.putInt("progress", progress.toInt())
        event.putInt("duration", duration.toInt())
        event.putDouble("percent", percent.toDouble())
        (view.context as ReactContext).getJSModule(RCTEventEmitter::class.java)
          .receiveEvent(view.id, "onProgress", event)
      }

      override fun onQualityChange(quality: String) {
        val event: WritableMap = Arguments.createMap()
        event.putString("quality", quality)
        (view.context as ReactContext).getJSModule(RCTEventEmitter::class.java)
          .receiveEvent(view.id, "onQualityChange", event)
      }

      override fun onPlaybackSpeedChange(speed: Float) {
        val event: WritableMap = Arguments.createMap()
        event.putDouble("speed", speed.toDouble())
        (view.context as ReactContext).getJSModule(RCTEventEmitter::class.java)
          .receiveEvent(view.id, "onPlaybackSpeedChange", event)
      }

      override fun onVideoSizeChange(width: Int, height: Int) {
        val event: WritableMap = Arguments.createMap()
        event.putInt("width", width)
        event.putInt("height", height)
        (view.context as ReactContext).getJSModule(RCTEventEmitter::class.java)
          .receiveEvent(view.id, "onVideoSizeChange", event)
      }

      override fun onBackClick() {
        (view.context as ReactContext).getJSModule(RCTEventEmitter::class.java)
          .receiveEvent(view.id, "onBackClick", null)
      }

      override fun onPreviousClick() {
        (view.context as ReactContext).getJSModule(RCTEventEmitter::class.java)
          .receiveEvent(view.id, "onPreviousClick", null)
      }

      override fun onNextClick() {
        (view.context as ReactContext).getJSModule(RCTEventEmitter::class.java)
          .receiveEvent(view.id, "onNextClick", null)
      }

      override fun onSettingsClick() {
        (view.context as ReactContext).getJSModule(RCTEventEmitter::class.java)
          .receiveEvent(view.id, "onSettingsClick", null)
      }

      override fun onError() {
        (view.context as ReactContext).getJSModule(RCTEventEmitter::class.java)
          .receiveEvent(view.id, "onError", null)
      }
    })
  }

  fun getScreenSizeInlcudingTopBottomBar(context: Context): IntArray {
    val screenDimensions = IntArray(2) // width[0], height[1]
    val x: Int
    val y: Int
    val orientation = context.resources.configuration.orientation
    val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    val display = wm.defaultDisplay
    val screenSize = Point()
    display.getRealSize(screenSize)
    x = screenSize.x
    y = screenSize.y
    screenDimensions[0] = if (orientation == Configuration.ORIENTATION_PORTRAIT) x else y // width
    screenDimensions[1] = if (orientation == Configuration.ORIENTATION_PORTRAIT) y else x // height
    return screenDimensions
  }

  private val COMMAND_PLAY = 1
  private val COMMAND_PAUSE = 2
  private val COMMAND_RESIZE_MODE = 3
  private val COMMAND_FULLSCREEN = 4

  override fun getCommandsMap(): Map<String, Int>? {
    return MapBuilder.of(
      "play", COMMAND_PLAY,
      "pause", COMMAND_PAUSE,
      "setResizeMode", COMMAND_RESIZE_MODE,
      "setFullscreen", COMMAND_FULLSCREEN
    )
  }

  override fun receiveCommand(root: PlayerView, commandId: Int, args: ReadableArray?) {
    when (commandId) {
      COMMAND_PLAY -> {
        root.play()
      }
      COMMAND_PAUSE -> {
        root.pause()
      }
      COMMAND_RESIZE_MODE -> {
        when (args?.getString(0)) {
          "zoom" -> root.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
          "fill" -> root.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FILL
          "fit" -> root.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
          "fixed-height" -> root.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIXED_HEIGHT
          "fixed-width" -> root.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIXED_WIDTH
        }
      }
      COMMAND_FULLSCREEN -> {
        when (args?.getBoolean(0)) {
          true -> root.fullscreenEnter()
          false -> root.fullscreenExit()
        }
      }
      else -> null
    }
  }

  override fun getExportedCustomBubblingEventTypeConstants(): MutableMap<String, Any>? {
    val events = listOf("onCreate", "onDestroy", "onFullscreenChange",
      "onPlayStateChange", "onProgress", "onQualityChange", "onPlaybackSpeedChange",
      "onBackClick", "onPreviousClick", "onNextClick", "onSettingsClick", "onVideoSizeChange",
      "onError"
    )
    val map = MapBuilder.builder<String, Any>();
    events.forEach {
      map.put(it, MapBuilder.of("phasedRegistrationNames", MapBuilder.of("bubbled", it)))
    }

    return map
      .build()
  }

  @ReactProp(name = "theme")
  fun setTheme(view: PlayerView, theme: String) {
    view.setTheme(theme)
  }

  @ReactProp(name = "buttonState")
  fun setButtons(view: PlayerView, buttons: ReadableMap?) {
    if (buttons == null) return

    view.setButtonState("next", buttons.getBoolean("next"))
    view.setButtonState("previous", buttons.getBoolean("previous"))
    view.setButtonState("settings", buttons.getBoolean("settings"))
  }

  @ReactProp(name = "markers")
  fun setMarkers(view: PlayerView, markers: ReadableArray) {

    var arr = LongArray(markers.size()) { (markers.getInt(it) * 1000).toLong() }
    var boolArr = BooleanArray(markers.size()) { false }

    view.setExtraAdGroupMarkers(
      arr,
      boolArr
    )

  }

  @ReactProp(name = "source")
  fun setVideo(view: PlayerView, video: ReadableMap?) {
    if (video == null) return

    url = video.getString("url")
    encKey = video.getString("encKey")
    thumbUrl = video.getString("thumbUrl")
    downloadId = video.getString("downloadId")
    resumeFrom = video.getDouble("resumeFrom").toFloat()
    title = video.getString("title")

    loadPlayer(view)
  }

  @ReactProp(name = "resizeMode")
  fun setResizeMode(view: PlayerView, mode: String?) {
    when (mode) {
      "zoom" -> view.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
      "fill" -> view.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FILL
      "fit" -> view.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
      "fixed-height" -> view.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIXED_HEIGHT
      "fixed-width" -> view.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIXED_WIDTH
    }
  }

  private fun getDownloadRequest(context: Context, contentId: String): DownloadRequest? {
    val downloadManager = DownloadUtil.getDownloadManager(context)
    val downloads = downloadManager?.downloadIndex?.getDownloads() ?: return null

    downloads.moveToFirst()
    while (!downloads.isAfterLast) {
      if (downloads.download.request.id == contentId) {
        return downloads.download.request
      }

      downloads.moveToNext()
    }

    return null
  }

  private fun loadPlayer(videoView: PlayerView) {
    if (url == null) {
      return
    }

    if (player != null) {
      player?.release()
      player = null
    }


    var mediaItem: MediaItem = MediaItem.fromUri(url!!)
    var dataSourceFactory: DataSource.Factory = DefaultDataSourceFactory(videoView.context)
    val mediaSource: MediaSource

    if (downloadId != null) {
      val request = getDownloadRequest(videoView.context, downloadId!!)
      if (request != null) {
        mediaItem = request.toMediaItem()
        dataSourceFactory = DownloadUtil.getDataSourceFactory(videoView.context)!!
      }
    }

    when (Util.inferContentType(Uri.parse(url))) {
      C.TYPE_HLS -> {
        if (encKey != null) {
          dataSourceFactory = CustomHlsDataSourceFactory(dataSourceFactory, getEncKey())
        }

        val bandwidthMeter: BandwidthMeter = DefaultBandwidthMeter
          .Builder(videoView.context)
          .setInitialBitrateEstimate(0)
          .build()

        val load = DefaultLoadControl.Builder()
          .setBufferDurationsMs(15000, 50000, 2500, 5000)
          .build()

        val cacheDataSourceFactory: DataSource.Factory = CacheDataSource.Factory()
          .setCache(getSimpleCacheInstance(videoView.context))
          .setUpstreamDataSourceFactory(dataSourceFactory)
          .setFlags(CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR or CacheDataSource.FLAG_BLOCK_ON_CACHE)

        val trackSelector = DefaultTrackSelector(videoView.context)
        trackSelector.setParameters(
          trackSelector
            .buildUponParameters()
            .setMaxVideoSize(854, 480)
            .setForceHighestSupportedBitrate(false)
        )

        player = SimpleExoPlayer
          .Builder(videoView.context)
          .setTrackSelector(trackSelector)
          .setBandwidthMeter(bandwidthMeter)
          .setLoadControl(load)
          .build()

        mediaSource = HlsMediaSource
          .Factory(cacheDataSourceFactory)
          .setAllowChunklessPreparation(true)
          .createMediaSource(mediaItem)
      }

      C.TYPE_DASH -> {
        mediaSource = DashMediaSource
          .Factory(dataSourceFactory)
          .createMediaSource(mediaItem)
      }

      C.TYPE_RTSP -> {
        mediaSource = RtspMediaSource
          .Factory()
          .createMediaSource(mediaItem)
      }

      C.TYPE_SS -> {
        mediaSource = SsMediaSource
          .Factory(dataSourceFactory)
          .createMediaSource(mediaItem)
      }

      else -> {
        mediaSource = ProgressiveMediaSource
          .Factory(dataSourceFactory)
          .createMediaSource(mediaItem)
      }
    }

    if (player == null) {
      player = SimpleExoPlayer
        .Builder(videoView.context)
        .setTrackSelector(DefaultTrackSelector(videoView.context))
        .build()
    }

    videoView.player = player

    player?.setMediaSource(mediaSource)
    player?.prepare()

    if (thumbUrl != null) {
      videoView.setThumbnail(thumbUrl!!)
    }
    videoView.setVideoTitle(title)

    videoView.playFromPercentile = if (resumeFrom == null) 0f else resumeFrom

    player?.playWhenReady = true
  }

  private fun getSimpleExoPlayer(videoView: PlayerView, urlPath: String): SimpleExoPlayer {
    val player = SimpleExoPlayer.Builder(videoView.context).build()
    videoView.player = player
    val mediaItem: MediaItem = MediaItem.fromUri(urlPath)
    player.setMediaItem(mediaItem)
    return player
  }

  private fun getEncKey(): ByteArray {
    return encKey!!.toByteArray(StandardCharsets.UTF_8)
  }

  private fun drawableFromUrl(url: String?, videoView: PlayerView) {
    val background = Thread {
      try {
        val x: Bitmap
        val connection: HttpURLConnection = URL(url).openConnection() as HttpURLConnection
        Log.e("err", url!!)
        connection.connect()
        val input: InputStream = connection.inputStream
        x = BitmapFactory.decodeStream(input)
        videoView.background = BitmapDrawable(Resources.getSystem(), x)
        videoView.defaultArtwork = videoView.background
        videoView.useArtwork = true;

      } catch (t: Throwable) {

      }
    }
    background.start()
  }

  private fun hexStringToByteArray(s: String): ByteArray {
    val len = s.length
    val data = ByteArray(len / 2)
    var i = 0
    while (i < len) {
      data[i / 2] = ((Character.digit(s[i], 16) shl 4)
        + Character.digit(s[i + 1], 16)).toByte()
      i += 2
    }
    return data
  }

  companion object {
    const val REACT_CLASS = "VideoView"
    var simpleCacheInstanceObj: SimpleCache? = null

    fun getSimpleCacheInstance(context: Context): SimpleCache {
      if (simpleCacheInstanceObj === null) {
        val evictor = LeastRecentlyUsedCacheEvictor((1024 * 1024 * 1024).toLong())
        val databaseProvider: DatabaseProvider = ExoDatabaseProvider(context)
        simpleCacheInstanceObj = SimpleCache(File(context.cacheDir, "exo"), evictor, databaseProvider);
      }

      return simpleCacheInstanceObj!!
    }
  }
}
