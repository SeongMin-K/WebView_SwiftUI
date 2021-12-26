//
//  WebViewRefreshControlHelper.swift
//  WebView_SwiftUI
//
//  Created by SeongMinK on 2021/12/26.
//

import Foundation
import UIKit

class WebViewRefreshControlHelper {
    var refreshControl: UIRefreshControl?
    var viewModel: MyWebViewModel?
    
    // Refresh Control에 붙일 메소드
    @objc func didRefresh() {
        print(#fileID, #function, "called")
        guard let refreshControl = refreshControl,
              let viewModel = viewModel else {
            print("refreshControl, viewModel 없음")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: {
            print("Refresh Action in")
            // ViewModel에 Refresh 하라고 알려줌
            viewModel.webNavigationSubject.send(.refresh)
            // Refresh 종료
            refreshControl.endRefreshing()
        })
    }
}
