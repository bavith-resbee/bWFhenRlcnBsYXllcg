package com.maazter.rn.player

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.view.View
import android.widget.*
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.updateLayoutParams
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.UiThreadUtil
import com.facebook.react.uimanager.annotations.ReactProp
import com.github.vkay94.dtpv.youtube.YouTubeOverlay
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout
import com.google.android.exoplayer2.ui.DefaultTimeBar
import com.google.android.exoplayer2.ui.TimeBar
import com.maazter.rn.player.listeners.PlayerListener
import java.util.*


class PlayerControl(private val playerView: PlayerView) {
  var isHidden = true
    set(value) {
      field = value

      if (!value) {
        showControls()
      } else {
        hideControls()
      }
    }

  var isFullscreen = false
    set(value) {
      field = value

      if (value) setFullscreenLayout()
      else setNormalLayout()
    }

  var isBuffering = false
    set(value) {
      field = value;
      if (value) {
        showBuffering()
      } else {
        hideBuffering()
        tryShowControls()
      }
    }

  var playStatus = PlayStatus.PAUSED
    set(value) {
      field = value

      when(value) {
        PlayStatus.PLAYING -> {
          showPlay()
          setHideTimer()
        }
        PlayStatus.PAUSED -> {
          showPlay()
          showControls()
        }
        PlayStatus.ENDED -> {
          showReplay()
          showControls()
        }
      }
    }

  var seekStatus = SeekStatus.NONE
    set(value) {
      val prev = field
      field = value

      if (value == SeekStatus.NONE) {
        hideInfo()
        if (prev != SeekStatus.FAST_SEEK) {
          showControls()
        } else {
          refreshControls()
        }
        return
      }

      hideControls(SeekStatus.FAST_SEEK != value)

      when (value) {
        SeekStatus.FAST_SEEK -> {
          bufferingView.alpha= 0.5F
        }
        SeekStatus.SEEKING -> {
          showInfo("seeking")
        }
        SeekStatus.SEEK_START -> {
          showInfo("seek_start")
        }
        else -> {}
      }
    }

  enum class PlayStatus {
    PLAYING, PAUSED, ENDED
  }

  enum class SeekStatus {
    SEEKING, FAST_SEEK, SEEK_START, NONE
  }

  private val playButton: ImageButton = playerView.findViewById(R.id.ytp_play)
  private val replayButton: ImageButton = playerView.findViewById(R.id.ytp_replay)
  private val bufferingView: ProgressBar = playerView.findViewById(R.id.ytp_loader)

  private val viewSectionTop: ConstraintLayout = playerView.findViewById(R.id.ytp_control_section_top)
  private val viewSectionMiddle: LinearLayout = playerView.findViewById(R.id.ytp_control_section_middle)
  private val viewSectionBottom: FrameLayout = playerView.findViewById(R.id.ytp_control_section_bottom)
  private val controls: FrameLayout = playerView.findViewById(R.id.ytp_controls)
  private val infoView: TextView = playerView.findViewById(R.id.ytp_info)
  private val infoSeekingView: LinearLayout = playerView.findViewById(R.id.ytp_info_seeking)
  private val controlsOverlay: FrameLayout = playerView.findViewById(R.id.ytp_controls_overlay)
  private val contentFrame: AspectRatioFrameLayout = playerView.findViewById(R.id.exo_content_frame)
  private val uiBottomAdjustmentView: FrameLayout = playerView.findViewById(R.id.ytp_ui_bottom_adjustment)
  private val controlView: FrameLayout = playerView.findViewById(R.id.ytp_player_view)

  private val seeker = playerView.findViewById<DefaultTimeBar>(R.id.exo_progress)
  private var hideTimer: Timer? = null
  private var infoTimer: Timer? = null

