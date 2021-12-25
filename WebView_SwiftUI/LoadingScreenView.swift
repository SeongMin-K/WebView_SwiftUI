//
//  LoadingScreenView.swift
//  WebView_SwiftUI
//
//  Created by SeongMinK on 2021/12/25.
//

import SwiftUI

struct LoadingScreenView: View {
    var body: some View {
        ZStack() {
            Color.black
                .opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            LoadingIndicatorView()
        }
    }
}

struct LoadingScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingScreenView()
    }
}
