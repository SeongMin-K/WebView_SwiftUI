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
    let refreshHelper = WebViewRefreshControlHelper()
    
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
        
        let myRefreshControl = UIRefreshControl()
        myRefreshControl.tintColor = UIColor.blue
        
        refreshHelper.viewModel = viewModel
        refreshHelper.refreshControl = myRefreshControl
        
        myRefreshControl.addTarget(refreshHelper, action: #selector(WebViewRefreshControlHelper.didRefresh), for: .valueChanged)
        
        webView.scrollView.refreshControl = myRefreshControl
        webView.scrollView.bounces = true
        
        webView.load(URLRequest(url: url))
        
        return webView
    }
    
    // Update UI View
    func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<MyWebView>) {
        
    }
    
    func createWKWebConfig() -> WKWebViewConfiguration {
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        
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
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        print("webView runJavaScriptAlertPanelWithMessage")
        self.myWebView.viewModel.JsAlertEvent.send(JsAlert(message, .alert))
        completionHandler()
    }
}

extension MyWebView.Coordinator: WKNavigationDelegate {
    // 웹 뷰 검색 시작
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print(#fileID, "didStartProvisionalNavigation called")
        
        // 로딩 중 알리기
        myWebView.viewModel.shouldShowIndicator.send(true)
        
        myWebView
            .viewModel
            .webNavigationSubject
            .sink { (action: Web_Navigation) in
                print("들어온 네비게이션 액션:", action)
                switch action {
                case .back:
                    if webView.canGoBack {
                        webView.goBack()
                    }
                case .forward:
                    if webView.canGoForward {
                        webView.goForward()
                    }
                case .refresh:
                    webView.reload()
                }
            }.store(in: &subscriptions)
    }
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print(#fileID, "didCommit called")
        myWebView.viewModel.shouldShowIndicator.send(true)
    }
    
    // 웹 뷰 검색 완료
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print(#fileID, "didFinish called")
        
        webView.evaluateJavaScript("document.title") { (response, error) in
            if error != nil {
                print("Title Error!")
            }
            if let title = response as? String {
                self.myWebView.viewModel.webSiteTitleSubject.send(title)
            }
        }
        
        myWebView
            .viewModel
            .nativeToJsEvent
            .sink { message in
                print(#fileID, #function, "called / nativeToJsEvent 들어옴 / message:", message)
                webView.evaluateJavaScript("nativeToJsEventCall('\(message)');", completionHandler: { (result, error) in
                    if let result = result {
                        print("nativeToJs result 성공:", result)
                    }
                    if let error = error {
                        print("nativeToJs result 실패:", error.localizedDescription)
                    }
                })
            }.store(in: &subscriptions)
        
        myWebView
            .viewModel
            .changedUrlSubject
            .compactMap { $0.url }
            .sink { changedUrl in
                print("변경된 url:", changedUrl)
                webView.load(URLRequest(url: changedUrl))
            }.store(in: &subscriptions)
        
        // 로딩이 끝났다고 알림
        self.myWebView.viewModel.shouldShowIndicator.send(false)
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print(#fileID, #function, "called")
        // 로딩이 끝났다고 알림
        self.myWebView.viewModel.shouldShowIndicator.send(false)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print(#fileID, "didFail called")
        // 로딩이 끝났다고 알림
        self.myWebView.viewModel.shouldShowIndicator.send(false)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print(#fileID, "didFailProvisionalNavigation called")
        // 로딩이 끝났다고 알림
        self.myWebView.viewModel.shouldShowIndicator.send(false)
    }
}

extension MyWebView.Coordinator: WKScriptMessageHandler {
    // 웹 뷰 JS에서 iOS 네이티브를 호출하는 메소드들이 이쪽을 탐
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("MyWebViewCoordinator - userContentController / message:", message)
        if message.name == "callbackHandler" {
            print("JSON 데이터가 웹으로부터 전달됨", message.body)
            if let receivedData: [String: String] = message.body as? Dictionary {
                print("receivedData:", receivedData)
                myWebView.viewModel.JsAlertEvent.send(JsAlert(receivedData["message"], .bridge))
            }
        }
    }
}
