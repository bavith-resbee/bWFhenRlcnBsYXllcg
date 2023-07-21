package com.maazter.rn.player.downloader

import com.google.android.exoplayer2.Format
import com.google.android.exoplayer2.source.TrackGroup
import com.google.android.exoplayer2.source.TrackGroupArray

class TrackKey(
  var trackGroupArray: TrackGroupArray,
  var trackGroup: TrackGroup,
  var trackFormat: Format
)
