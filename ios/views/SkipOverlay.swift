//
// Created by Samar Yalini on 28/07/21.
//

import Foundation
import ValueAnimator
import YRipple

enum SkipDirection {
    case left
    case right
}

class SkipOverlay: UIControl {
    private var seconds = UILabel()
    private var playerView: PlayerView? = nil
    private var containerView = UIView()

    private var direction: SkipDirection = .left

    var endCallback: (() -> ())? = nil
    var startCallback: (() -> ())? = nil

    private var setupDone = false

    private var constraintLeadingAnchor: NSLayoutConstraint? = nil
    private var constraintTrailingAnchor: NSLayoutConstraint? = nil

    private var constraintIcon1Trailing: NSLayoutConstraint? = nil
    private var constraintIcon1Leading: NSLayoutConstraint? = nil

    private var constraintIcon3Trailing: NSLayoutConstraint? = nil
    private var constraintIcon3Leading: NSLayoutConstraint? = nil

    private var constraintIcon2Center: NSLayoutConstraint? = nil
    private var constraintSecondsCenter: NSLayoutConstraint? = nil

    private var currentSeconds = 10 {
        didSet {
            seconds.text = "\(currentSeconds) seconds"
        }
    }
    private var debounceTimer: Timer? = nil

    func setPlayerView(view: PlayerView) {
        playerView = view
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupOnce()
    }

    private func drawCurve() {
        let isLeft = direction == .left

        let rectShape = CAShapeLayer()
        rectShape.bounds = frame
        rectShape.position = center

        let widthPx = frame.width
        let heightPx = frame.height
        let arcSize = CGFloat(20)
        let w = isLeft ? 0 : widthPx
        let f = CGFloat(isLeft ? 1 : -1)
        let halfWidth = widthPx * 0.5

        let p = UIBezierPath()
        p.move(to: CGPoint(x: w, y: 0))
        p.addLine(to: CGPoint(x: (f * (halfWidth - arcSize) + w), y: 0))
        p.addQuadCurve(
                to: CGPoint(x: f * (halfWidth - arcSize) + w, y: heightPx),
                controlPoint: CGPoint(x: f * (halfWidth + arcSize) + w , y: heightPx / 2)
        )
        p.addLine(to: CGPoint(x: w, y: frame.height))
        p.close()

        rectShape.path = p.cgPath

        layer.backgroundColor = UIColor.init(hexString: "#20EEEEEE").cgColor
        layer.mask = rectShape
    }

    private func setupOnce() {
        if setupDone {
            return
        }

        setupDone = true

        backgroundColor = UIColor.black.withAlphaComponent(0.4)

        // CONTAINER
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        containerView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5).isActive = true

        constraintLeadingAnchor = containerView.leadingAnchor.constraint(equalTo: leadingAnchor)
        constraintTrailingAnchor = containerView.trailingAnchor.constraint(equalTo: trailingAnchor)

        // ICON 1
        icon1.font = UIFont.fontAwesome(ofSize: 25, style: .solid)
        icon1.text = String.fontAwesomeIcon(name: .caretRight)
        icon1.textColor = .white

        containerView.addSubview(icon1)
        icon1.translatesAutoresizingMaskIntoConstraints = false
        icon1.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true

        constraintIcon1Trailing = icon1.trailingAnchor.constraint(equalTo: icon2.leadingAnchor, constant: -2)
        constraintIcon1Leading = icon1.leadingAnchor.constraint(equalTo: icon2.trailingAnchor, constant: 2)

        // ICON 2
        icon2.font = UIFont.fontAwesome(ofSize: 25, style: .solid)
        icon2.text = String.fontAwesomeIcon(name: .caretRight)
        icon2.textColor = .white

        containerView.addSubview(icon2)
        icon2.translatesAutoresizingMaskIntoConstraints = false
        icon2.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        constraintIcon2Center = icon2.centerXAnchor.constraint(equalTo: containerView.centerXAnchor, constant: -25)
        constraintIcon2Center?.isActive = true

        // ICON 3
        icon3.font = UIFont.fontAwesome(ofSize: 25, style: .solid)
        icon3.text = String.fontAwesomeIcon(name: .caretRight)
        icon3.textColor = .white

