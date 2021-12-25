//
//  LoadingIndicatorView.swift
//  WebView_SwiftUI
//
//  Created by SeongMinK on 2021/12/25.
//

import SwiftUI
import UIKit

struct LoadingIndicatorView: UIViewRepresentable {
    var isAnimating: Bool = true
    var color: UIColor = .white
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView()
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<Self>) {
        isAnimating ? uiView.startAnimating(): uiView.startAnimating()
        uiView.style = .large
        uiView.color = color
    }
}
