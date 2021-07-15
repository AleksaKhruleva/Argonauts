//
//  EnterEmailView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 04.07.2021.
//

import SwiftUI

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct EnterEmailView: View {
    @Binding var switcher: Views
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var email: String = ""
    @State var alertMessage: String = ""
    
    @State var showAlert: Bool = false
    @State var isEditing: Bool = false
    @State var isValid: Bool = false
    @State var isLoading: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                Text("Подключение")
                TextField("Email"
                          , text: $email
                          , onEditingChanged: { _ in  }
                          , onCommit: {
                          })
                    .keyboardType(.emailAddress)
                Text("1234")
                Button {
                    UIApplication.shared.endEditing()
                    isValid = isValidEmailAddress(email: email)
                    isValid = true
                    if isValid {
                        loadDataAsync()
                    } else {
                        alertMessage = "Введён некорректный email, попробуйте ещё раз"
                        showAlert = true
                    }
                } label: {
                    Text("Зарегестрироваться")
                }
                .alert(isPresented: $showAlert, content: {
                    Alert(title: Text("Ошибка"), message: Text(alertMessage))
                })
            }
            if isLoading {
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .allowsHitTesting(true)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .pink))
            }
        }
        .onAppear {
            globalObj.sentPassCode = "1234"
        }
    }
    
    func loadDataAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
//            connectDevice(email: email, code: globalObj.sentPassCode)
            DispatchQueue.main.async {
                isLoading = false
                if alertMessage == "" {
                    globalObj.email = email
                    switcher = .enterPassCode
                }
            }
        }
    }
    
    func isValidEmailAddress(email: String) -> Bool {
        var isValid: Bool = true
        do {
            let emailRegEx =  "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
            let regex = try NSRegularExpression(pattern: emailRegEx)
            let nsString = email as NSString
            let results = regex.matches(in: email, range: NSRange(location: 0, length: nsString.length))
            if results.count != 1 { isValid = false }
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            isValid = false
        }
        return isValid
    }
    
    func connectDevice(email: String, code: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=connect_device&email=" + email + "&code=" + code
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let dop = json["message"] as! [String : Any]
                    print("EnterEmailView.connectDevice(): \(dop)")
                    
                    if dop["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        alertMessage = ""
                    }
                }
            } catch let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
                alertMessage = "Ошибка"
                showAlert = true
            }
        } else {
            alertMessage = "Ошибка"
            showAlert = true
        }
    }
    
    func generatePassCode() -> String {
        let passCode = String(Int.random(in: 1000...9999))
        return passCode
    }
}

//struct EnterEmailView_Previews: PreviewProvider {
//    static var previews: some View {
//        EnterEmailView()
//    }
//}
