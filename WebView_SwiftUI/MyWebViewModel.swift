//
//  MyWebViewModel.swift
//  WebView_SwiftUI
//
//  Created by SeongMinK on 2021/12/22.
//

import Foundation
import Combine

typealias Web_Navigation = MyWebViewModel.Navigation

class MyWebViewModel: ObservableObject {
    enum Navigation {
        case back, forward, refresh
    }
    
    enum URL_Type {
        case jeong, youtube, github, kakao
        
        var url: URL? {
            switch self {
            case .jeong:
                return URL(string: "https://tuentuenna.github.io/simple_js_alert")
            case .youtube:
                return URL(string: "https://www.youtube.com/channel/UCg_pGaOuYAHvncmq2piUWAQ")
            case .github:
                return URL(string: "https://github.com/SeongMin-K")
            case .kakao:
                return URL(string: "https://open.kakao.com/o/sqP7S3Bd")
            }
        }
    }
    
    // 웹 뷰의 url 변경 이벤트
    var changedUrlSubject = PassthroughSubject<MyWebViewModel.URL_Type, Never>()
    
    // 웹 뷰의 네비게이션 액션 이벤트
    var webNavigationSubject = PassthroughSubject<Web_Navigation, Never>()
    
    // 웹 뷰의 타이틀 이벤트
    var webSiteTitleSubject = PassthroughSubject<String, Never>()
    
    // iOS -> JS 함수 호출
    var nativeToJsEvent = PassthroughSubject<String, Never>()
    
    // JS Alert 들어오면 이벤트 보내기
    var JsAlertEvent = PassthroughSubject<JsAlert, Never>()
    
    // 로딩 여부 이벤트
    var shouldShowIndicator = PassthroughSubject<Bool, Never>()
    
    // 로딩 여부 이벤트
    var downloadEvent = PassthroughSubject<URL, Never>()
}
