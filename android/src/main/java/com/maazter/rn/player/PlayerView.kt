package com.maazter.rn.player

import android.annotation.SuppressLint
import android.content.Context
import android.content.res.ColorStateList
import android.content.res.Resources
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.drawable.BitmapDrawable
import android.os.Handler
import android.util.AttributeSet
import android.util.Log
import android.util.TypedValue
import android.view.*
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.core.widget.NestedScrollView
import androidx.interpolator.view.animation.FastOutSlowInInterpolator
import com.facebook.react.uimanager.ThemedReactContext
import com.github.vkay94.dtpv.DoubleTapPlayerView
import com.github.vkay94.dtpv.youtube.YouTubeOverlay
import com.google.android.exoplayer2.*
import com.google.android.exoplayer2.source.TrackGroupArray
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector.SelectionOverride
import com.google.android.exoplayer2.trackselection.MappingTrackSelector.MappedTrackInfo
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout
import com.google.android.exoplayer2.ui.DefaultTimeBar
import com.google.android.exoplayer2.video.VideoSize
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.google.android.material.snackbar.Snackbar
import com.maazter.rn.player.PlayerView.ProgressTracker.PositionListener
import com.maazter.rn.player.listeners.PlayerListener
import rm.com.youtubeplayicon.PlayIconDrawable
import rm.com.youtubeplayicon.PlayIconDrawable.IconState
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL


