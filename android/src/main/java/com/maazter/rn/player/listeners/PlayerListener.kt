package com.maazter.rn.player.listeners

interface PlayerListener {
  fun onBuffering() {}
  fun onReady() {}
  fun onReplay() {}
  fun onIdle() {}
  fun onError() {}

  fun onChangeResizeMode(mode: Int) {}

  fun onProgress(progress: Long, percent: Float, duration: Long) {}
  fun onFullscreenChange(isFullscreen: Boolean) {}
  fun onQualityChange(quality: String) {}
  fun onPlaybackSpeedChange(speed: Float) {}
  fun onPlayStateChange(state: Int) {}
  fun onVideoSizeChange(width: Int, height: Int) {}
  fun onCreate() {}
  fun onDestroy() {}

  fun onBackClick() {}
  fun onNextClick() {}
  fun onPreviousClick() {}
  fun onSettingsClick() {}
  fun onFullscreenClick(isFullscreen: Boolean) {}
}
