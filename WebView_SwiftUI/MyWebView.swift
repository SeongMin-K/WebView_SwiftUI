//
//  MyWebView.swift
//  WebView_SwiftUI
//
//  Created by SeongMinK on 2021/11/21.
//

import SwiftUI
import WebKit
import Combine

struct MyWebView: UIViewRepresentable {
    @EnvironmentObject var viewModel: MyWebViewModel
    var urlToLoad: String
    
    func makeCoordinator() -> MyWebView.Coordinator {
        return MyWebView.Coordinator(self)
    }
    
    // Make UI View
    func makeUIView(context: Context) -> WKWebView {
        guard let url = URL(string: self.urlToLoad) else { return WKWebView() }
        let webView = WKWebView(frame: .zero, configuration: createWKWebConfig())
        
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))
        
        return webView
    }
    
    // Update UI View
    func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<MyWebView>) {
        
    }
    
    func createWKWebConfig() -> WKWebViewConfiguration {
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        preferences.javaScriptEnabled = true
        
        let wkWebConfig = WKWebViewConfiguration()
        
        let userContentController = WKUserContentController()
        userContentController.add(self.makeCoordinator(), name: "callbackHandler")
        wkWebConfig.userContentController = userContentController
        wkWebConfig.preferences = preferences
        
        return wkWebConfig
    }
    
    class Coordinator: NSObject {
        var myWebView: MyWebView // SwiftUI View
        var subscriptions = Set<AnyCancellable>()
        
        init(_ myWebView: MyWebView) {
            self.myWebView = myWebView
        }
    }
}

extension MyWebView.Coordinator: WKUIDelegate {
    
}

extension MyWebView.Coordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print(#fileID, #function, "called")
        myWebView
            .viewModel
            .changedUrlSubject
            .compactMap { $0.url }
            .sink { changedUrl in
                print("변경된 url:", changedUrl)
                webView.load(URLRequest(url: changedUrl))
            }.store(in: &subscriptions)
    }
}

extension MyWebView.Coordinator: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("MyWebViewCoordinator - userContentController / message:", message)
    }
}
