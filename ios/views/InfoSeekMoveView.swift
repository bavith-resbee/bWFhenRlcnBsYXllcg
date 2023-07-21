//
// Created by Samar Yalini on 08/08/21.
//

import Foundation

class InfoSeekMoveView: UIView {

    private var icon1 = UILabel()
    private var icon2 = UILabel()
    private var icon3 = UILabel()
    private var icon4 = UILabel()
    private var icon5 = UILabel()
    private var icon6 = UILabel()

    private var text = UILabel()

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    func setUp() {
        icon1.font = UIFont.fontAwesome(ofSize: 25, style: .solid)
        icon2.font = UIFont.fontAwesome(ofSize: 25, style: .solid)
        icon3.font = UIFont.fontAwesome(ofSize: 25, style: .solid)
        icon4.font = UIFont.fontAwesome(ofSize: 25, style: .solid)
        icon5.font = UIFont.fontAwesome(ofSize: 25, style: .solid)
        icon6.font = UIFont.fontAwesome(ofSize: 25, style: .solid)

        icon1.textColor = .white
        icon2.textColor = .white
        icon3.textColor = .white
        icon4.textColor = .white
        icon5.textColor = .white
        icon6.textColor = .white
        text.textColor = .white

        icon1.textAlignment = .center
        icon2.textAlignment = .center
        icon3.textAlignment = .center
        icon4.textAlignment = .center
        icon5.textAlignment = .center
        icon6.textAlignment = .center
        text.textAlignment = .center

        icon1.textColor = .white
        icon2.textColor = .white
        icon3.textColor = .white
        icon4.textColor = .white
        icon5.textColor = .white
        icon6.textColor = .white

        icon1.alpha = 1
        icon2.alpha = 0.8
        icon3.alpha = 0.6
        icon4.alpha = 1
        icon5.alpha = 0.8
        icon6.alpha = 0.6

        icon1.text = String.fontAwesomeIcon(name: .caretLeft)
        icon2.text = String.fontAwesomeIcon(name: .caretLeft)
        icon3.text = String.fontAwesomeIcon(name: .caretLeft)
        icon4.text = String.fontAwesomeIcon(name: .caretRight)
        icon5.text = String.fontAwesomeIcon(name: .caretRight)
        icon6.text = String.fontAwesomeIcon(name: .caretRight)

        text.font = text.font.withSize(12)
        text.text = "Double tap left or right to seek 10 seconds"

        addSubview(icon1)
        addSubview(icon2)
        addSubview(icon3)
        addSubview(icon4)
        addSubview(icon5)
        addSubview(icon6)
        addSubview(text)

        icon1.translatesAutoresizingMaskIntoConstraints = false
        icon2.translatesAutoresizingMaskIntoConstraints = false
        icon3.translatesAutoresizingMaskIntoConstraints = false
        icon4.translatesAutoresizingMaskIntoConstraints = false
        icon5.translatesAutoresizingMaskIntoConstraints = false
        icon6.translatesAutoresizingMaskIntoConstraints = false
        text.translatesAutoresizingMaskIntoConstraints = false

        icon1.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        icon2.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        icon3.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        icon4.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        icon5.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        icon6.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        text.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        text.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true

        icon1.trailingAnchor.constraint(equalTo: text.leadingAnchor, constant: -5).isActive = true
        icon2.trailingAnchor.constraint(equalTo: icon1.leadingAnchor, constant: 0).isActive = true
        icon3.trailingAnchor.constraint(equalTo: icon2.leadingAnchor, constant: 0).isActive = true

        icon4.leadingAnchor.constraint(equalTo: text.trailingAnchor, constant: 5).isActive = true
        icon5.leadingAnchor.constraint(equalTo: icon4.trailingAnchor, constant: 0).isActive = true
        icon6.leadingAnchor.constraint(equalTo: icon5.trailingAnchor, constant: 0).isActive = true
    }
}