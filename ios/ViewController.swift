//
//  ViewController.swift
//  MaazterPlayer
//
//  Created by Samar Yalini on 24/07/21.
//  Copyright © 2021 Facebook. All rights reserved.
//

import Foundation
import FontAwesome_swift
import Toaster
import YRipple

class ViewController: UIViewController, PlayerListener, SliderDelegate {

    private let btnPrevious = RippleButton()
    private let btnNext = RippleButton()
    private let btnSettings = RippleButton()
    private let btnQuality = RippleButton()
    private let btnSpeed = RippleButton()
    private let btnBack = RippleButton()
    private let btnFullscreen = RippleButton()
    private let btnRestart = RippleButton()
    private let btnPlayPause = PlayPauseButton(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
    private let spinner = SpinnerView(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
    private let viewHolderCenter = UIView()
    private var seekbar: Slider? = nil
    private let thumbnailView = UIImageView()
    private let durationView = UILabel()
    
    private let titleView = UILabel()
    private let titleContainer = UIView()

    private var controlsView = UIView()
    private var infoView = UIView()
    private var infoSeekPressView = UILabel()
    private var infoSeekMoveView = InfoSeekMoveView()

    private var constraintSpeedWithSettings: NSLayoutConstraint? = nil
    private var constraintSpeedWithoutSettings: NSLayoutConstraint? = nil

    private var constraintBtnFullscreenBottom: NSLayoutConstraint? = nil
    private var constraintDurationBottom: NSLayoutConstraint? = nil
    private var constraintSeekbarBottom: NSLayoutConstraint? = nil
    private var constraintSeekbarTrailing: NSLayoutConstraint? = nil
    private var constraintSeekbarLeading: NSLayoutConstraint? = nil

    private let bottomMarginFullscreen = -20
    private var source: VideoSource? = nil
    
    let event = PlayerControlEvent()

    private var controlsTimer: Timer? = nil
    private var isFullscreen = false
    private var resizeMode = "fit"
    private var seekState: SeekState = .none {
        didSet {
            refreshViews()
        }
    }
    private var playState: PlayState = .buffering {
        didSet {
            refreshViews()
        }
    }
    private var isControlsShown: Bool = false
    private var theme = UIColor.init(hexString: "#ff3b30")

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func initialize(view: UIView) {
        view.addSubview(self.view)
        self.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        self.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        self.view.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        self.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        loadView1()
    }

    var playerContainerView: UIView!

    var playerView: PlayerView!

    private func setUpPlayerContainerView() {
        playerContainerView = UIView()
        playerContainerView.backgroundColor = .red
        view.addSubview(playerContainerView)

        playerContainerView.translatesAutoresizingMaskIntoConstraints = false
        playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        playerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        playerContainerView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        playerContainerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    }

    private func setUpPlayerView() {
        playerView = PlayerView()
        playerContainerView.addSubview(playerView)

        playerView.backgroundColor = .black
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerView.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor).isActive = true
        playerView.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor).isActive = true
        playerView.topAnchor.constraint(equalTo: playerContainerView.topAnchor).isActive = true
        playerView.bottomAnchor.constraint(equalTo: playerContainerView.bottomAnchor).isActive = true

        playerView.addListener(self)
        playerView.initialize()
    }

