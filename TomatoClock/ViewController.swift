//
//  ViewController.swift
//  TomatoClock
//
//  Created by zhouchun on 2020/7/13.
//  Copyright © 2020 Hiuson. All rights reserved.
//

import UIKit
import SnapKit
import AudioToolbox

class ViewController: UIViewController {
    
    private var displayLink: CADisplayLink!
    
    private let foreColor = UIColor.white
    private let backColor = UIColor.black
    private let textSize: CGFloat = 160
    
    private var longPress: UILongPressGestureRecognizer!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        let link = CADisplayLink(target: WeakProxy(target: self), selector: #selector(self.displayLinkRefreshed(_:)))
        link.add(to: .main, forMode: .common)
        self.displayLink = link
        
        self.longPress = UILongPressGestureRecognizer.init(target: self, action: #selector(self.longPressResponse(_:)))
    }
    
    @available(*, unavailable, message:"init is unavailable")
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        let link = CADisplayLink(target: WeakProxy(target: self), selector: #selector(self.displayLinkRefreshed(_:)))
        link.add(to: .main, forMode: .common)
        self.displayLink = link
        
        self.longPress = UILongPressGestureRecognizer.init(target: self, action: #selector(self.longPressResponse(_:)))
    }
    
    deinit {
        displayLink.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = backColor
    
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(self.forceContinue))
        self.view.addGestureRecognizer(tap)
        
        view.addSubview(timeStackView)
        timeStackView.snp.makeConstraints { (make) in
            make.center.equalTo(view)
            make.width.equalTo(530)
        }
    }
    
    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: textSize, weight: .bold)
        label.textColor = foreColor
        return label
    }()
    
    private lazy var timeStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: self.timeLabels)
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private lazy var timeLabels: [UILabel] = {
        return (0...4).map { (_) -> UILabel in
            let label = UILabel()
            label.font = .systemFont(ofSize: textSize, weight: .bold)
            label.textColor = foreColor
            label.textAlignment = .center
            return label
        }
    }()
    
    private lazy var continueBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.addTarget(self, action: #selector(self.continueClicked), for: .touchUpInside)
        btn.layer.cornerRadius = 3
        btn.layer.borderWidth = 1
        btn.layer.borderColor = foreColor.cgColor
        return btn
    }()
    
    var startTime = NSDate.now
    var countDown: TimeInterval = 25 * 60
    @objc func displayLinkRefreshed(_ link: CADisplayLink) {
        if pause {
            return
        }
        
        let timeinterval = countDown - NSDate.now.timeIntervalSince(startTime)
        
        if timeinterval <= 0 {
            timeUp()
        } else {
            updateTimeLabel(timeinterval)
        }
    }
    
    var pause: Bool = false
    func timeUp() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        let ani = CABasicAnimation(keyPath: "opacity")
        ani.isRemovedOnCompletion = false
        ani.fromValue = 1.0
        ani.toValue = 0
        ani.autoreverses = true
        ani.repeatCount = Float.greatestFiniteMagnitude
        ani.duration = 2.0
        ani.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        self.timeLabel.layer.add(ani, forKey: "alphaAni")
        
        pause = true
    }
    
    func updateTimeLabel(_ timeInterval: TimeInterval) {
        let min = Int(timeInterval) / 60
        let sec = Int(timeInterval) % 60
        timeLabel.text = String.init(format: "%02d : %02d", min, sec)
        
        timeLabels[0].text = "\(min / 10)"
        timeLabels[1].text = "\(min % 10)"
        timeLabels[2].text = ":"
        timeLabels[3].text = "\(sec / 10)"
        timeLabels[4].text = "\(sec % 10)"
    }
    
    @objc func continueClicked() {
        if pause {
            forceContinue()
        }
    }
    
    @objc func forceContinue() {
        startTime = NSDate.now
        countDown = (countDown > 15 * 60) ? 5 * 60 : 25 * 60
        countDown += 1
        
        self.timeLabel.layer.removeAllAnimations()
        
        pause = false
    }
    
    var longPressTime = NSDate.now
    @objc func longPressResponse(_ longPress: UILongPressGestureRecognizer) {
        switch longPress.state {
        case .began:
            longPressTime = NSDate.now
        case .changed:
            updateLongPressEffect()
        case .ended:
            timeLabel.alpha = 1.0
            longPress.isEnabled = true
        default: break
        }
    }
    
    func updateLongPressEffect() {
        let timeInterval = NSDate.now.timeIntervalSince(longPressTime)
        let max = 2.0
        if timeInterval >= max {
            forceContinue()
            longPress.isEnabled = false
        } else {
            timeLabel.alpha = CGFloat((2.0 - timeInterval) / 2.0)
        }
    }
}

public final class WeakProxy<T: NSObjectProtocol>: NSObject {
    
    private weak var target: T?
    
    init(target: T) {
        self.target = target
        
        super.init()
    }
    
    public override func responds(to aSelector: Selector!) -> Bool {
        return (target?.responds(to: aSelector) ?? false) || super.responds(to: aSelector)
    }
    
    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return target
    }
    
}