  init {
    playerView.setOnClickListener {
      isHidden = !isHidden
    }

    playerView.addListener(object : PlayerListener {
      override fun onBuffering() { isBuffering = true }
      override fun onReady() { isBuffering = false }
      override fun onReplay() { playStatus = PlayStatus.PLAYING }
      override fun onFullscreenChange(isFullscreen: Boolean) { this@PlayerControl.isFullscreen = isFullscreen }
      override fun onPlayStateChange(state: Int) {
        playStatus = when(state) {
          1 -> PlayStatus.PLAYING
          2 -> PlayStatus.PAUSED
          3 -> PlayStatus.ENDED
          else -> PlayStatus.PLAYING
        }
      }
      override fun onError() { isBuffering = false }
      override fun onChangeResizeMode(mode: Int) {
        hideControls(false)
        when (mode) {
          AspectRatioFrameLayout.RESIZE_MODE_FIT -> { hideControls(); showInfo("resize-mode-fit") }
          AspectRatioFrameLayout.RESIZE_MODE_ZOOM -> { hideControls(); showInfo("resize-mode-zoom") }
        }
      }
    })

    val overlay = playerView.findViewById<YouTubeOverlay>(R.id.ytp_skip_overlay)
    overlay
      .performListener(object : YouTubeOverlay.PerformListener {
        override fun onAnimationStart() {
          seekStatus = SeekStatus.FAST_SEEK
          overlay.visibility = View.VISIBLE
        }

        override fun onAnimationEnd() {
          seekStatus = SeekStatus.NONE
          overlay.visibility = View.INVISIBLE
        }
      })

    val progress = playerView.findViewById<DefaultTimeBar>(R.id.exo_progress)
    progress.addListener(object : TimeBar.OnScrubListener {
      override fun onScrubMove(timeBar: TimeBar, position: Long) {
        seekStatus = SeekStatus.SEEKING;
      }

      override fun onScrubStart(timeBar: TimeBar, position: Long) {
        seekStatus = SeekStatus.SEEK_START
      }

      override fun onScrubStop(timeBar: TimeBar, position: Long, canceled: Boolean) {
        seekStatus = SeekStatus.NONE
      }
    })

    UiThreadUtil.runOnUiThread {
      hideControls()
    }
  }

  private fun refreshControls() {
    if (isBuffering) {
      showBuffering()
    } else {
      hideBuffering()
    }

    if (isHidden) {
      hideControls()
    } else {
      showControls()
    }
  }

  private fun tryShowControls() {
    if (playStatus == PlayStatus.PAUSED || playStatus == PlayStatus.ENDED) {
      showControls()
    }
  }

  private fun setHideTimer() {
    removeHideTimer()
    if (playStatus == PlayStatus.PLAYING) {
      hideTimer = setTimeout({ isHidden = true }, 3000L)
    }
  }

  private fun showInfo(type: String): Unit {
    when (type) {
      "seeking" -> {
        fadeViewOut(infoView, 0)
        fadeViewIn(infoSeekingView, 0)
      }
      "seek_start" -> {
        infoView.text = "Slide left or right to seek"
        infoView.background = null
        fadeViewIn(infoView)
        playerView.requestLayout()
      }
      "resize-mode-fit" -> {
        showResizeModeInfo("Normal")
      }
      "resize-mode-zoom" -> {
        showResizeModeInfo("Zoomed to fill")
      }
    }

    fadeViewIn(controlsOverlay, 0)
  }

  private fun showResizeModeInfo(text: String) {
    infoView.text = text
    infoView.setBackgroundResource(R.drawable.bg_info_view)
    fadeViewIn(infoView)

    removeInfoTimer()
    infoTimer = setTimeout({
      fadeViewOut(arrayOf(infoView, controlsOverlay))
    }, 1500)
  }

  private fun hideInfo() {
    fadeViewOut(arrayOf(infoView, controlsOverlay, infoSeekingView))
  }

  private fun setFullscreenLayout() {
    viewSectionBottom.updateLayoutParams<FrameLayout.LayoutParams> {
      bottomMargin = playerView.resources.getDimensionPixelSize(R.dimen.controlsBottomMarginFullscreen);
    }

    seeker.updateLayoutParams<FrameLayout.LayoutParams> {
      bottomMargin = DensityUtil.dip2px(playerView.context, 3f)
      marginStart = 0
      marginEnd = 0
    }

    contentFrame.updateLayoutParams<FrameLayout.LayoutParams> {
      bottomMargin = 0
    }

    controlView.updateLayoutParams<FrameLayout.LayoutParams> {
      bottomMargin = 0
    }

    uiBottomAdjustmentView.visibility = View.GONE

    playerView.requestLayout()
  }

