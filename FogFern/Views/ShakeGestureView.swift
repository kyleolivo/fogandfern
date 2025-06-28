//
//  ShakeGestureView.swift
//  FogFern
//
//  Created by Kyle Olivo on 6/28/25.
//

import SwiftUI
import UIKit

struct ShakeGestureViewModifier: ViewModifier {
    let onShake: () -> Void
    
    func body(content: Content) -> some View {
        content
            .background(ShakeDetectionView(onShake: onShake))
    }
}

struct ShakeDetectionView: UIViewRepresentable {
    let onShake: () -> Void
    
    func makeUIView(context: Context) -> ShakeDetectingView {
        let view = ShakeDetectingView()
        view.onShake = onShake
        return view
    }
    
    func updateUIView(_ uiView: ShakeDetectingView, context: Context) {
        uiView.onShake = onShake
    }
}

class ShakeDetectingView: UIView {
    var onShake: (() -> Void)?
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            onShake?()
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        becomeFirstResponder()
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeGestureViewModifier(onShake: action))
    }
}