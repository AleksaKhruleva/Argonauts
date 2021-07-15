//
//  CreateAccount.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 25.06.2021.
//

import SwiftUI

struct CreateAccountView: View {
    @Binding var switcher: Views
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var nick: String = ""
    @State var alertMessage: String = ""
    
    @State var isLoading: Bool = false
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                Text("Введите своё имя")
                TextField("Ник"
                          , text: $nick
                          , onEditingChanged: { _ in }
                          , onCommit: {
                            
                          })
                Button {
                    loadDataAsync()
                } label: {
                    Text("Продолжить")
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Ошибка"), message: Text(alertMessage))
            }
            if isLoading {
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .allowsHitTesting(true)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .pink))
            }
        }
    }
    
    func loadDataAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            addUser(email: globalObj.email, nick: nick)
            DispatchQueue.main.async {
                isLoading = false
                if alertMessage == "" {
                    switcher = .addTransp
                }
            }
        }
    }
    
    func addUser(email: String, nick: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=add_user&email=" + email + "&nick=" + nick
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let dop = json["new_user"] as! [String : Any]
                    print("CreateAccountView.addUser(): \(dop)")
                    
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
}

//struct CreateAccount_Previews: PreviewProvider {
//    static var previews: some View {
//        CreateAccount()
//    }
//}
