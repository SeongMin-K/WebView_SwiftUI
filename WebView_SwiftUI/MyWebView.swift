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

//MARK: - 다운로드 관련
extension MyWebView.Coordinator {
    /// 다운로드 허용 여부
    /// - Parameters:
    ///   - availableTypes: 허용하는 파일 타입
    ///   - fileTypeToDownload: 다운로드하려는 파일 타입
    /// - Returns: 다운로드 가능 여부
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
    
    // 다운로드 받은 파일의 임시 저장 위치 반환
    fileprivate func moveDownloadFile(url: URL, fileName: String) -> URL {
        let tempDir = NSTemporaryDirectory()
        let destinationPath = tempDir + fileName
        let destinationFileURL = URL(fileURLWithPath: destinationPath)
        try? FileManager.default.removeItem(at: destinationFileURL)
        try? FileManager.default.moveItem(at: url, to: destinationFileURL)
        return destinationFileURL
    }
    
    // 파일 다운로드
    fileprivate func downloadFile(webView: WKWebView, url: URL, fileName: String, completion: @escaping (URL?) -> Void) {
        print(#fileID, #function, "called")
        
        // webView 쿠키 가져오기
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies({ fetchedCookies in
            let session = URLSession.shared
            session.configuration.httpCookieStorage?.setCookies(fetchedCookies, for: url, mainDocumentURL: nil)
            let downloadTask = session.downloadTask(with: url) { localUrl, urlResponse, error in
                print("다운로드 완료")
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

//MARK: - UIDelegate 관련
extension MyWebView.Coordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        print("webView runJavaScriptAlertPanelWithMessage")
        self.myWebView.viewModel.JsAlertEvent.send(JsAlert(message, .alert))
        completionHandler()
    }
}

//MARK: - WKNavigationDelegate 관련 (링크 이동)
extension MyWebView.Coordinator: WKNavigationDelegate {
    // 네비게이션 응답
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        print(#fileID, #function, "called")
        // 클릭된 url, 파일 형태 및 이름
        guard let url = navigationResponse.response.url,
              let mimeType = navigationResponse.response.mimeType,
              let fileName = navigationResponse.response.suggestedFilename else {
            decisionHandler(.cancel)
            return
        }
        print("webView 다운로드 테스트 - url:", url)
        print("webView 다운로드 테스트 - mimeType:", mimeType.getReadableMimeType())
        print("webView 다운로드 테스트 - fileName:", fileName)
        
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
                print("다운로드 받은 fileUrl:", fileUrl)
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
    
    // 네비게이션 액션
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Request URL이 없으면 return
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        switch url.scheme {
        // 전화번호, 이메일이 들어오면 외부로 링크 열기
        case "tel", "mailto":
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        default:
            // 특정 도메인 이동 못하게 하기
            switch url.host {
            case "www.youtube.com":
                print("유튜브 이동이 금지됨")
                myWebView.viewModel.JsAlertEvent.send(JsAlert(url.host, .blocked))
                decisionHandler(.cancel)
            default:
                decisionHandler(.allow)
            }
        }
    }
    
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

//MARK: - WKScriptMessageHandler 관련
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
