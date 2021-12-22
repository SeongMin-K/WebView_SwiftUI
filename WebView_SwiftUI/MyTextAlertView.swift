//
//  MyTextAlertView.swift
//  WebView_SwiftUI
//
//  Created by SeongMinK on 2021/12/22.
//

import UIKit
import SwiftUI

struct MyTextAlertView: UIViewControllerRepresentable {
    @Binding var textString: String
    @Binding var showAlert: Bool
    
    var title: String
    var message: String
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<MyTextAlertView>) -> UIViewController {
        return UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<MyTextAlertView>) {
        guard context.coordinator.uiAlertController == nil else { return }
        
        if self.showAlert {
            let uiAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            uiAlertController.addTextField(configurationHandler: { textField in
                textField.placeholder = "전달할 값을 입력하세요"
                textField.text = self.textString
            })
            
            uiAlertController.addAction(UIAlertAction(title: "취소", style: .destructive, handler: { _ in
                print("취소 클릭됨")
                self.textString = ""
            }))
            
            uiAlertController.addAction(UIAlertAction(title: "보내기", style: .default, handler: { _ in
                if let textField = uiAlertController.textFields?.first,
                   let inputText = textField.text {
                    self.textString = inputText
                }
                
                uiAlertController.dismiss(animated: true, completion: {
                    print("보내기 버튼 클릭됨")
                    self.showAlert = false
                })
            }))
            
            DispatchQueue.main.async {
                uiViewController.present(uiAlertController, animated: true, completion: {
                    self.showAlert = false
                    context.coordinator.uiAlertController = nil
                })
            }
        }
    }
    
    func makeCoordinator() -> MyTextAlertView.Coordinator {
        MyTextAlertView.Coordinator(self)
    }
    
    // UIKit의 Delegate 등의 이벤트를 받아주는 역할
    class Coordinator: NSObject {
        var uiAlertController: UIAlertController? // UIKit View
        var myTextAlertView: MyTextAlertView // SwiftUI View
        
        init(_ myTextAlertView: MyTextAlertView) {
            self.myTextAlertView = myTextAlertView
        }
    }
}

extension MyTextAlertView.Coordinator: UITextFieldDelegate {
    // 글자가 입력될 때
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text as NSString? {
            self.myTextAlertView.textString = text.replacingCharacters(in: range, with: string)
        } else {
            self.myTextAlertView.textString = ""
        }
        return true
    }
}
