//
//  ContentView.swift
//  WebView_SwiftUI
//
//  Created by SeongMinK on 2021/11/21.
//

import SwiftUI

struct ContentView: View {
    var urlYoutube = "https://www.youtube.com/channel/UCg_pGaOuYAHvncmq2piUWAQ"
    var urlGitHub = "https://github.com/SeongMin-K"
    var urlKakao = "https://open.kakao.com/o/sqP7S3Bd"

    var body: some View {
        NavigationView {
            HStack {
                NavigationLink(
                    destination: MyWebView(urlToLoad: urlYoutube)
                        .edgesIgnoringSafeArea(.all)
                ) {
                    Text("Youtube")
                        .font(.system(size: 20))
                        .bold()
                        .padding(15)
                        .foregroundColor(Color.white)
                        .background(Color.red)
                        .cornerRadius(15)
                }
                NavigationLink(
                    destination: MyWebView(urlToLoad: urlGitHub)
                        .edgesIgnoringSafeArea(.all)
                ) {
                    Text("GitHub")
                        .font(.system(size: 20))
                        .bold()
                        .padding(15)
                        .foregroundColor(Color.white)
                        .background(Color.black)
                        .cornerRadius(15)
                }
                NavigationLink(
                    destination: MyWebView(urlToLoad: urlKakao)
                        .edgesIgnoringSafeArea(.all)
                ) {
                    Text("KaKao")
                        .font(.system(size: 20))
                        .bold()
                        .padding(15)
                        .foregroundColor(Color.white)
                        .background(Color.yellow)
                        .cornerRadius(15)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
