//
//  String+Ext.swift
//  WebView_SwiftUI
//
//  Created by SeongMinK on 2021/12/28.
//

import Foundation
import SwiftUI

extension String {
    // mimeType을 가져옴
    func getReadableMimeType() -> String {
        print("Stirng - getReadableMimeType()")
        if let mimeType = mimeTypes.first(where: { (key: String, value: String) in
            value == self
        }) {
            return mimeType.key
        } else {
            return "unknown"
        }
    }
}
