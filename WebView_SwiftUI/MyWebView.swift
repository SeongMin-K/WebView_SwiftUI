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

//MARK: - ???????????? ??????
extension MyWebView.Coordinator {
    /// ???????????? ?????? ??????
    /// - Parameters:
    ///   - availableTypes: ???????????? ?????? ??????
    ///   - fileTypeToDownload: ????????????????????? ?????? ??????
    /// - Returns: ???????????? ?????? ??????
    fileprivate func checkDownloadAvailable(availableTypes: [String], fileTypeToDownload: String) -> Bool {
        print("checkDownloadAvailable() called - availableTypes: \(availableTypes) / fileTypeToDownload: (fileTypeToDownload)")
        let availableDictionaries = mimeTypes.filter { (key: String, value: String) in
            availableTypes.contains(key)
        }
        print("availableDictionaries:", availableDictionaries)
        
        return availableDictionaries.contains { (key: String, value: String) in
            value == fileTypeToDownload
        }
    }
    
    // ???????????? ?????? ????????? ?????? ?????? ?????? ??????
    fileprivate func moveDownloadFile(url: URL, fileName: String) -> URL {
        let tempDir = NSTemporaryDirectory()
        let destinationPath = tempDir + fileName
        let destinationFileURL = URL(fileURLWithPath: destinationPath)
        try? FileManager.default.removeItem(at: destinationFileURL)
        try? FileManager.default.moveItem(at: url, to: destinationFileURL)
        return destinationFileURL
    }
    
    // ?????? ????????????
    fileprivate func downloadFile(webView: WKWebView, url: URL, fileName: String, completion: @escaping (URL?) -> Void) {
        print(#fileID, #function, "called")
        
        // webView ?????? ????????????
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies({ fetchedCookies in
            let session = URLSession.shared
            session.configuration.httpCookieStorage?.setCookies(fetchedCookies, for: url, mainDocumentURL: nil)
            let downloadTask = session.downloadTask(with: url) { localUrl, urlResponse, error in
                print("???????????? ??????")
                if let localUrl = localUrl {
                    let finalDestinationUrl = self.moveDownloadFile(url: localUrl, fileName: fileName)
                    completion(finalDestinationUrl)
                } else {
                    completion(nil)
                }
            }
            downloadTask.resume()
        })
    }
}

//MARK: - UIDelegate ??????
extension MyWebView.Coordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        print("webView runJavaScriptAlertPanelWithMessage")
        self.myWebView.viewModel.JsAlertEvent.send(JsAlert(message, .alert))
        completionHandler()
    }
}

//MARK: - WKNavigationDelegate ?????? (?????? ??????)
extension MyWebView.Coordinator: WKNavigationDelegate {
    // ??????????????? ??????
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        print(#fileID, #function, "called")
        // ????????? url, ?????? ?????? ??? ??????
        guard let url = navigationResponse.response.url,
              let mimeType = navigationResponse.response.mimeType,
              let fileName = navigationResponse.response.suggestedFilename else {
            decisionHandler(.cancel)
            return
        }
        print("webView ???????????? ????????? - url:", url)
        print("webView ???????????? ????????? - mimeType:", mimeType.getReadableMimeType())
        print("webView ???????????? ????????? - fileName:", fileName)
        
        let downloadAvailableType = ["pdf", "zip"]
        
        if mimeType == "text/html" {
            decisionHandler(.allow)
        } else {
            if !checkDownloadAvailable(availableTypes: downloadAvailableType, fileTypeToDownload: mimeType) {
                self.myWebView.viewModel.JsAlertEvent.send(JsAlert(fileName, .downloadNotAvailable))
                decisionHandler(.cancel)
                return
            }
            downloadFile(webView: webView, url: url, fileName: fileName, completion: { fileUrl in
                print("???????????? ?????? fileUrl:", fileUrl)
                DispatchQueue.main.async {
                    if let fileUrl = fileUrl {
                        self.myWebView.viewModel.downloadEvent.send(fileUrl)
                    } else {
                        self.myWebView.viewModel.JsAlertEvent.send(JsAlert(fileName, .downloadFailed))
                    }
                }
            })
            decisionHandler(.cancel)
        }
    }
    
    // ??????????????? ??????
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Request URL??? ????????? return
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        switch url.scheme {
        // ????????????, ???????????? ???????????? ????????? ?????? ??????
        case "tel", "mailto":
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        default:
            // ?????? ????????? ?????? ????????? ??????
            switch url.host {
            case "www.youtube.com":
                print("????????? ????????? ?????????")
                myWebView.viewModel.JsAlertEvent.send(JsAlert(url.host, .blocked))
                decisionHandler(.cancel)
            default:
                decisionHandler(.allow)
            }
        }
    }
    
    // ??? ??? ?????? ??????
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print(#fileID, "didStartProvisionalNavigation called")
        
        // ?????? ??? ?????????
        myWebView.viewModel.shouldShowIndicator.send(true)
        
        myWebView
            .viewModel
            .webNavigationSubject
            .sink { (action: Web_Navigation) in
                print("????????? ??????????????? ??????:", action)
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
    
    // ??? ??? ?????? ??????
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
                print(#fileID, #function, "called / nativeToJsEvent ????????? / message:", message)
                webView.evaluateJavaScript("nativeToJsEventCall('\(message)');", completionHandler: { (result, error) in
                    if let result = result {
                        print("nativeToJs result ??????:", result)
                    }
                    if let error = error {
                        print("nativeToJs result ??????:", error.localizedDescription)
                    }
                })
            }.store(in: &subscriptions)
        
        myWebView
            .viewModel
            .changedUrlSubject
            .compactMap { $0.url }
            .sink { changedUrl in
                print("????????? url:", changedUrl)
                webView.load(URLRequest(url: changedUrl))
            }.store(in: &subscriptions)
        
        // ????????? ???????????? ??????
        self.myWebView.viewModel.shouldShowIndicator.send(false)
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print(#fileID, #function, "called")
        // ????????? ???????????? ??????
        self.myWebView.viewModel.shouldShowIndicator.send(false)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print(#fileID, "didFail called")
        // ????????? ???????????? ??????
        self.myWebView.viewModel.shouldShowIndicator.send(false)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print(#fileID, "didFailProvisionalNavigation called")
        // ????????? ???????????? ??????
        self.myWebView.viewModel.shouldShowIndicator.send(false)
    }
}

//MARK: - WKScriptMessageHandler ??????
extension MyWebView.Coordinator: WKScriptMessageHandler {
    // ??? ??? JS?????? iOS ??????????????? ???????????? ??????????????? ????????? ???
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("MyWebViewCoordinator - userContentController / message:", message)
        if message.name == "callbackHandler" {
            print("JSON ???????????? ??????????????? ?????????", message.body)
            if let receivedData: [String: String] = message.body as? Dictionary {
                print("receivedData:", receivedData)
                myWebView.viewModel.JsAlertEvent.send(JsAlert(receivedData["message"], .bridge))
            }
        }
    }
}