  private fun setNormalLayout() {
    viewSectionBottom.updateLayoutParams<FrameLayout.LayoutParams> {
      bottomMargin = playerView.resources.getDimensionPixelSize(R.dimen.controlsBottomMarginNormal);
    }

    seeker.updateLayoutParams<FrameLayout.LayoutParams> {
      bottomMargin = playerView.resources.getDimensionPixelSize(R.dimen.playerSeekbarAdjustment);
      marginStart = DensityUtil.dip2px(playerView.context, -8f)
      marginEnd = DensityUtil.dip2px(playerView.context, -8f)
    }

    contentFrame.updateLayoutParams<FrameLayout.LayoutParams> {
      bottomMargin = playerView.resources.getDimensionPixelSize(R.dimen.playerUiBottomAdjustment);
    }

    controlView.updateLayoutParams<FrameLayout.LayoutParams> {
      bottomMargin = playerView.resources.getDimensionPixelSize(R.dimen.playerBottomAdjustment);
    }

    uiBottomAdjustmentView.visibility = View.VISIBLE

    playerView.requestLayout()
  }

  private fun fadeViewIn(view: View, duration: Long = 200) {
    if (duration == 0L) {
      UiThreadUtil.runOnUiThread {
        view.alpha = 1f
        view.visibility = View.VISIBLE
      }
      return
    }

    UiThreadUtil.runOnUiThread {
      view.visibility = View.VISIBLE
      view
        .animate()
        .setDuration(duration)
        .alpha(1f)
        .setListener(object : AnimatorListenerAdapter() {
          override fun onAnimationEnd(animation: Animator) {
            view.visibility = View.VISIBLE
          }
        })
    }
  }

  private fun fadeViewOut(view: View, duration: Long = 200) {
    if (duration == 0L) {
      UiThreadUtil.runOnUiThread {
        view.alpha = 0f
        view.visibility = View.INVISIBLE
      }
      return
    }

    UiThreadUtil.runOnUiThread {
      view
        .animate()
        .setDuration(duration)
        .alpha(0f)
        .setListener(object : AnimatorListenerAdapter() {
          override fun onAnimationEnd(animation: Animator) {
            view.visibility = View.INVISIBLE
          }
        })
    }
  }

  private fun fadeViewIn(views: Array<View>) {
    views.forEach { fadeViewIn(it) }
  }

  private fun fadeViewOut(views: Array<View>) {
    views.forEach { fadeViewOut(it) }
  }

  private fun fadeVisibility(fadeIn: Array<View>, fadeOut: Array<View>) {
    fadeViewIn(fadeIn)
    fadeViewOut(fadeOut)
  }

  private fun removeHideTimer() {
    hideTimer?.cancel()
    hideTimer = null
  }

  private fun removeInfoTimer() {
    infoTimer?.cancel()
    infoTimer = null
  }

  private fun showControls(animate: Boolean = true) {
    if (seekStatus != SeekStatus.NONE)
      return

    UiThreadUtil.runOnUiThread {
      seeker.showScrubber()
      if (animate) {
        fadeViewIn(arrayOf(controls, seeker))
      } else {
        controls.visibility = View.VISIBLE
        seeker.visibility = View.VISIBLE
      }

      infoView.visibility = View.INVISIBLE
      setHideTimer()
    }
  }

  private fun hideControls(animate: Boolean = true) {
    removeHideTimer()

    UiThreadUtil.runOnUiThread {
      if (animate) {
        fadeViewOut(controls)
      } else {
        controls.visibility = View.INVISIBLE
      }

      if (seekStatus == SeekStatus.NONE) {
        seeker.hideScrubber(true)
      }

      if (seekStatus != SeekStatus.SEEKING && seekStatus != SeekStatus.SEEK_START) {
        if (animate) {
          fadeViewOut(seeker)
        } else {
          seeker.visibility = View.INVISIBLE
        }
      }
    }
  }

  private fun showBuffering() {
    playButton.visibility = View.INVISIBLE
    replayButton.visibility = View.INVISIBLE
    bufferingView.visibility = View.VISIBLE
  }

  private fun hideBuffering() {
    bufferingView.visibility = View.INVISIBLE
    if (playStatus == PlayStatus.ENDED) {
      showReplay()
    } else {
      showPlay()
    }
  }

  private fun showPlay() {
    if (isBuffering) return;

    playButton.visibility = View.VISIBLE
    replayButton.visibility = View.INVISIBLE
  }

  private fun showReplay() {
    if (isBuffering) return

    playButton.visibility = View.INVISIBLE
    replayButton.visibility = View.VISIBLE
  }

  private fun setTimeout(run: () -> Unit, delay: Long): Timer {
    val timer = Timer()
    timer.schedule(object : TimerTask() {
      override fun run() {
        run()
      }
    }, delay)
    return timer
  }
}
