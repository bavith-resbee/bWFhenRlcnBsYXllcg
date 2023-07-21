//
//  Slider.swift
//  MaazterPlayer
//
//  Created by Samar Yalini on 07/08/21.
//  Copyright © 2021 Facebook. All rights reserved.
//

import Foundation

public protocol SliderDelegate: AnyObject {
    func onScrubStart()
    func onScrubMove()
    func onScrubStop()
}

public class Slider: UIControl {
    public weak var delegate: SliderDelegate?

    private var fullTrack : UIView = UIView()
    private var currentTrack: UIView = UIView()
    private var bufferTrack: UIView = UIView()
    private var thumbImage: UIImageView = UIImageView()

    public var fullTrackColor: UIColor = .clear {
        didSet {
            fullTrack.backgroundColor = fullTrackColor
        }
    }
    public var bufferTrackColor: UIColor = UIColor(hexString: "66ffffff") {
        didSet {
            bufferTrack.backgroundColor = bufferTrackColor
        }
    }
    public var currentTrackColor: UIColor = .red {
        didSet {
            currentTrack.backgroundColor = currentTrackColor
        }
    }
    public var thumbTrackColor: UIColor = .red {
        didSet {
            thumbImage.backgroundColor = thumbTrackColor
        }
    }

    public var sliderAlignment: SliderAlignment = .center
    public var minimumValue: CGFloat = 0 {
        didSet {
            computeValues()
        }
    }
    public var maximumValue: CGFloat = 1 {
        didSet {
            computeValues()
        }
    }
    public var trackHeight: CGFloat = 4
    public var thumbHeight: CGFloat = 12 {
        didSet {
            computeValues()
        }
    }

    private var frameWidth: CGFloat = 0
    private var frameHeight: CGFloat = 0
    private var thumbTrackWidth: CGFloat = 0
    private var valueConversion: CGFloat = 0
    private var pointConversion: CGFloat = 0
    private var handleTouch: Bool = false
    private var setUpDone: Bool = false
    private var handleValueChange: Bool = true
    private var bufferCurrentPosition: CGFloat = 0
    private var currentPosition: CGFloat = 0
    private var bufferTrackPosition: CGFloat {
        bufferValue * valueConversion
    }
    private var thumbInitialCurrentPosition: CGFloat {
        if value*valueConversion > thumbTrackWidth {
            return thumbTrackWidth
        }
        return value*valueConversion
    }
    private var bufferInitialCurrentPosition: CGFloat {
        bufferValue * valueConversion
    }
    public var value: CGFloat = 0 {
        didSet {
            if setUpDone {
                currentPosition = value*valueConversion
                if currentPosition > thumbTrackWidth {
                    currentPosition = thumbTrackWidth
                }
                updateFramesFromValue()
            } else {
                draw(frame)
            }
        }
    }
    public var bufferValue: CGFloat = 0 {
        didSet {
            if setUpDone {
                bufferCurrentPosition = bufferValue*valueConversion
                updateBufferFrame()
            }
        }
    }
    private var trackY: CGFloat {
        switch sliderAlignment {
        case .top:
            return (thumbHeight - trackHeight)/2
        case .bottom:
            return frameHeight - (thumbHeight + trackHeight)/2
        default:
            return (frameHeight - trackHeight)/2
        }
    }
    private var thumbY: CGFloat {
        switch sliderAlignment {
        case .top:
            return 0
        case .bottom:
            return frameHeight - thumbHeight
        default:
            return (frameHeight - thumbHeight)/2
        }
    }

