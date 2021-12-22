//
//  ContentView.swift
//  WebView_SwiftUI
//
//  Created by SeongMinK on 2021/11/21.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var myWebVM: MyWebViewModel
    @State var textString = ""
    @State var shouldShowAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    MyWebView(urlToLoad: "https://tuentuenna.github.io/simple_js_alert")
                    webViewBottomTabbar
                }
                .navigationBarTitle(Text("WebView"), displayMode: .inline)
                .navigationBarItems(
                    leading: siteMenu,
                    trailing: Button("iOS -> JS") {
                        print("iOS -> JS 버튼 클릭")
                        self.shouldShowAlert.toggle()
                    }
                )
                if self.shouldShowAlert { createTextAlert() }
                Text(textString)
                    .font(.system(size: 26))
                    .fontWeight(.bold)
                    .background(Color.yellow)
                    .offset(y: -(UIScreen.main.bounds.height * 0.32))
            }
        }
    }
    
    var siteMenu: some View {
        Text("사이트 이동")
            .foregroundColor(Color.blue)
            .contextMenu(ContextMenu(menuItems: {
                Button(action: {
                    print("정대리 웹뷰 이동")
                    self.myWebVM.changedUrlSubject.send(.jeong)
                }, label: {
                    Text("정대리 웹뷰 이동")
                    Image("Jeong")
                })
                Button(action: {
                    print("Youtube 이동")
                    self.myWebVM.changedUrlSubject.send(.youtube)
                }, label: {
                    Text("Youtube 이동")
                    Image("Shark")
                })
                Button(action: {
                    print("GitHub 이동")
                    self.myWebVM.changedUrlSubject.send(.github)
                }, label: {
                    Text("GitHub 이동")
                    Image("GitHub")
                })
                Button(action: {
                    print("Kakao 이동")
                    self.myWebVM.changedUrlSubject.send(.kakao)
                }, label: {
                    Text("Kakao 이동")
                    Image("Kakao")
                })
            }))
    }
    
    var webViewBottomTabbar: some View {
        VStack {
            Divider()
            HStack {
                Spacer()
                Button(action: {
                    print("뒤로 가기")
                }, label: {
                    Image(systemName: "arrow.backward")
                        .font(.system(size: 23))
                })
                Group {
                    Spacer()
                    Divider()
                    Spacer()
                }
                Button(action: {
                    print("앞으로 가기")
                }, label: {
                    Image(systemName: "arrow.forward")
                        .font(.system(size: 23))
                })
                Group {
                    Spacer()
                    Divider()
                    Spacer()
                }
                Button(action: {
                    print("새로고침")
                }, label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 23))
                })
                Spacer()
            }.frame(height: 45)
            Divider()
        }
    }
}

extension ContentView {
    func createTextAlert() -> MyTextAlertView {
        MyTextAlertView(textString: $textString, showAlert: $shouldShowAlert, title: "iOS -> JS 보내기", message: "")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
