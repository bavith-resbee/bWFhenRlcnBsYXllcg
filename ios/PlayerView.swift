//
//  PlayerView.swift
//  MaazterPlayer
//
//  Created by Samar Yalini on 24/07/21.
//  Copyright © 2021 Facebook. All rights reserved.
//

import Foundation
import AVFoundation

class PlayerView : UIView {

    private var source: VideoSource? = nil

    private var resourceLoaderDelegate: PlayerResourceLoaderDelegate?

    let event = PlayerEvent()

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }

    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    private var playerItemContext = 0

    // Keep the reference and use it to observe the loading status.
    private var playerItem: AVPlayerItem?

    private var timeObserver: Any?
    private var playerReadyEmitted: Bool = false
    private var isEnded: Bool = false

    func initialize() {
        NotificationCenter.default.addObserver(self, selector: #selector(donePlaying), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        playerLayer.addObserver(self, forKeyPath: #keyPath(AVPlayerLayer.videoGravity), options: [.old, .new], context: &playerItemContext)
    }

    private func setUpAsset(with url: URL, encKey: String?, completion: ((_ asset: AVAsset) -> Void)?) {
        let asset: AVURLAsset
        if encKey != nil {
            resourceLoaderDelegate = PlayerResourceLoaderDelegate(url: url, encKey: encKey!);
            asset = AVURLAsset(url: (resourceLoaderDelegate?.getInitialURL())!)
            asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: .main)
        } else {
            asset = AVURLAsset(url: url)
        }

        asset.loadValuesAsynchronously(forKeys: ["playable"]) {
            var error: NSError? = nil
            let status = asset.statusOfValue(forKey: "playable", error: &error)
            switch status {
            case .loaded:
                completion?(asset)
            case .failed:
                print(".failed")
            case .cancelled:
                print(".cancelled")
            default:
                print("default")
            }
        }
    }

    private func setUpPlayerItem(with asset: AVAsset) {
        playerItem = AVPlayerItem(asset: asset)
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &playerItemContext)
        playerItem?.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithm.spectral;

        DispatchQueue.main.async { [weak self] in
            self?.player = AVPlayer(playerItem: self?.playerItem!)
            self?.initiateObserver()
        }
    }

    private func initiateObserver() {
        player?.addObserver(self, forKeyPath: #keyPath(AVPlayer.currentItem.presentationSize), options: [.old, .new], context: &playerItemContext)
        player?.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: [.old, .new], context: &playerItemContext)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 1), queue: .main, using: progressUpdate)
        setResizeMode(mode: "fit")
    }

    private func ejectPlayer() {
        if player == nil {
            return
        }

        player?.pause()

        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        player?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.currentItem.presentationSize))
        player?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus))

        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }

        event.emitOnDestroy()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // Only handle observations for the playerItemContext
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            // Switch over status value
            switch status {
            case .readyToPlay:
                print(".readyToPlay")
                player?.play()
                if !playerReadyEmitted {
                    if source!.resumeFrom > 0 {
                        let duration = CMTimeGetSeconds(player?.currentItem?.duration ?? .zero)
                        let resumeFrom = Double(source?.resumeFrom ?? 0)
                        let playFrom = (duration * resumeFrom)/100
                        seekTo(time: playFrom, completion: { _ in })
                    }
                    playerReadyEmitted = true
                    event.emitOnCreate()
                }
            case .failed:
                print(".failed")
            case .unknown:
                print(".unknown")
            @unknown default:
                print("@unknown default")
            }
        } else if keyPath == #keyPath(AVPlayer.currentItem.presentationSize) {
            guard let size = change?[.newKey] as? CGSize else { return }
            event.emitOnVideoSizeChange(width: Int(size.width), height: Int(size.height))
        } else if keyPath == #keyPath(AVPlayerLayer.videoGravity) {
            guard let gravity = change?[.newKey] as? AVLayerVideoGravity else { return }
            var mode: String = "";

            switch gravity {
            case .resize: mode = "fill"
            case .resizeAspect: mode = "fit"
            case .resizeAspectFill: mode = "zoom"
            default: mode = ""
            }
            event.emitOnChangeResizeMode(mode: mode)
        } else if keyPath == #keyPath(AVPlayer.timeControlStatus) {
            switch player?.timeControlStatus {
            case .paused:
                if !isEnded {
                    event.emitOnPlayStateChange(state: .paused)
                }
            case .playing:
                isEnded = false
                event.emitOnPlayStateChange(state: .playing)
            case .waitingToPlayAtSpecifiedRate:
                if player?.currentItem?.isPlaybackLikelyToKeepUp != true {
                    event.emitOnPlayStateChange(state: .buffering)
                } else {
                    event.emitOnPlayStateChange(state: .playing)
                }

                if (player?.currentItem?.isPlaybackBufferEmpty == true) {
                    event.emitOnPlayStateChange(state: .buffering)
                }
            case .none:
                print(".none")
            case .some:
                print(".some")
            }
        }
    }

    @objc func donePlaying(notification: Notification) {
        event.emitOnPlayStateChange(state: .ended)
        isEnded = true
    }

    func progressUpdate(time: CMTime) {
        if let duration = player?.currentItem?.duration {
            let duration = CMTimeGetSeconds(duration), time = CMTimeGetSeconds(time)
            let percent = (time * 100)/duration
            
            if !duration.isNaN {
                event.emitOnProgress(progress: Int(time), percent: percent, duration: Double(duration))
            }
        }
    }

    func prepareAndPlay(source: VideoSource) {
        self.source = source

        if player != nil {
            ejectPlayer()
        }

        playerReadyEmitted = false

        setUpAsset(with: source.url, encKey: source.encKey) { [weak self] (asset: AVAsset) in
            self?.setUpPlayerItem(with: asset)
        }
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func restart() {
        seekTo(time: 0, completion: { _ in })
        player?.play()
    }

    func seekTo(time: Double, completion: @escaping (Bool)->Void) {
        player?.seek(to: CMTimeMakeWithSeconds(time, preferredTimescale: 60000), toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: completion)
    }

    func getDuration() -> Double {
        CMTimeGetSeconds(player?.currentItem?.duration ?? CMTime.zero)
    }

    func getCurrentProgress() -> Double {
        CMTimeGetSeconds(player?.currentItem?.currentTime() ?? CMTime.zero)
    }

    func getBufferedDuration() -> Double
    {
        if let range = player?.currentItem?.loadedTimeRanges.first {
            return CMTimeGetSeconds(CMTimeRangeGetEnd(range.timeRangeValue))
        }
        return CMTimeGetSeconds(.zero)
    }


    func setSpeed(speed: Float) {
        player?.rate = speed

        event.emitOnPlaybackSpeedChange(speed: speed)
    }

    func getSpeed() -> Float {
        player?.rate ?? 0
    }

    func getQualities() -> Array<Quality> {
        resourceLoaderDelegate?.qualities ?? []
    }

    func getVideoResolution() -> String {
        let height = playerItem?.tracks.first { track in track.assetTrack?.mediaType == .video }?.assetTrack?.naturalSize.height ?? 0
        return "\(Int(height))p"
    }

    func getPeakBitRate()-> Double {
        player?.currentItem?.preferredPeakBitRate ?? 0
    }

    func setPeakBitRate(bitrate: Double) {
        player?.currentItem?.preferredPeakBitRate = bitrate

        event.emitOnQualityChange(quality: Quality.getResolution(bitrate: bitrate))
    }

    func setResizeMode(mode: String) {
        switch mode {
        case "zoom":
            playerLayer.videoGravity = .resizeAspectFill
        case "fill":
            playerLayer.videoGravity = .resize
        case "fit":
            playerLayer.videoGravity = .resizeAspect
        default:
            playerLayer.videoGravity = .resizeAspect
        }
    }

    func getVideoGravity() -> AVLayerVideoGravity {
        playerLayer.videoGravity
    }

    func setVideoGravity(gravity: AVLayerVideoGravity) {
        playerLayer.videoGravity = gravity
    }

    func addListener(_ listener: PlayerListener) {
        event.addListener(listener)
    }

    deinit {
        ejectPlayer()
        playerLayer.removeObserver(self, forKeyPath: #keyPath(AVPlayerLayer.videoGravity))
        NotificationCenter.default.removeObserver(self)
    }
}

class Quality {
    var width: Int
    var height: Int

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    func getResolution() -> String {
        String(height) + "p"
    }

    static func getBitRate(resolution: String) -> Double {
        var bitRate: Double = 0
        switch resolution {
        case "240p":
            bitRate = 700000
        case "360p":
            bitRate = 1500000
        case "480p":
            bitRate = 2000000
        case "720p":
            bitRate = 4000000
        case "1080p":
            bitRate = 6000000
        case "2k":
            bitRate = 16000000
        case "4k":
            bitRate = 45000000
        case "Auto":
            bitRate = 0
        default:
            bitRate = 0
        }
        return bitRate
    }

    static func getResolution(bitrate: Double) -> String {
        var resolution: String = "Auto"
        switch bitrate {
        case 700000:
            resolution = "240p"
        case 1500000:
            resolution = "360p"
        case 2000000:
            resolution = "480p"
        case 4000000:
            resolution = "720p"
        case 6000000:
            resolution = "1080p"
        case 16000000:
            resolution = "2k"
        case 45000000:
            resolution = "4k"
        case 0:
            resolution = "Auto"
        default:
            resolution = "Auto"
        }
        return resolution
    }
}

class VideoSource {
    var url: URL
    var encKey: String? = nil
    var thumbUrl: URL? = nil
    var resumeFrom: Float = 0
    var title: String? = nil

    init(url: URL) {
        self.url = url
    }
}
