//
//  ProgressSliderView.swift
//  ExampleSwiftUI
//
//  Created by Yoheimuta on 2021/06/19.
//  Copyright © 2021 YOSHIMUTA YOHEI. All rights reserved.
//

import SwiftUI

struct ProgressSliderView: UIViewRepresentable {
    @EnvironmentObject var model: PlayerModel

    @Binding var value: Float
    @Binding var maximumValue: Float
    @Binding var isUserInteractionEnabled: Bool
    @Binding var playableProgress: Float
    var updateValueHandler: (Float) -> Void

    @State private var touching = false

    init(value: Binding<Float>,
         maximumValue: Binding<Float>,
         isUserInteractionEnabled: Binding<Bool>,
         playableProgress: Binding<Float>,
         updateValueHandler: @escaping (Float) -> Void) {
        self._value = value
        self._maximumValue = maximumValue
        self._isUserInteractionEnabled = isUserInteractionEnabled
        self._playableProgress = playableProgress
        self.updateValueHandler = updateValueHandler
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIProgressSlider {
        let slider = UIProgressSlider()
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.updateValue(sender:)),
            for: .valueChanged)

        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.startTouch(sender:)),
            for: .touchDown)

        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.endTouch(sender:)),
            for: .touchUpInside)

        return slider
    }

    func updateUIView(_ uiView: UIProgressSlider, context: Context) {
        if !touching {
            uiView.setValue(value, animated: true)
        }
        uiView.maximumValue = maximumValue
        uiView.isUserInteractionEnabled = isUserInteractionEnabled
        uiView.playableProgress = playableProgress
        uiView.touching = touching
        uiView.setNeedsDisplay()
    }

    class Coordinator: NSObject {
        var view: ProgressSliderView
        var playing: Bool = false

        init(_ view: ProgressSliderView) {
            self.view = view
        }

        @objc
        func updateValue(sender: UIProgressSlider) {
            view.updateValueHandler(sender.value)
        }

        @objc
        func startTouch(sender: UIProgressSlider) {
            if !view.model.canPlay {
                playing = true
                view.model.pause()
            }
            view.touching = true
        }

        @objc
        func endTouch(sender: UIProgressSlider) {
            if playing {
                view.model.play()
            }
            playing = false
            view.touching = false
        }

    }
}

class UIProgressSlider: UISlider {
    var playableProgress: Float = 0
    var touching: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        let newValue = self.minimumValue + Float(location.x / self.bounds.width) * (self.maximumValue - self.minimumValue)
        setValue(newValue, animated: true)
        return true
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        let newValue = self.minimumValue + Float(location.x / self.bounds.width) * (self.maximumValue - self.minimumValue)
        setValue(newValue, animated: true)
        return super.continueTracking(touch, with: event)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        setThumbImage(UIImage(), for: .normal)
        
        let trackSize = CGSize(width: rect.width, height: touching ? 14.0 : 8.0)

        let minimumTrackImage = UIGraphicsImageRenderer(size: rect.size).image { _ in
            UIColor(white: 1, alpha: 0.8).setFill()
            let roundedRect = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: 0, y: (rect.height - trackSize.height) / 2), size: trackSize), cornerRadius: trackSize.height / 2)
            roundedRect.fill()
        }

        let maximumTrackImage = UIGraphicsImageRenderer(size: rect.size).image { _ in
            UIColor(white: 1, alpha: 0.5).setFill()
            let roundedRect = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: 0, y: (rect.height - trackSize.height) / 2), size: trackSize), cornerRadius: trackSize.height / 2)
            roundedRect.fill()
        }
        
        setMinimumTrackImage(minimumTrackImage, for: .normal)
        setMaximumTrackImage(maximumTrackImage, for: .normal)
    }
}
