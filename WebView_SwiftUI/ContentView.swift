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
    @State  var isLoading = false
    @State var webTitle = ""
    @State var jsAlert: JsAlert?

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    MyWebView(urlToLoad: "https://tuentuenna.github.io/simple_js_alert")
                    webViewBottomTabbar
                }
                .navigationBarTitle(Text(webTitle), displayMode: .inline)
                .navigationBarItems(
                    leading: siteMenu,
                    trailing: Button("iOS -> JS") {
                        print("iOS -> JS 버튼 클릭")
                        self.shouldShowAlert.toggle()
                    }
                )
                .alert(item: $jsAlert, content: { alert in
                    createAlert(alert)
                })
                if self.shouldShowAlert { createTextAlert() }
                if self.isLoading { LoadingScreenView() }
//                Text(textString)
//                    .font(.system(size: 26))
//                    .fontWeight(.bold)
//                    .background(Color.yellow)
//                    .offset(y: -(UIScreen.main.bounds.height * 0.32))
            }
            .onReceive(myWebVM.webSiteTitleSubject, perform: { receivedWebTitle in
                print("ContentView - webTitle:", webTitle)
                self.webTitle = receivedWebTitle
            })
            .onReceive(myWebVM.JsAlertEvent, perform: { jsAlert in
                print("ContentView - jsAlert:", jsAlert)
                self.jsAlert = jsAlert
            })
            .onReceive(myWebVM.shouldShowIndicator, perform: { isLoading in
                print("ContentView - isLoading:", isLoading)
                self.isLoading = isLoading
            })
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
                    self.myWebVM.webNavigationSubject.send(.back)
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
                    self.myWebVM.webNavigationSubject.send(.forward)
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
                    self.myWebVM.webNavigationSubject.send(.refresh)
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
    
    func createAlert(_ alert: JsAlert) -> Alert {
        Alert(title: Text(alert.type.description), message: Text(alert.message), dismissButton: .default(Text("확인"), action: {
            print("알림창 확인 버튼이 클릭됨")
        }))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
