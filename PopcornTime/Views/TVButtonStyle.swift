//
//  TVButtonStyle.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 20.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import Foundation
import SwiftUI

struct TVButtonStyle: ButtonStyle {
    var onFocus: () -> Void = {}
    
    func makeBody(configuration: Self.Configuration) -> some View {
        TVButton(configuration: configuration, onFocus: onFocus)
    }
}

struct TVButton: View {
    struct Theme {
        let fontSize: CGFloat = value(tvOS: 23, macOS: 16)
    }
    let theme = Theme()
    
    @Environment(\.isFocused) var focused: Bool
    let configuration: ButtonStyle.Configuration
    var onFocus: () -> Void = {}

    var body: some View {
        return configuration.label
            .scaleEffect(focused ? 1.1 : 1)
        #if os(tvOS)
            .focusable(true)
        #endif
            .font(.system(size: theme.fontSize, weight: .medium))
            .foregroundColor(focused ? .white : Color(white: 1, opacity: 0.6))
            .animation(.easeOut, value: focused)
            .onChange(of: focused) { newValue in
                if newValue {
                    onFocus()
                }
            }
    }
}