    override init(frame:CGRect) {
        super.init(frame:frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        frameWidth = frame.width
        frameHeight = frame.height
        setUpUI()
    }

    func computeValues() {
        thumbTrackWidth = frameWidth-thumbHeight
        valueConversion = frameWidth/(maximumValue-minimumValue)
        pointConversion = (maximumValue-minimumValue)/frameWidth
    }

    func setUpUI() {
        backgroundColor = UIColor.red
        addViews()
    }

    func addViews() {
        computeValues()
        fullTrack = UIView(frame: CGRect(x: 0, y: trackY, width: frame.width, height: trackHeight))
        addSubview(fullTrack)

        bufferTrack = UIView(frame: CGRect(x: 0, y: trackY, width: bufferInitialCurrentPosition, height: trackHeight))
        currentTrack = UIView(frame: CGRect(x: 0, y: trackY, width: thumbInitialCurrentPosition, height: trackHeight))
        thumbImage = Scrubber(frame: CGRect(x: thumbInitialCurrentPosition, y: thumbY, width: thumbHeight, height: thumbHeight))

        fullTrack.backgroundColor = fullTrackColor
        bufferTrack.backgroundColor = bufferTrackColor
        currentTrack.backgroundColor = currentTrackColor
        thumbImage.backgroundColor = thumbTrackColor
        thumbImage.layer.cornerRadius = trackHeight*2

        addSubview(bufferTrack)
        addSubview(currentTrack)
        addSubview(thumbImage)

        addTapGestureRecogniser()
        setUpDone = true
    }

    public override var intrinsicContentSize: CGSize {
        frame.size
    }

    func addTapGestureRecogniser() {
        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapImageView(_:))))
    }

    func updateFrames() {
        if handleTouch {
            UIView.animateKeyframes(withDuration: 0, delay: 0, options: []) { [weak self] in
                guard let self = self else { return }
                self.thumbImage.frame.origin.x = self.currentPosition
                self.currentTrack.frame.size.width = self.currentPosition
            }
        }
    }

    func updateFramesFromValue() {
        if handleValueChange {
            UIView.animateKeyframes(withDuration: 0, delay: 0, options: []) { [weak self] in
                self?.thumbImage.frame.origin.x = self?.currentPosition ?? 0
                self?.currentTrack.frame.size.width = self?.currentPosition ?? 0
            }
        }
    }

    func updateBufferFrame() {
        UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: []) { [weak self] in
            guard let self = self else { return }
            self.bufferTrack.frame.size.width = self.bufferCurrentPosition
        }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleValueChange = false
        let touch = touches.first
        let point = touch!.location(in: thumbImage)

        if point.x < thumbHeight && point.x > -thumbHeight {
            handleTouch = true
        }else {
            handleTouch = false
        }

        delegate?.onScrubStart()
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        delegate?.onScrubStop()
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let point = touch!.location(in: self)

        if point.x > 0 && point.x < (frame.width - thumbHeight) {
            currentPosition = point.x
        }else if point.x <= 0 {
            currentPosition = 0
        }else if point.x >= (frame.width - thumbHeight){
            currentPosition = frame.width - thumbHeight
        }

        updateFrames()

        delegate?.onScrubMove()
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let point = touch!.location(in: self)

        if point.x <= 0 {
            currentPosition = 0
        }else if point.x >= (frame.width - thumbHeight) {
            currentPosition = frameWidth - thumbHeight
        }

        updateFrames()

        value = currentPosition*pointConversion
        handleTouch = false
        handleValueChange = true

        sendActions(for: .valueChanged)

        delegate?.onScrubStop()
    }

    @IBAction func didTapImageView(_ sender: UITapGestureRecognizer) {
        handleValueChange = false
        handleTouch = true

        let point = sender.location(in: self)
        if point.x > 0 && point.x < (frame.width - thumbHeight) {
            currentPosition = point.x
        } else if point.x <= 0 {
            currentPosition = 0
        } else if point.x >= (frame.width - thumbHeight) {
            currentPosition = frame.width - thumbHeight
        }

        updateFrames()

        value = currentPosition*pointConversion
        handleTouch = false
        handleValueChange = true

        sendActions(for: .valueChanged)
    }
}

public enum SliderAlignment {
    case top
    case bottom
    case center
}

class Scrubber: UIImageView {
    private var pressed = false

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapScrubber)))
    }

    @objc private func didTapScrubber() {
        if pressed == true {
            UIView.animate(withDuration: 0.1, animations: { [self] in
                frame.size.width = frame.size.width - 2
                frame.size.height = frame.size.height - 2
            })
            pressed = false
        }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        if pressed == false {
            pressed = true
            UIView.animate(withDuration: 0.1, animations: { [self] in
                frame.size.width = frame.size.width + 2
                frame.size.height = frame.size.height + 2
            })
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        didTapScrubber()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        didTapScrubber()

    }
}
