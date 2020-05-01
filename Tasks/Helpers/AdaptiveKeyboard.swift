//
//  AdaptiveKeyboard.swift
//  Tasks
//
//  Created by Nick Garfitt on 30/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import SwiftUI
import Combine

struct AdaptiveKeyboard<Content: View>: View {
    
    let view: Content

    @State private var keyboardHeight: CGFloat = 0

    private let showPublisher = NotificationCenter.Publisher.init(
        center: .default,
        name: UIResponder.keyboardWillShowNotification
    ).map { (notification) -> CGFloat in
        if let rect = notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? CGRect {
            return rect.size.height
        } else {
            return 0
        }
    }

    private let hidePublisher = NotificationCenter.Publisher.init(
        center: .default,
        name: UIResponder.keyboardWillHideNotification
    ).map {_ -> CGFloat in 0}

    // Like HStack or VStack, the only parameter is the view that this view should layout.
    // (It takes one view rather than the multiple views that Stacks can take)
    init(@ViewBuilder content: () -> Content) {
        view = content()
    }
    /*
    var body: some View {
        VStack {
            view
            Rectangle()
                .frame(height: keyboardHeight)
                //.animation(.default)
                .animation(.easeOut(duration: 0.16))
                .foregroundColor(.clear)
        }.onReceive(showPublisher.merge(with: hidePublisher)) { (height) in
            self.keyboardHeight = height - 10
        }
    }
    */
    var body: some View {
        VStack {
            view
                .padding(.bottom, keyboardHeight)
                .animation(.none)
            
        } .onReceive(showPublisher.merge(with: hidePublisher)) {
            (height) in self.keyboardHeight = height
        }
    }
}

struct AdaptsToKeyboard: ViewModifier {
    @State var currentHeight: CGFloat = 0

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .padding(.bottom, self.currentHeight)
                .animation(.easeOut(duration: 0.16))
                .onAppear(perform: {
                    NotificationCenter.Publisher(center: NotificationCenter.default, name: UIResponder.keyboardWillShowNotification)
                        .merge(with: NotificationCenter.Publisher(center: NotificationCenter.default, name: UIResponder.keyboardWillChangeFrameNotification))
                        .compactMap { notification in
                            notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? CGRect
                    }
                    .map { rect in
                        rect.height - geometry.safeAreaInsets.bottom
                    }
                    .subscribe(Subscribers.Assign(object: self, keyPath: \.currentHeight))

                    NotificationCenter.Publisher(center: NotificationCenter.default, name: UIResponder.keyboardWillHideNotification)
                        .compactMap { notification in
                            CGFloat.zero
                    }
                    .subscribe(Subscribers.Assign(object: self, keyPath: \.currentHeight))
                })
        }
    }
}
