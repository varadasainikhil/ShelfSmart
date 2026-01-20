//
//  View+GlassEffect.swift
//  ShelfSmart
//
//  Created for iOS 18-26 backward compatibility
//

import SwiftUI

extension View {
    /// Applies glass effect on iOS 26+ devices, no effect on earlier versions
    @ViewBuilder
    func conditionalGlassEffect() -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
        } else {
            self
        }
    }
}
