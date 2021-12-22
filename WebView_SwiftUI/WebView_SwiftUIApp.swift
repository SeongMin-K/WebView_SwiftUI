//
//  WebView_SwiftUIApp.swift
//  WebView_SwiftUI
//
//  Created by SeongMinK on 2021/11/21.
//

import SwiftUI

@main
struct WebView_SwiftUIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(MyWebViewModel())
        }
    }
}
