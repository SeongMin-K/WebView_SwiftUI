//
//  JsAlert.swift
//  WebView_SwiftUI
//
//  Created by SeongMinK on 2021/12/25.
//

import Foundation

struct JsAlert: Identifiable {
    enum JS_Type: CustomStringConvertible {
        case alert, bridge, blocked, downloadFailed, downloadNotAvailable
        var description: String {
            switch self {
            case .alert:
                return "Alert 타입"
            case .bridge:
                return "Bridge 타입"
            case .blocked:
                return "차단된 사이트"
            case .downloadFailed:
                return "파일 다운로드 실패"
            case .downloadNotAvailable:
                return "파일 다운로드 불가"
            }
        }
    }
    
    let id: UUID = UUID()
    var message: String = ""
    var type: JS_Type
    
    init(_ message: String? = nil, _ type: JS_Type) {
        self.message = message ?? "메세지 없음"
        self.type = type
    }
}
