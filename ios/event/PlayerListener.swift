//
//  PlayerListener.swift
//  MaazterPlayer
//
//  Created by Samar Yalini on 28/07/21.
//  Copyright © 2021 Facebook. All rights reserved.
//

import Foundation

@objc protocol PlayerListener: AnyObject {
    @objc optional func onReady()
    @objc optional func onReplay()
    @objc optional func onIdle()
    @objc optional func onError()

    @objc optional func onChangeResizeMode(mode: String)
    @objc optional func onProgress(progress: Int, percent: Double, duration: Double)
    @objc optional func onFullscreenChange(isFullscreen: Bool)
    @objc optional func onQualityChange(quality: String)
    @objc optional func onPlaybackSpeedChange(speed: Float)
    @objc optional func onPlayStateChange(state: Int)
    @objc optional func onVideoSizeChange(width: Int, height: Int)
    @objc optional func onCreate()
    @objc optional func onDestroy()
}

@objc protocol PlayerControlListener: AnyObject {
    @objc optional func onBackClick()
    @objc optional func onNextClick()
    @objc optional func onPreviousClick()
    @objc optional func onSettingsClick()
    @objc optional func onFullscreenClick(isFullscreen: Bool)
}