        containerView.addSubview(icon3)
        icon3.translatesAutoresizingMaskIntoConstraints = false
        icon3.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true

        constraintIcon3Trailing = icon3.trailingAnchor.constraint(equalTo: icon2.leadingAnchor, constant: -2)
        constraintIcon3Leading = icon3.leadingAnchor.constraint(equalTo: icon2.trailingAnchor, constant: 2)


        // SECONDS VIEW
        seconds.text = "10 seconds"
        seconds.font = seconds.font.withSize(12)
        seconds.textColor = .white
        containerView.addSubview(seconds)
        seconds.translatesAutoresizingMaskIntoConstraints = false
        seconds.topAnchor.constraint(equalTo: icon2.bottomAnchor, constant: 5).isActive = true
        constraintSecondsCenter = seconds.centerXAnchor.constraint(equalTo: containerView.centerXAnchor, constant: -25)
        constraintSecondsCenter?.isActive = true

        initializeAnimators()

        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
    }

    private func setupLayout() {
        drawCurve()

        if direction == .left {
            icon1.text = String.fontAwesomeIcon(name: .caretLeft)
            icon2.text = String.fontAwesomeIcon(name: .caretLeft)
            icon3.text = String.fontAwesomeIcon(name: .caretLeft)

            constraintIcon1Trailing?.isActive = false
            constraintIcon1Leading?.isActive = true

            constraintIcon3Leading?.isActive = false
            constraintIcon3Trailing?.isActive = true

            constraintTrailingAnchor?.isActive = false
            constraintLeadingAnchor?.isActive = true

            constraintIcon2Center?.constant = -25
            constraintSecondsCenter?.constant = -25
        } else {
            icon1.text = String.fontAwesomeIcon(name: .caretRight)
            icon2.text = String.fontAwesomeIcon(name: .caretRight)
            icon3.text = String.fontAwesomeIcon(name: .caretRight)

            constraintIcon1Leading?.isActive = false
            constraintIcon1Trailing?.isActive = true

            constraintIcon3Trailing?.isActive = false
            constraintIcon3Leading?.isActive = true

            constraintLeadingAnchor?.isActive = false
            constraintTrailingAnchor?.isActive = true

            constraintIcon2Center?.constant = 25
            constraintSecondsCenter?.constant = 25
        }
    }

    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: self)
        let screenWidth = frame.size.width;

        if point.x > (screenWidth / 2) {
            incrementIn(direction: .right)
        } else {
            incrementIn(direction: .left)
        }

        rippleStop()
        rippleFill(location: point, color: UIColor(hexString: "#18FFFFFF"))
    }

    private func incrementIn(direction: SkipDirection) {
        if self.direction == direction {
            increment()
            return
        }

        updateSeekPosition()
        
        self.direction = direction
        restart()
    }

    private func updateSeekPosition() {
        let duration = playerView?.getDuration() ?? 0
        let progress = playerView?.getCurrentProgress() ?? 0
        let inc = currentSeconds
        var newPosition: Double = progress + Double((direction == .left ? -inc : inc))

        if newPosition < 0 {
            newPosition = 0
        } else if newPosition > duration {
            newPosition = duration
        }

        playerView?.seekTo(time: newPosition, completion: { _ in })
    }

    private func restart() {
        let duration = playerView?.getDuration() ?? 0
        let progress = playerView?.getCurrentProgress() ?? 0

        if duration < 0 {
            return
        }

        if direction == .left && progress <= 0 {
            return
        } else if direction == .right && progress >= duration {
            return
        }

        debounceTimer?.invalidate()

        currentSeconds = 10
        setupLayout()
        startTriAnimation()
        isHidden = false
        finishWithAnimation()
    }

    private func increment() {
        currentSeconds += 10
        finishWithAnimation()
    }

    func start(direction: SkipDirection) {
        if !isHidden {
            return
        }

        self.direction = direction

        restart()
        startCallback?()
    }

    private func finishWithAnimation() {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(1), repeats: false) { [self] _ in
            finish()
        }
    }

    func finish() {
        updateSeekPosition()
        stopTriAnimation()
        isHidden = true
        endCallback?()
    }

    private func resetIcons() {
        icon1.alpha = 0
        icon2.alpha = 0
        icon3.alpha = 0
    }

    private func stopTriAnimation() {
        firstAnimator?.cancel()
        secondAnimator?.cancel()
        thirdAnimator?.cancel()
        fourthAnimator?.cancel()
        fifthAnimator?.cancel()
        resetIcons()
    }

    func startTriAnimation() {
        stopTriAnimation()
        firstAnimator?.start()
    }


    var icon1 = UILabel()
    var icon2 = UILabel()
    var icon3 = UILabel()

    let animationDuration = 1000

    func initializeAnimators() {
        firstAnimator = CustomValueAnimator(
                duration: Double(animationDuration / 5),
                start: { [self] in
                    icon1.alpha = 0
                    icon2.alpha = 0
                    icon3.alpha = 0
                },
                update: { [self] it in
                    icon1.alpha = CGFloat(it)
                },
                end: { [self] in
                    secondAnimator?.start()
                }
        )

        secondAnimator = CustomValueAnimator(
                duration: Double(animationDuration / 5),
                start: { [self] in
                    icon1.alpha = 1
                    icon2.alpha = 0
                    icon3.alpha = 0
                },
                update: { [self] it in
                    icon2.alpha = CGFloat(it)
                },
                end: { [self] in
                    thirdAnimator?.start()
                }
        )

        thirdAnimator = CustomValueAnimator(
                duration: Double(animationDuration / 5),
                start: { [self] in
                    icon1.alpha = 1
                    icon2.alpha = 1
                    icon3.alpha = 0
                },
                update: { [self] it in
                    icon1.alpha = 1 - icon3.alpha // or 1f - it (t3.alpha => all three stay a little longer together)
                    icon3.alpha = CGFloat(it)
                },
                end: { [self] in
                    fourthAnimator?.start()
                }
        )

        fourthAnimator = CustomValueAnimator(
                duration: Double(animationDuration / 5),
                start: { [self] in
                    icon1.alpha = 0
                    icon2.alpha = 1
                    icon3.alpha = 1
                },
                update: { [self] it in
                    icon2.alpha = CGFloat(1 - it)
                },
                end: { [self] in
                    fifthAnimator?.start()
                }
        )

        fifthAnimator = CustomValueAnimator(
                duration: Double(animationDuration / 5),
                start: { [self] in
                    icon1.alpha = 0
                    icon2.alpha = 0
                    icon3.alpha = 1
                },
                update: { [self] it in
                    icon3.alpha = CGFloat(1 - it)
                },
                end: { [self] in
                    firstAnimator?.start()
                }
        )
    }

    private var firstAnimator: CustomValueAnimator? = nil
    private var secondAnimator: CustomValueAnimator? = nil
    private var thirdAnimator: CustomValueAnimator? = nil
    private var fourthAnimator: CustomValueAnimator? = nil
    private var fifthAnimator: CustomValueAnimator? = nil
}

class CustomValueAnimator {
    let duration: TimeInterval

    let startFn: () -> Void
    let updateFn: (Double) -> Void
    let endFn: () -> Void

    var animator: ValueAnimator? = nil
    var isCanceled = false

    init (
            duration: TimeInterval,
            start: @escaping () -> Void,
            update: @escaping (Double) -> Void,
            end: @escaping () -> Void
    ) {
        self.duration = duration / 1000
        startFn = start
        endFn = end
        updateFn = update
    }

    func start() {
        isCanceled = false
        animator = ValueAnimator.animate("alpha", from: 0, to: 1, duration: duration,
                easing: EaseLinear.easeIn(),
                onChanged: { p, v in
                    self.updateFn(v.value)
                }
        )
        animator?.endCallback = { [self] in
            if !isCanceled {
                endFn()
            }
        }

        startFn()
        animator?.resume()
    }

    func cancel() {
        isCanceled = true
        animator?.finish()
    }

    deinit {
        animator?.dispose()
    }
}