class PlayerView @JvmOverloads constructor(
  context: Context?, attrs: AttributeSet? = null, defStyleAttr: Int = 0
) : DoubleTapPlayerView(context, attrs, defStyleAttr) {

  companion object {
    class BsItem<T>(var name: String, var value: T, var selected: Boolean? = false)
    class QualityItem(var format: Format, var groupIndex: Int, var trackIndex: Int)
  }

  private var selectedQuality = -1
  private var fullscreen = false

  private var thumbnailView: ImageView = findViewById(R.id.ytp_thumbnail)
  private var thumbnailHidden = false

  private val events = PlayerEventEmitter()
  private val playerControl: PlayerControl = PlayerControl(this);
  private var progressTracker: ProgressTracker? = null

  private var scaleGestureDetector: ScaleGestureDetector? = ScaleGestureDetector(context, ScaleGestureListener(this))

  private lateinit var playButton: PlayIconDrawable

  var playFromPercentile: Float? = null
  var themeColor = "#ff0000"
  var playerNeedsPrepare = false

  init {
    init()
  }

  @SuppressLint("ClickableViewAccessibility")
  private fun init() {
    val playButtonView = findViewById<ImageView>(R.id.ytp_play)

    playButton = PlayIconDrawable.builder()
      .withColor(Color.WHITE)
      .withInterpolator(FastOutSlowInInterpolator())
      .withDuration(300)
      .withInitialState(IconState.PAUSE)
      .withStateListener { state ->
        run {
          when (state) {
            IconState.PLAY -> player?.pause()
            IconState.PAUSE -> {
              if (playerNeedsPrepare) {
                player?.prepare()
              }
              player?.play()
            }
          }
        }
      }
      .into(playButtonView)

    playButtonView.setOnClickListener {
      playButton.toggle(true)
    }

    resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT

    setShowBuffering(SHOW_BUFFERING_NEVER)
    controllerShowTimeoutMs = 0
    controllerHideOnTouch = false

    findViewById<YouTubeOverlay>(R.id.ytp_skip_overlay)
      .playerView(this)

    findViewById<ImageButton>(R.id.ytp_speed).setOnClickListener {
      try {
        showSpeedSelector()
      } catch (e: Exception) {
      }
    }

    findViewById<ImageButton>(R.id.ytp_quality).setOnClickListener {
      try {
        showQualitySelector()
      } catch (e: Exception) {
      }
    }

    findViewById<ImageButton>(R.id.ytp_fullscreen).setOnClickListener {
      toggleFullscreen()
    }

    findViewById<ImageButton>(R.id.ytp_replay).setOnClickListener {
      player?.seekTo(0);
      player?.playWhenReady = true;

      events.onReplay()
    }

    findViewById<ImageButton>(R.id.ytp_back).setOnClickListener {
      events.onBackClick()
    }

    findViewById<ImageButton>(R.id.ytp_next).setOnClickListener {
      events.onNextClick()
    }

    findViewById<ImageButton>(R.id.ytp_prev).setOnClickListener {
      events.onPreviousClick()
    }

    findViewById<ImageButton>(R.id.ytp_settings).setOnClickListener {
      events.onSettingsClick()
    }
  }

  private var layoutRequested = false;
  override fun requestLayout() {
    super.requestLayout()

    if (!layoutRequested) {
      layoutRequested = true
      post {
        measureAndLayout()
        postDelayed({
          layoutRequested = false
        }, 250)
      }
    }
  }

  private fun measureAndLayout() {
    measure(
      MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY),
      MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY)
    )
    layout(left, top, right, bottom)
  }

  override fun onTouchEvent(ev: MotionEvent): Boolean {
    if (fullscreen) {
      scaleGestureDetector?.onTouchEvent(ev)

    }
    return super.onTouchEvent(ev)
  }

  private fun toggleFullscreen() {
    if (fullscreen) {
      events.onFullscreenClick(false)
    } else {
      events.onFullscreenClick(true)
    }
  }

  fun fullscreenEnter() {
/*    val activity = (context as ThemedReactContext).baseContext as AppCompatActivity
    val fullscreenButton = findViewById<ImageButton>(R.id.ytp_fullscreen)

    fullscreenButton.setImageDrawable(ContextCompat.getDrawable(context, R.drawable.ic_player_fullscreen_exit))
    activity.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE

    UiThreadUtil.runOnUiThread {
      activity.window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_FULLSCREEN
    }*/

    fullscreen = true
    events.onFullscreenChange(true)
  }

  fun fullscreenExit() {
//    resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT

/*    val activity = (context as ThemedReactContext).baseContext as AppCompatActivity
    val fullscreenButton = findViewById<ImageButton>(R.id.ytp_fullscreen)

    fullscreenButton.setImageDrawable(ContextCompat.getDrawable(context, R.drawable.ic_player_fullscreen))
    activity.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT

    UiThreadUtil.runOnUiThread {
      activity.window.decorView.systemUiVisibility = (SYSTEM_UI_FLAG_LAYOUT_STABLE
        or SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        or SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN)
    }*/

    if (resizeMode != AspectRatioFrameLayout.RESIZE_MODE_FIT) {
      changeResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FIT)
    }

    fullscreen = false
    events.onFullscreenChange(false)
  }

  fun changeResizeMode(mode: Int) {
    resizeMode = mode
    events.onChangeResizeMode(mode)
    measureAndLayout()
  }

  private fun showSpeedSelector() {
    val speeds = listOf(
      BsItem("0.25x", 0.25f),
      BsItem("0.5x", 0.5f),
      BsItem("0.75x", 0.75f),
      BsItem("Normal", 1f),
      BsItem("1.25x", 1.25f),
      BsItem("1.5x", 1.5f),
      BsItem("1.75x", 1.75f),
      BsItem("2", 2f)
    )

    val speed = player?.playbackParameters?.speed;
    showBottomSheetDialog(
      speeds.map { it.selected = speed == it.value; it },
      { item: BsItem<Float>, sheet: BottomSheetDialog ->
        run {
          player?.setPlaybackSpeed(item.value)
          sheet.dismiss()
          events.onPlaybackSpeedChange(item.value)
        }
      },
      "Speed"
    )
  }

  private fun showQualitySelector() {
    var trackGroups: TrackGroupArray? = null
    var rendererIndex: Int? = null

    val player = (player as SimpleExoPlayer)
    val trackSelector = (player.trackSelector as DefaultTrackSelector)

    val mappedTrackInfo: MappedTrackInfo = trackSelector.currentMappedTrackInfo!!
    loop@ for (i in 0 until mappedTrackInfo.rendererCount) {
      trackGroups = mappedTrackInfo.getTrackGroups(i)
      if (trackGroups.length != 0) {
        when (player.getRendererType(i)) {
          C.TRACK_TYPE_VIDEO -> {
            rendererIndex = i;
            break@loop
          }
        }
      }
    }

    rendererIndex!!
    trackGroups!!

    val quality: ArrayList<BsItem<QualityItem>> = ArrayList()

    for (i in 0 until trackGroups.length) {
      quality.add(BsItem("Auto", QualityItem(Format.Builder().build(), i, -1)))
      val group = trackGroups.get(i)
      for (j in 0 until group.length) {
        val format = group.getFormat(j)
        val height = format.height.toInt()

        if(height != 1080 && height != 720)
        {
          var qualityName: String;

          //change this in bottom sheet too
          when (height) {
            240 -> qualityName = "Low"
            360 -> qualityName = "Medium"
            480 -> qualityName = "High"
            else -> {
              qualityName = height.toString() + "p"
            }
          }

          quality.add(BsItem(qualityName, QualityItem(format, i, j), false))
        }

      }
    }

    showBottomSheetDialog(
      quality.map { it.selected = it.value.trackIndex == selectedQuality; it },
      { item: BsItem<QualityItem>, sheet: BottomSheetDialog ->
        run {
          var tracks: IntArray = intArrayOf()
          if (item.value.trackIndex == -1) {
            for (i in 0 until trackGroups.length) {
              tracks = IntArray(trackGroups.get(i).length) { it }
            }
          } else {
            tracks = intArrayOf(item.value.trackIndex)
          }

          selectedQuality = item.value.trackIndex
          trackSelector.parameters = trackSelector.buildUponParameters()
            .setSelectionOverride(rendererIndex, trackGroups, SelectionOverride(item.value.groupIndex, *tracks))
            .build()
          sheet.dismiss()

          var name: String;

          when(item.name)
          {
            "SD - upto 480p" -> name = "SD"
            "HD - upto 720p" -> name = "HD"
            "Full HD - upto 1080p" -> name = "Full HD"
            else -> {
              name = item.name
            }
          }

          Snackbar
            .make(this, "$name will apply to your current video", Snackbar.LENGTH_SHORT)
            .setTextColor(Color.WHITE)
            .show()

          events.onQualityChange(item.name)
        }
      },
      "Quality"
    )
  }

  private fun <T> showBottomSheetDialog(data: List<BsItem<T>>, callback: (BsItem<T>, BottomSheetDialog) -> Unit, title: String? = null): BottomSheetDialog {

    val bottomSheetDialog = BottomSheetDialog(this.context)

    val parent = LinearLayout(context);
    parent.orientation = LinearLayout.VERTICAL
    parent.layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.MATCH_PARENT)

    val px8 = DensityUtil.dip2px(context, 8f)
    val px24 = DensityUtil.dip2px(context, 24f)

    data.forEachIndexed { index, item ->
      val elRoot = LinearLayout(context)
      elRoot.layoutParams = LinearLayout.LayoutParams(
        LinearLayout.LayoutParams.MATCH_PARENT,
        LinearLayout.LayoutParams.WRAP_CONTENT
      )
      elRoot.orientation = LinearLayout.HORIZONTAL
      elRoot.setPadding(px8, px8, px8, px8)
      elRoot.isClickable = true
      elRoot.isFocusable = true
      elRoot.background = with(TypedValue()) {
        context.theme.resolveAttribute(
          R.attr.selectableItemBackground, this, true
        )
        ContextCompat.getDrawable(context, resourceId)
      }
      elRoot.setOnClickListener { callback(item, bottomSheetDialog) }

      val imgLP = LayoutParams(px24, px24);
      imgLP.setMargins(px8, px8, px8, px8)

      val imageView = ImageView(context)
      imageView.layoutParams = imgLP
      imageView.setColorFilter(Color.parseColor("#000000"))

      if (item.selected == true) {
        imageView.setImageDrawable(
          context.resources.getDrawable(
            R.drawable.ic_player_done_black,
            null
          )
        )
      }

      val txtLP = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)
      txtLP.gravity = Gravity.CENTER_VERTICAL

      val textView = TextView(context)
      textView.layoutParams = txtLP
      textView.text = item.name
      textView.setPadding(px8, px8, px8, px8)

      elRoot.addView(imageView, 0)
      elRoot.addView(textView, 1)

      parent.addView(elRoot, index)
    }

    val scroll = NestedScrollView(context)
    scroll.addView(parent)

    bottomSheetDialog.setTitle(title)
    bottomSheetDialog.setContentView(scroll)
    bottomSheetDialog.dismissWithAnimation = true
    bottomSheetDialog.show()

    if (fullscreen) {
      val bottomSheet =
        bottomSheetDialog.findViewById<FrameLayout>(com.google.android.material.R.id.design_bottom_sheet)
      val behavior: BottomSheetBehavior<*> = BottomSheetBehavior.from<FrameLayout?>(bottomSheet!!)
      behavior.state = BottomSheetBehavior.STATE_EXPANDED
      behavior.peekHeight = height
    }

    return bottomSheetDialog
  }

  fun setThumbnail(url: String) {
    val background = Thread {
      try {
        val connection: HttpURLConnection = URL(url).openConnection() as HttpURLConnection
        connection.connect()
        val input: InputStream = connection.inputStream
        val drawable = BitmapDrawable(Resources.getSystem(), BitmapFactory.decodeStream(input))
        thumbnailView.setImageDrawable(drawable)
      } catch (t: Throwable) {
      }
    }
    background.start()
  }

  fun setTheme(color: String) {
    themeColor = color;
    val progressBar = findViewById<ProgressBar>(R.id.ytp_loader)
    val seekBar = findViewById<DefaultTimeBar>(R.id.exo_progress)

    val parsedTheme = Color.parseColor(themeColor)
    progressBar.indeterminateTintList = ColorStateList.valueOf(parsedTheme)
    seekBar.setPlayedColor(parsedTheme)
    seekBar.setScrubberColor(parsedTheme)
  }

  fun setVideoTitle(title: String?) {
    val titleView = findViewById<TextView>(R.id.ytp_video_title)

    if (title == null) {
      titleView.text = ""
      titleView.visibility = INVISIBLE
      return
    }

    titleView.text = title
    titleView.visibility = VISIBLE
  }

  fun setButtonState(button: String, isEnabled: Boolean) {
    val btn = when(button) {
      "next" -> findViewById<ImageButton>(R.id.ytp_next)
      "previous" -> findViewById<ImageButton>(R.id.ytp_prev)
      "settings" -> {
        val settingsView = findViewById<ImageButton>(R.id.ytp_settings);
        if (isEnabled) {
          settingsView.visibility = VISIBLE
        } else {
          settingsView.visibility = GONE
        }
        return
      }
      else -> null
    }

    btn?.imageAlpha = if(isEnabled) 255 else 125
    btn?.isEnabled = isEnabled
  }

  fun play() {
    playButton.animateToState(IconState.PAUSE)
  }

  fun pause() {
    playButton.animateToState(IconState.PLAY)
  }

  fun release() {
    progressTracker?.purgeHandler();
    player?.release()
    player = null;
  }

  private fun initDoubleTapPlayerView() {
    val overlay = findViewById<YouTubeOverlay>(R.id.ytp_skip_overlay)
    overlay
      .player(player!!)
      .playerView(this)

    controller(overlay)
  }

  var lastPlayState: Int = 0;
  private fun initPlayer() {

    initDoubleTapPlayerView()

    setTheme(themeColor)
    thumbnailHidden = false

    player!!.addListener(object : Player.Listener {
      override fun onPlayerStateChanged(playWhenReady: Boolean, playbackState: Int) {
        when (playbackState) {
          Player.STATE_BUFFERING -> {
            playerNeedsPrepare = false
            events.onBuffering()
          }
          Player.STATE_READY -> {
            events.onReady()

            if (lastPlayState == 3) {
              lastPlayState = if (playWhenReady) 1 else 2;
              events.onPlayStateChange(lastPlayState)
            }
          }
          Player.STATE_ENDED -> {
            lastPlayState = 3
            events.onPlayStateChange(3)
          }
          Player.STATE_IDLE -> {
          }
        }

        keepScreenOn =
          !(playbackState == Player.STATE_IDLE || playbackState == Player.STATE_ENDED || !playWhenReady)
      }

      override fun onTimelineChanged(timeline: Timeline, reason: Int) {
        if (reason == ExoPlayer.TIMELINE_CHANGE_REASON_SOURCE_UPDATE && !thumbnailHidden) {
          playerInitialized()
        }
      }

      override fun onPlayWhenReadyChanged(playWhenReady: Boolean, reason: Int) {
        lastPlayState = if (playWhenReady) 1 else 2
        events.onPlayStateChange(lastPlayState)
      }

      override fun onPlayerError(error: ExoPlaybackException) {
        pause()
        playerNeedsPrepare = true
        events.onError()
      }

      override fun onVideoSizeChanged(videoSize: VideoSize) {
        events.onVideoSizeChange(videoSize.width, videoSize.height)
      }
    })
  }

  fun hideSystemUi() {
    val activity = (context as ThemedReactContext).baseContext as AppCompatActivity
    val decorView: View = activity.window.decorView
    decorView.systemUiVisibility = (SYSTEM_UI_FLAG_LAYOUT_STABLE
      or SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
      or SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
      or SYSTEM_UI_FLAG_HIDE_NAVIGATION
      or SYSTEM_UI_FLAG_FULLSCREEN
      or SYSTEM_UI_FLAG_IMMERSIVE_STICKY)
  }

  override fun onWindowFocusChanged(hasWindowFocus: Boolean) {
    super.onWindowFocusChanged(hasWindowFocus)

    if (hasWindowFocus && fullscreen) {
      hideSystemUi();
    }
  }

  private var layoutOnHour = false
  private fun playerInitialized() {
    thumbnailView.animate().alpha(0f).duration = 200
    thumbnailHidden = true;

    if (progressTracker != null) {
      progressTracker?.purgeHandler()
    }

    layoutOnHour = false
    progressTracker = ProgressTracker(player!!, object : PositionListener {
      override fun progress(position: Long) {
        val percent = ((position * 100) / player!!.duration)
        events.onProgress(position, percent.toFloat(), player!!.duration)

        if (!layoutOnHour && player!!.duration >= 3600000) {
          measureAndLayout()
          layoutOnHour = true
        }
      }
    })

    if (playFromPercentile != null) {
      val playFrom = (player!!.duration * playFromPercentile!!)/100
      player!!.seekTo(playFrom.toLong())
    }

    measureAndLayout()
  }

  override fun setPlayer(player: Player?) {
    super.setPlayer(player)
    if (player != null) {
      initPlayer();
    }
  }

  fun addListener(listener: PlayerListener) {
    events.addListener(listener)
  }

  internal class PlayerEventEmitter {
    private val listeners: MutableList<PlayerListener> = ArrayList()
    fun addListener(listener: PlayerListener) {
      listeners.add(listener)
    }

    fun onBuffering() {
      for (listener in listeners) listener.onBuffering()
    }

    fun onReady() {
      for (listener in listeners) listener.onReady()
    }

    fun onReplay() {
      for (listener in listeners) listener.onReplay()
    }

    fun onChangeResizeMode(mode: Int) {
      for (listener in listeners) listener.onChangeResizeMode(mode)
    }

    fun onIdle() {
      for (listener in listeners) listener.onIdle()
    }

    fun onError() {
      for (listener in listeners) listener.onError()
    }

    /**/
    fun onProgress(progress: Long, percent: Float, duration: Long) {
      for (listener in listeners) listener.onProgress(progress, percent, duration)
    }

    fun onFullscreenChange(isFullscreen: Boolean) {
      for (listener in listeners) listener.onFullscreenChange(isFullscreen)
    }

    fun onQualityChange(quality: String) {
      for (listener in listeners) listener.onQualityChange(quality)
    }

    fun onPlaybackSpeedChange(speed: Float) {
      for (listener in listeners) listener.onPlaybackSpeedChange(speed)
    }

    fun onPlayStateChange(state: Int) {
      for (listener in listeners) listener.onPlayStateChange(state)
    }

    fun onVideoSizeChange(width: Int, height: Int) {
      for (listener in listeners) listener.onVideoSizeChange(width, height)
    }

    fun onCreate() {
      for (listener in listeners) listener.onCreate()
    }

    fun onDestroy() {
      for (listener in listeners) listener.onDestroy()
    }

    fun onNextClick() {
      for (listener in listeners) listener.onNextClick()
    }

    fun onPreviousClick() {
      for (listener in listeners) listener.onPreviousClick()
    }

    fun onBackClick() {
      for (listener in listeners) listener.onBackClick()
    }

    fun onSettingsClick() {
      for (listener in listeners) listener.onSettingsClick()
    }

    fun onFullscreenClick(isFullscreen: Boolean) {
      for (listener in listeners) listener.onFullscreenClick(isFullscreen)
    }
  }

  class ProgressTracker(private val player: Player, private val positionListener: PositionListener) : Runnable {
    interface PositionListener {
      fun progress(position: Long)
    }

    private val handler: Handler = Handler()
    override fun run() {
      val position = player.currentPosition
      positionListener.progress(position)
      handler.postDelayed(this, 1000)
    }

    fun purgeHandler() {
      handler.removeCallbacks(this)
    }

    init {
      handler.post(this)
    }
  }


  class ScaleGestureListener(private val playerView: PlayerView) : ScaleGestureDetector.SimpleOnScaleGestureListener() {
    private var scaleFactor = 0f

    override fun onScale(detector: ScaleGestureDetector): Boolean {
      scaleFactor = detector.scaleFactor
      return true
    }

    override fun onScaleBegin(detector: ScaleGestureDetector): Boolean {
      return true
    }

    override fun onScaleEnd(detector: ScaleGestureDetector) {
      if (scaleFactor > 1) {
        playerView.changeResizeMode(AspectRatioFrameLayout.RESIZE_MODE_ZOOM)
      } else {
        playerView.changeResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FIT)
      }
    }
  }
}
