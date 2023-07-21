import AVKit
import AVFoundation

@objc(MaazterPlayerViewManager)
class MaazterPlayerViewManager: RCTViewManager {
  override func view() -> UIView {
    MaazterPlayerView()
  }

  @objc func pause(_ node: NSNumber) -> Void {
    DispatchQueue.main.async {
      let component = self.bridge.uiManager.view(forReactTag: node) as! MaazterPlayerView
      component.pause()
    }
  }

  @objc func play(_ node: NSNumber) -> Void {
    DispatchQueue.main.async {
      let component = self.bridge.uiManager.view(forReactTag: node) as! MaazterPlayerView
      component.play()
    }
  }

  @objc func setFullscreen(_ node: NSNumber, isFullscreen: Bool) -> Void {
    DispatchQueue.main.async {
      let component = self.bridge.uiManager.view(forReactTag: node) as! MaazterPlayerView
      component.setFullscreen(isFullscreen: isFullscreen)
    }
  }
}


class MaazterPlayerView: UIView {
  var playerView: PlayerView? = nil
  var controller: ViewController? = nil

  var playerDelegate: PlayerListener!
  var controlDelegate: PlayerControlListener!

  init() {
    super.init(frame: CGRect.zero)

    controller = ViewController()
    controller?.initialize(view: self)
    playerDelegate = MaazterEventListener(view: self)
    controller?.playerView.addListener(playerDelegate)
    controller?.event.addListener(playerDelegate as! PlayerControlListener)
  }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

  @objc var theme: String? = nil  {
    didSet {
      if theme != nil {
        controller?.setTheme(theme: UIColor(hexString: theme!))
      }
    }
  }

  @objc var buttonState: NSDictionary? = nil {
    didSet {
      if (buttonState == nil) { return }

      let btnNext = buttonState?.object(forKey: "next") as? Bool
      let btnPrevious = buttonState?.object(forKey: "previous") as? Bool
      let btnSettings = buttonState?.object(forKey: "settings") as? Bool

      if (btnNext != nil) {
        controller?.setButtonState(name: "next", enabled: btnNext!)
      }

      if (btnPrevious != nil) {
        controller?.setButtonState(name: "previous", enabled: btnPrevious!)
      }

      if (btnSettings != nil) {
        controller?.setButtonState(name: "settings", enabled: btnSettings!)
      }
    }
  }

  @objc var source: NSDictionary? = nil {
    didSet {
      if (source == nil) { return }
      let videoURL = source?.object(forKey: "url") as! String
      let encKey = source?.object(forKey: "encKey") as? String
      let thumbUrl = source?.object(forKey: "thumbUrl") as? String
      let resumeFrom = source?.object(forKey: "resumeFrom") as? Float
      let title = source?.object(forKey: "title") as? String

      let source = VideoSource(url: URL(string: videoURL)!)
      source.encKey = encKey
      source.thumbUrl = thumbUrl != nil ? URL(string: thumbUrl!) : nil
      source.resumeFrom = resumeFrom ?? 0
      source.title = title != nil ? title : nil
        
      controller?.playVideo(source: source)
      controller?.showTitle(title: title ?? "")
    }
  }

  @objc var resizeMode: String? = nil {
    didSet {
      if resizeMode != nil {
        controller?.setResizeMode(mode: resizeMode!)
      }
    }
  }

  @objc func play() {
    controller?.playerView.play()
  }

  @objc func pause() {
    controller?.playerView.pause()
  }

  @objc func setFullscreen(isFullscreen: Bool) {
    controller?.setFullscreen(isFullscreen: isFullscreen)
  }

  @objc var onChangeResizeMode: RCTBubblingEventBlock?
  @objc var onProgress: RCTBubblingEventBlock?
  @objc var onFullscreenChange: RCTBubblingEventBlock?
  @objc var onQualityChange: RCTBubblingEventBlock?
  @objc var onPlaybackSpeedChange: RCTBubblingEventBlock?
  @objc var onPlayStateChange: RCTBubblingEventBlock?
  @objc var onVideoSizeChange: RCTBubblingEventBlock?
  @objc var onCreate: RCTBubblingEventBlock?
  @objc var onDestroy: RCTBubblingEventBlock?

  /** CONTROL EVENTS **/
  @objc var onBackClick: RCTBubblingEventBlock?
  @objc var onNextClick: RCTBubblingEventBlock?
  @objc var onPreviousClick: RCTBubblingEventBlock?
  @objc var onSettingsClick: RCTBubblingEventBlock?
  @objc var onFullscreenClick: RCTBubblingEventBlock?
}


class MaazterEventListener: PlayerListener, PlayerControlListener {

  let view: MaazterPlayerView!

  init(view: MaazterPlayerView) {
    self.view = view
  }

  func onChangeResizeMode(mode: String) {
    guard let onChangeResizeMode = view.onChangeResizeMode else { return }
    onChangeResizeMode(["mode": mode])
  }

  func onProgress(progress: Int, percent: Double, duration: Int) {
    guard let onProgress = view.onProgress else { return }
    onProgress(["progress": progress, "percent": percent, "duration": duration])
  }

  func onFullscreenChange(isFullscreen: Bool) {
    guard let onFullscreenChange = view.onFullscreenChange else { return }
    onFullscreenChange(["isFullscreen": isFullscreen])
  }

  func onQualityChange(quality: String) {
    guard let onQualityChange = view.onQualityChange else { return }
    onQualityChange(["quality": quality])
  }

  func onPlaybackSpeedChange(speed: Float) {
    guard let onPlaybackSpeedChange = view.onPlaybackSpeedChange else { return }
    onPlaybackSpeedChange(["speed": speed])
  }

  func onPlayStateChange(state: Int) {
    guard let onPlayStateChange = view.onPlayStateChange else { return }
    onPlayStateChange(["state": state])
  }

  func onVideoSizeChange(width: Int, height: Int) {
    guard let onVideoSizeChange = view.onVideoSizeChange else { return }
    onVideoSizeChange(["width": width, "height": height])
  }

  func onCreate() {
    guard let onCreate = view.onCreate else { return }
    onCreate(nil)
  }

  func onDestroy() {
    guard let onDestroy = view.onDestroy else { return }
    onDestroy(nil)
  }

  /** CONTROL EVENTS **/
  func onBackClick() {
    guard let onBackClick = view.onBackClick else { return }
    onBackClick(nil)
  }

  func onNextClick() {
    guard let onNextClick = view.onNextClick else { return }
    onNextClick(nil)
  }

  func onPreviousClick() {
    guard let onPreviousClick = view.onPreviousClick else { return }
    onPreviousClick(nil)
  }

  func onSettingsClick() {
    guard let onSettingsClick = view.onSettingsClick else { return }
    onSettingsClick(nil)
  }

  func onFullscreenClick(isFullscreen: Bool) {
    guard let onFullscreenClick = view.onFullscreenClick else { return }
    onFullscreenClick(["isFullscreen": isFullscreen])
  }
}