    private func setUpInfoView() {
        infoView.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        playerContainerView.addSubview(infoView)
        infoView.translatesAutoresizingMaskIntoConstraints = false
        infoView.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor).isActive = true
        infoView.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor).isActive = true
        infoView.topAnchor.constraint(equalTo: playerContainerView.topAnchor).isActive = true
        infoView.bottomAnchor.constraint(equalTo: playerContainerView.bottomAnchor).isActive = true


        // INFO SEEK PRESS VIEW
        infoSeekPressView.isHidden = true
        infoSeekPressView.text = "Slide left or right to seek"
        infoSeekPressView.font = infoSeekPressView.font.withSize(12)
        infoSeekPressView.textColor = .white
        infoSeekPressView.textAlignment = .center

        infoView.addSubview(infoSeekPressView)
        infoSeekPressView.translatesAutoresizingMaskIntoConstraints = false
        infoSeekPressView.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 20).isActive = true
        infoSeekPressView.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -20).isActive = true
        infoSeekPressView.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 20).isActive = true

        // INFO SEEKING VIEW
        infoSeekMoveView.isHidden = true
        infoView.addSubview(infoSeekMoveView)
        infoSeekMoveView.translatesAutoresizingMaskIntoConstraints = false
        infoSeekMoveView.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 20).isActive = true
        infoSeekMoveView.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -20).isActive = true
        infoSeekMoveView.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 20).isActive = true
    }

    private func setUpControls() {
        // THUMBNAIL
        thumbnailView.isHidden = true

        playerContainerView.addSubview(thumbnailView)
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor).isActive = true
        thumbnailView.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor).isActive = true
        thumbnailView.topAnchor.constraint(equalTo: playerContainerView.topAnchor).isActive = true
        thumbnailView.bottomAnchor.constraint(equalTo: playerContainerView.bottomAnchor).isActive = true


        // CONTROLS VIEW
        controlsView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        controlsView.isHidden = true
        controlsView.alpha = 0

        playerContainerView.addSubview(controlsView)
        controlsView.translatesAutoresizingMaskIntoConstraints = false
        controlsView.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor).isActive = true
        controlsView.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor).isActive = true
        controlsView.topAnchor.constraint(equalTo: playerContainerView.topAnchor).isActive = true
        controlsView.bottomAnchor.constraint(equalTo: playerContainerView.bottomAnchor).isActive = true


        // BUTTON SETTINGS
        btnSettings.titleLabel?.font = UIFont.fontAwesome(ofSize: 20, style: .solid)
        btnSettings.setTitle(String.fontAwesomeIcon(name: .cog), for: .normal)

        controlsView.addSubview(btnSettings)
        btnSettings.translatesAutoresizingMaskIntoConstraints = false
        btnSettings.trailingAnchor.constraint(equalTo: controlsView.trailingAnchor, constant: -10).isActive = true
        btnSettings.topAnchor.constraint(equalTo: controlsView.topAnchor, constant: 5).isActive = true


        // BUTTON SPEED
        btnSpeed.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        btnSpeed.setTitle("1x", for: .normal)

        controlsView.addSubview(btnSpeed)
        btnSpeed.translatesAutoresizingMaskIntoConstraints = false
        constraintSpeedWithoutSettings = btnSpeed.trailingAnchor.constraint(equalTo: controlsView.trailingAnchor, constant: -10)
        constraintSpeedWithSettings = btnSpeed.trailingAnchor.constraint(equalTo: btnSettings.leadingAnchor, constant: -10)
        constraintSpeedWithSettings?.isActive = true
        constraintSpeedWithoutSettings?.isActive = false
        btnSpeed.topAnchor.constraint(equalTo: controlsView.topAnchor, constant: 5).isActive = true

        // BUTTON QUALITY
        btnQuality.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        btnQuality.setTitle("HD", for: .normal)

        controlsView.addSubview(btnQuality)
        btnQuality.translatesAutoresizingMaskIntoConstraints = false
        btnQuality.trailingAnchor.constraint(equalTo: btnSpeed.leadingAnchor, constant: -10).isActive = true
        btnQuality.topAnchor.constraint(equalTo: controlsView.topAnchor, constant: 5).isActive = true
        

        // BUTTON BACK
        btnBack.titleLabel?.font = UIFont.fontAwesome(ofSize: 20, style: .solid)
        btnBack.setTitle(String.fontAwesomeIcon(name: .chevronLeft), for: .normal)

        controlsView.addSubview(btnBack)
        btnBack.translatesAutoresizingMaskIntoConstraints = false
        btnBack.leadingAnchor.constraint(equalTo: controlsView.leadingAnchor, constant: 3).isActive = true
        btnBack.topAnchor.constraint(equalTo: controlsView.topAnchor, constant: 5).isActive = true
        

        // BUTTON FULLSCREEN
        btnFullscreen.titleLabel?.font = UIFont.fontAwesome(ofSize: 20, style: .solid)
        btnFullscreen.setTitle(String.fontAwesomeIcon(name: .expand), for: .normal)

        controlsView.addSubview(btnFullscreen)
        btnFullscreen.translatesAutoresizingMaskIntoConstraints = false
        btnFullscreen.trailingAnchor.constraint(equalTo: controlsView.trailingAnchor, constant: -10).isActive = true
        constraintBtnFullscreenBottom = btnFullscreen.bottomAnchor.constraint(equalTo: controlsView.bottomAnchor, constant: -10)
        constraintBtnFullscreenBottom?.isActive = true

        // VIEW HOLDER CENTER
