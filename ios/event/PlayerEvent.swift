//
//  PlayerEvent.swift
//  MaazterPlayer
//
//  Created by Samar Yalini on 28/07/21.
//  Copyright © 2021 Facebook. All rights reserved.
//

import Foundation

class PlayerEvent {
    private var listeners: [WeakReference<PlayerListener>] = []

    func addListener(_ listener: PlayerListener) {
        listeners.append(WeakReference(value: listener))
    }

    func emitOnChangeResizeMode(mode: String) {
        listeners.forEach({ $0.value?.onChangeResizeMode?(mode: mode) })
    }

    func emitOnProgress(progress: Int, percent: Double, duration: Double) {
        listeners.forEach({ $0.value?.onProgress?(progress: progress, percent: percent, duration: duration) })
    }

    /**/func emitOnFullscreenChange(isFullscreen: Bool) {
        listeners.forEach({ $0.value?.onFullscreenChange?(isFullscreen: isFullscreen) })
    }

    func emitOnQualityChange(quality: String) {
        listeners.forEach({ $0.value?.onQualityChange?(quality: quality) })
    }

    func emitOnPlaybackSpeedChange(speed: Float) {
        listeners.forEach({ $0.value?.onPlaybackSpeedChange?(speed: speed) })
    }

    func emitOnPlayStateChange(state: PlayState) {
        listeners.forEach({ $0.value?.onPlayStateChange?(state: state.rawValue) })
    }

    func emitOnVideoSizeChange(width: Int, height: Int) {
        listeners.forEach({ $0.value?.onVideoSizeChange?(width: width, height: height) })
    }

    func emitOnCreate() {
        listeners.forEach({ $0.value?.onCreate?() })
    }

    func emitOnDestroy() {
        listeners.forEach({ $0.value?.onDestroy?() })
    }
}

class PlayerControlEvent {
    private var listeners: [WeakReference<PlayerControlListener>] = []

    func addListener(_ listener: PlayerControlListener) {
        listeners.append(WeakReference(value: listener))
    }

    func emitOnBackClick() {
        listeners.forEach({ $0.value?.onBackClick?() })
    }

    func emitOnNextClick() {
        listeners.forEach({ $0.value?.onNextClick?() })
    }

    func emitOnPreviousClick() {
        listeners.forEach({ $0.value?.onPreviousClick?() })
    }

    func emitOnSettingsClick() {
        listeners.forEach({ $0.value?.onSettingsClick?() })
    }

    func emitOnFullscreenClick(isFullscreen: Bool) {
        listeners.forEach({ $0.value?.onFullscreenClick?(isFullscreen: isFullscreen) })
    }
}

class WeakReference<T: AnyObject> {
    
    weak var value: T?

    init(value: T) {
        self.value = value
    }
    
    func release() {
        value = nil
    }
}
