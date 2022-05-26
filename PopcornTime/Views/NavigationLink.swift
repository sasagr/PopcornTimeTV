//
//  NavigationLink.swift
//  NavigationLink
//
//  Created by Alexandru Tudose on 03.10.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI

typealias NavigationLink = StackNavigationLink

public struct StackNavigationLink<Label: View, Destination: View>: View {
    
    private var label: Label
    private var destination: Destination
    @Binding var isActive: Bool
    
    @Environment(\.push) private var push
    
    @State var isHovering: Bool = false
    
    public var body: some View {
        let action = {
            withAnimation {
                self.push(AnyView(destination), nil)
            }
        }
        
        Button(action: action, label: { label })
            .onChange(of: isActive) { newValue in
                if newValue {
                    self.push(AnyView(destination), _isActive)
                }
            }
            .onHover { hover in
                isHovering = hover
            }
            .environment(\.isFocused, isHovering)
    }

    /// Creates an instance that presents `destination`.
    public init(destination: Destination, @ViewBuilder label: () -> Label) {
        self.label = label()
        self.destination = destination
        _isActive = .constant(false)
    }
//
    public init(destination: Destination, isActive: Binding<Bool>, @ViewBuilder label: @escaping () -> Label) {
        self.label = label()
        self.destination = destination
        _isActive = isActive
    }
//
//    /// Creates an instance that presents `destination` when `selection` is set
//    /// to `tag`.
//    public init<V>(destination: Destination, tag: V, selection: Binding<V?>, @ViewBuilder label: @escaping () -> Label) where V : Hashable {
//        self.label = label
//        self.destination = destination
//    }
    
    public init(isActive: Binding<Bool>, @ViewBuilder destination: () -> Destination, @ViewBuilder label: () -> Label) {
        self.destination = destination()
        self.label = label()
        _isActive = isActive
    }
    
    public init(@ViewBuilder destination: () -> Destination, @ViewBuilder label: () -> Label) {
        self.destination = destination()
        self.label = label()
        _isActive = .constant(false)
    }
}