//        viewHolderCenter.isUserInteractionEnabled = true
        controlsView.addSubview(viewHolderCenter)
        viewHolderCenter.translatesAutoresizingMaskIntoConstraints = false
        viewHolderCenter.centerXAnchor.constraint(equalTo: controlsView.centerXAnchor).isActive = true
        viewHolderCenter.centerYAnchor.constraint(equalTo: controlsView.centerYAnchor).isActive = true
        viewHolderCenter.heightAnchor.constraint(equalToConstant: 32).isActive = true
        viewHolderCenter.widthAnchor.constraint(equalToConstant: 32).isActive = true

        // BUTTON NEXT
        btnNext.titleLabel?.font = UIFont.fontAwesome(ofSize: 20, style: .solid)
        btnNext.setTitle(String.fontAwesomeIcon(name: .stepForward), for: .normal)

        controlsView.addSubview(btnNext)
        btnNext.translatesAutoresizingMaskIntoConstraints = false
        btnNext.leadingAnchor.constraint(equalTo: viewHolderCenter.trailingAnchor, constant: 50).isActive = true
        btnNext.centerYAnchor.constraint(equalTo: controlsView.centerYAnchor).isActive = true

        // BUTTON PREVIOUS
        btnPrevious.titleLabel?.font = UIFont.fontAwesome(ofSize: 20, style: .solid)
        btnPrevious.setTitle(String.fontAwesomeIcon(name: .stepBackward), for: .normal)

        controlsView.addSubview(btnPrevious)
        btnPrevious.translatesAutoresizingMaskIntoConstraints = false
        btnPrevious.trailingAnchor.constraint(equalTo: viewHolderCenter.leadingAnchor, constant: -50).isActive = true
        btnPrevious.centerYAnchor.constraint(equalTo: controlsView.centerYAnchor).isActive = true

        // BUTTON PLAY/PAUSE
        viewHolderCenter.addSubview(btnPlayPause)
        btnPlayPause.translatesAutoresizingMaskIntoConstraints = false
        btnPlayPause.centerXAnchor.constraint(equalTo: viewHolderCenter.centerXAnchor).isActive = true
        btnPlayPause.centerYAnchor.constraint(equalTo: viewHolderCenter.centerYAnchor).isActive = true
        btnPlayPause.heightAnchor.constraint(equalToConstant: 32).isActive = true
        btnPlayPause.widthAnchor.constraint(equalToConstant: 32).isActive = true
        btnPlayPause.setPlaying(true)

        // BUTTON RESTART
        btnRestart.titleLabel?.font = UIFont.fontAwesome(ofSize: 30, style: .solid)
        btnRestart.setTitle(String.fontAwesomeIcon(name: .redoAlt), for: .normal)

        viewHolderCenter.addSubview(btnRestart)
        btnRestart.translatesAutoresizingMaskIntoConstraints = false
        btnRestart.centerXAnchor.constraint(equalTo: viewHolderCenter.centerXAnchor).isActive = true
        btnRestart.centerYAnchor.constraint(equalTo: viewHolderCenter.centerYAnchor).isActive = true
        btnRestart.heightAnchor.constraint(equalToConstant: 32).isActive = true
        btnRestart.widthAnchor.constraint(equalToConstant: 32).isActive = true
        btnRestart.isHidden = true
        
        //TITLE CONTAINER
        controlsView.addSubview(titleContainer)
        titleContainer.translatesAutoresizingMaskIntoConstraints = false
        titleContainer.topAnchor.constraint(equalTo: controlsView.topAnchor).isActive = true
        titleContainer.leadingAnchor.constraint(equalTo: btnBack.trailingAnchor).isActive = true
        
        //TITLE
        controlsView.addSubview(titleView)
        titleView.text = source?.title
        titleView.textColor = .white
        titleView.font = titleView.font.withSize(14)
        titleView.lineBreakMode = NSLineBreakMode.byTruncatingTail
        titleView.adjustsFontSizeToFitWidth = false
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.topAnchor.constraint(equalTo: controlsView.topAnchor, constant: 14).isActive = true
        titleView.leadingAnchor.constraint(equalTo: btnBack.trailingAnchor, constant: 4).isActive = true
        titleView.widthAnchor.constraint(lessThanOrEqualTo: titleContainer.widthAnchor).isActive = true

        btnQuality.leadingAnchor.constraint(equalTo: titleContainer.trailingAnchor, constant: 8).isActive = true
        
        // SPINNER
        spinner.setColor(color: theme)

        playerContainerView.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerXAnchor.constraint(equalTo: playerContainerView.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: playerContainerView.centerYAnchor).isActive = true
        spinner.heightAnchor.constraint(equalToConstant: 50).isActive = true
        spinner.widthAnchor.constraint(equalToConstant: 50).isActive = true
        spinner.animate()

        // DURATION VIEW
        durationView.textColor = .white
        durationView.font = durationView.font.withSize(14)
        durationView.baselineAdjustment = .alignCenters
        
        controlsView.addSubview(durationView)
        durationView.translatesAutoresizingMaskIntoConstraints = false
        durationView.leadingAnchor.constraint(equalTo: controlsView.leadingAnchor, constant: 10).isActive = true
        constraintDurationBottom = durationView.bottomAnchor.constraint(equalTo: controlsView.bottomAnchor, constant: -10)
        constraintDurationBottom?.isActive = true

        onPlayStateChange(state: 4) // Initially Buffering

        btnSpeed.addTarget(self, action: #selector(openSpeedPopup), for: .touchUpInside)
        btnQuality.addTarget(self, action: #selector(openQualityPopup), for: .touchUpInside)
        btnRestart.addTarget(self, action: #selector(restartVideo), for: .touchUpInside)

        btnSettings.setOnClickListener { [self] in event.emitOnSettingsClick() }
        btnFullscreen.setOnClickListener { [self] in event.emitOnFullscreenClick(isFullscreen: !isFullscreen) }
        btnBack.setOnClickListener { [self] in
            if isFullscreen {
                event.emitOnFullscreenClick(isFullscreen: false)
            } else {
                event.emitOnBackClick()
            }
        }
        btnNext.setOnClickListener { [self] in event.emitOnNextClick() }
        btnPrevious.setOnClickListener { [self] in event.emitOnPreviousClick() }

        playerContainerView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action:#selector(pinchRecognized(_:))))
        btnPlayPause.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(triggerPlayPause)))


        // SKIP VIEW
        playerContainerView.addSubview(doubleTapView)
        doubleTapView.translatesAutoresizingMaskIntoConstraints = false
        doubleTapView.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor).isActive = true
        doubleTapView.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor).isActive = true
        doubleTapView.topAnchor.constraint(equalTo: playerContainerView.topAnchor).isActive = true
        doubleTapView.bottomAnchor.constraint(equalTo: playerContainerView.bottomAnchor).isActive = true
        doubleTapView.isHidden = true

        doubleTapView.startCallback = { [self] in seekState = .skipping }
        doubleTapView.endCallback = { [self] in seekState = .none }
        doubleTapView.setPlayerView(view: playerView)


        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(didDoubleTapped(_:)))
        doubleTap.numberOfTapsRequired = 2
        playerContainerView.addGestureRecognizer(doubleTap)

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(didTapControlsView(_:)))
        singleTap.numberOfTapsRequired = 1
        playerContainerView.addGestureRecognizer(singleTap)

        singleTap.require(toFail: doubleTap)
    }

    @objc func pinchRecognized(_ pinch: UIPinchGestureRecognizer) {
        if !isFullscreen {
            return
        }

        var pinchScale = pinch.scale
        pinchScale = round(pinchScale * 1000) / 1000.0
        if (pinchScale < 1) {
            if playerView.getVideoGravity() != .resizeAspect {
                playerView.setVideoGravity(gravity: .resizeAspect)
                Toast(text: "Normal").show()
            }
        } else {
            if playerView.getVideoGravity() != .resize {
                playerView.setVideoGravity(gravity: .resize)
                Toast(text: "Zoomed to fit").show()
            }
        }
    }

    let skipLeftView: SkipOverlay = SkipOverlay()
    let skipRightView: SkipOverlay = SkipOverlay()
    let doubleTapView: SkipOverlay = SkipOverlay()

    @objc private func didDoubleTapped(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: playerContainerView)
        let screenWidth = playerContainerView.frame.size.width;

        if point.x > (screenWidth / 2) {
            doubleTapView.start(direction: .right)
        } else {
            doubleTapView.start(direction: .left)
        }

        doubleTapView.rippleFill(location: point, color: UIColor.init(hexString: "#18FFFFFF"))
    }

    @objc private func didTapControlsView(_ sender: UITapGestureRecognizer) {
        if !(sender.view == controlsView || sender.view == playerContainerView) {
            return
        }

        if seekState != .none {
            return
        }

        isControlsShown = !isControlsShown
        refreshViews()
    }

    private func hideControls(withSeekbar: Bool = true) {
        if controlsView.isHidden {
            return
        }

        UIView.animate(withDuration: 0.2, animations: { () -> () in
            self.controlsView.alpha = 0
        }, completion: { [self] b in
            controlsView.isHidden = true
            isControlsShown = false
        })
    }

    private func showControls() {
        controlsTimer?.invalidate()

        if !controlsView.isHidden {
            controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in self.tryHideControls() }
            return
        }

        if seekbar?.isHidden == true && seekbar != nil {
            showView(view: seekbar!, animated: true)
        }

        isControlsShown = true
        controlsView.alpha = 0
        controlsView.isHidden = false
        UIView.animate(withDuration: 0.2, animations: { () -> () in
            self.controlsView.alpha = 1
        }, completion: { b in
            self.controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in self.tryHideControls() }
        })
    }

    private func tryHideControls() {
        if controlsView.isHidden {
            return
        }

        if playState == .playing {
            hideControls()
        }

        if seekState == .none && seekbar != nil {
            hideView(view: seekbar!, animated: true)
        }
    }

    private func refreshViews() {
        spinner.isHidden = !(playState == .buffering && seekState == .none)

        switch seekState {
        case .none:
            hideView(view: infoView, animated: true)
        case .seekPress:
            infoSeekPressView.isHidden = false
            infoSeekMoveView.isHidden = true
            showView(view: infoView, animated: true)
        case .seeking:
            infoSeekPressView.isHidden = true
            infoSeekMoveView.isHidden = false
            showView(view: infoView, animated: true)
            break
        case .skipping:
            break
        }

        viewHolderCenter.isHidden = !spinner.isHidden

        btnRestart.isHidden = playState != .ended
        btnPlayPause.isHidden = playState == .ended

        // Control View
        if seekState == .none {
            showControls()
            /*if isControlsShown {
                showControls()
            } else {
                hideControls()
                if seekbar != nil {
                    hideView(view: seekbar!, animated: true)
                }
            }*/
        } else {
            hideControls()
        }
    }

    private func hideView(view: UIView, animated: Bool = false) {
        if view.isHidden {
            return
        }

        if !animated {
            view.alpha = 0
            view.isHidden = true
            return
        }

        UIView.animate(withDuration: 0.2, animations: { () -> () in
            view.alpha = 0
        }, completion: { b in
            view.isHidden = true
        })
    }

    private func showView(view: UIView, animated: Bool = false) {
        if !view.isHidden {
            return
        }

        if !animated {
            view.alpha = 1
            view.isHidden = false
            return
        }

        view.alpha = 0
        view.isHidden = false
        UIView.animate(withDuration: 0.2, animations: { () -> () in
            view.alpha = 1
        }, completion: { _ in })
    }

    func setSeekbar() {
        // SEEKBAR
        seekbar = Slider(frame: CGRect(x: 0, y: 0, width: controlsView.frame.width, height: 20))
        seekbar?.currentTrackColor = theme
        seekbar?.thumbTrackColor = theme

        playerContainerView.addSubview(seekbar!)
        seekbar?.translatesAutoresizingMaskIntoConstraints = false
        constraintSeekbarLeading = seekbar?.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor)
        constraintSeekbarTrailing = seekbar?.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor)
        constraintSeekbarBottom = seekbar?.bottomAnchor.constraint(equalTo: playerContainerView.bottomAnchor, constant: 8)
        constraintSeekbarLeading?.isActive = true
        constraintSeekbarTrailing?.isActive = true
        constraintSeekbarBottom?.isActive = true

        seekbar?.minimumValue = 0
        seekbar?.maximumValue = (videoDuration > 0) ? CGFloat(videoDuration) : 100

        seekbar?.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)
        seekbar?.delegate = self
    }

    private var scrubberTimer: Timer? = nil

    func onScrubStart() {
        scrubberTimer?.invalidate()
        scrubberTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { [self] (timer) in
            seekState = .seekPress
        }
    }

    func onScrubMove() {
        scrubberTimer?.invalidate()
        seekState = .seeking
    }

    func onScrubStop() {
        scrubberTimer?.invalidate()
        seekState = .none
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if seekbar == nil {
            setSeekbar()
        }
    }

    public private(set) var isScrubbingInProgress: Bool = false
    public private(set) var isSeekInProgress = false
    private var progressBarHighlightedObserver: NSKeyValueObservation?

    private var videoDuration: Double = 0 {
        didSet {
            seekbar?.maximumValue = CGFloat(videoDuration)
            durationView.text = durationString
        }
    }

    private var currentProgress: Double = 0 {
        didSet {
            seekbar?.value = CGFloat(currentProgress)
            durationView.text = durationString
        }
    }

    private func secondsToHMS(seconds: Int) -> String {
        let (h, m, s) = (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
        var (hh, mm, ss) = (String(format: "%02d", h), String(format: "%02d", m), String(format: "%02d", s))

        hh = h > 0 ? "\(hh):" : "";
        mm = "\(mm):"
        return hh + mm + ss
    }

    private var durationString: String {
        let d = secondsToHMS(seconds: Int(videoDuration))
        let p = secondsToHMS(seconds: Int(currentProgress))

        return p + " / " + d
    }

    func onPlayStateChange(state: Int) {
        playState = PlayState(rawValue: state)!

        switch playState {
        case .playing:
            btnPlayPause.setPlaying(true)
        case .paused:
            isControlsShown = true
            btnPlayPause.setPlaying(false)
        case .ended:
            isControlsShown = true
        default:
            break
        }

        refreshViews()
    }

    func onProgress(progress: Int, percent: Double, duration: Int) {
        if !isScrubbingInProgress && !isSeekInProgress {
            currentProgress = Double(progress)
        }
        seekbar?.bufferValue = CGFloat(playerView.getBufferedDuration())
    }

    func onCreate() {
        videoDuration = playerView.getDuration()
        thumbnailView.isHidden = true
    }

    @objc func handleSliderChange() {
        isSeekInProgress = true
        playerView.seekTo(time: Double(seekbar?.value ?? 0), completion: { [self] _ in
            isSeekInProgress = false
        })
    }

    @objc func triggerPlayPause() {
        if btnPlayPause.playing {
            playerView.player?.pause()
        } else {
            playerView.player?.play()
        }
    }

    @objc func restartVideo() {
        playerView.restart()
    }

    @objc func openSpeedPopup() {
        let speeds = [
            BsItem(name: "0.25x", value: 0.25),
            BsItem(name: "0.5x", value: 0.5),
            BsItem(name: "0.75x", value: 0.75),
            BsItem(name: "Normal", value: 1),
            BsItem(name: "1.25x", value: 1.25),
            BsItem(name: "1.5x", value: 1.5),
            BsItem(name: "1.75x", value: 1.75),
            BsItem(name: "2", value: 2)
        ]

        speeds.forEach { speed in
            speed.selected = playerView.getSpeed() == Float(speed.value)
        }

        let actionSheet: UIAlertController = UIAlertController(title: "Playback Speed", message: nil, preferredStyle: .actionSheet)

        speeds.forEach { i in
            let action = UIAlertAction(title: i.name, style: .default) { [self] _ in
                playerView.setSpeed(speed: Float(i.value))
            }

            action.setValue(i.selected, forKey: "checked")
            actionSheet.addAction(action)
        }

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in })
        present(actionSheet, animated: true)
    }

    @objc func openQualityPopup() {
        let qualities = playerView.getQualities()
        if qualities.count < 0 {
            return
        }

        let quality = Quality.getResolution(bitrate: playerView.getPeakBitRate())

        let actionSheet: UIAlertController = UIAlertController(title: "Quality", message: nil, preferredStyle: .actionSheet)

        let autoOptionTitle = quality == "Auto" ? "Auto (\(playerView.getVideoResolution()))" : "Auto"
        let autoOption = UIAlertAction(title: autoOptionTitle, style: .default) { [self] _ in playerView.setPeakBitRate(bitrate: 0) }
        autoOption.setValue(quality == "Auto", forKey: "checked")
        actionSheet.addAction(autoOption)

        qualities.forEach { i in
            let action = UIAlertAction(title: i.getResolution(), style: .default) { [self] _ in
                playerView.setPeakBitRate(bitrate: Quality.getBitRate(resolution: i.getResolution()))
            }

            action.setValue(quality == i.getResolution(), forKey: "checked")
            actionSheet.addAction(action)
        }

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in })
        present(actionSheet, animated: true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        playerView.player?.pause()
    }

    func setButtonState(name: String, enabled: Bool) {
        switch name {
        case "next":
            btnNext.isEnabled = enabled
            btnNext.alpha = enabled ? 1 : 0.5
        case "previous":
            btnPrevious.isEnabled = enabled
            btnPrevious.alpha = enabled ? 1 : 0.5
        case "settings":
            btnSettings.isHidden = !enabled
            constraintSpeedWithSettings?.isActive = enabled
            constraintSpeedWithoutSettings?.isActive = !enabled
        default:
            break
        }
    }

    func setResizeMode(mode: String) {
        resizeMode = mode
        playerView.setResizeMode(mode: mode)
    }

    func setTheme(theme: UIColor) {
        self.theme = theme

        seekbar?.currentTrackColor = theme
        seekbar?.thumbTrackColor = theme

        spinner.setColor(color: theme)
    }

    func setFullscreen(isFullscreen: Bool) {
        self.isFullscreen = isFullscreen
        playerView.event.emitOnFullscreenChange(isFullscreen: isFullscreen)
        if isFullscreen {
            constraintBtnFullscreenBottom?.constant += CGFloat(bottomMarginFullscreen)
            constraintSeekbarBottom?.constant += CGFloat(bottomMarginFullscreen)
            constraintDurationBottom?.constant += CGFloat(bottomMarginFullscreen)

            constraintSeekbarTrailing?.constant += 10
            constraintSeekbarLeading?.constant += 10
        } else {
            constraintBtnFullscreenBottom?.constant -= CGFloat(bottomMarginFullscreen)
            constraintSeekbarBottom?.constant -= CGFloat(bottomMarginFullscreen)
            constraintDurationBottom?.constant -= CGFloat(bottomMarginFullscreen)

            constraintSeekbarTrailing?.constant -= 10
            constraintSeekbarLeading?.constant -= 10

            playerView.setResizeMode(mode: resizeMode)
        }
    }

    func playVideo(source: VideoSource) {
        playerView.prepareAndPlay(source: source)

        if source.thumbUrl != nil {
            thumbnailView.downloaded(from: source.thumbUrl!)
            thumbnailView.isHidden = false
        }
    }
    
    func showTitle(title: String) {
        if(title != "") {
            titleView.text = title
            titleView.isEnabled = true
        }
    }

    func loadView1() {
        setUpPlayerContainerView()
        setUpPlayerView()
        setUpControls()
        setUpInfoView()
    }
}

extension String {
    func maxLength(length: Int) -> String {
        var str = self
        let nsString = str as NSString
        var dots = ""
        if nsString.length >= length {
            dots = nsString.length > length ? "..." : ""
            str = nsString.substring(with: NSRange(
                location: 0, length: nsString.length > length ? length : nsString.length
            ))
        }
        return str + dots
    }
}

class BsItem<T> {
    public var name: String
    public var value: T
    public var selected: Bool

    init(name: String, value: T, selected: Bool = false) {
        self.name = name
        self.value = value
        self.selected = selected
    }
}

enum SeekState: Int {
    case none
    case seekPress
    case seeking
    case skipping
}

enum PlayState: Int {
    case playing = 1
    case paused = 2
    case buffering = 4
    case ended = 3
}
