//
//  AccountView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 29.06.2021.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var isLoading: Bool = false
    @State var showAlert: Bool = false
    
    @State var alertMessage: String = ""
    @State var nick: String = ""
    
    var body: some View {
        ZStack {
            VStack {
                Text(nick)
                Text(globalObj.email)
            }
            if isLoading {
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .allowsHitTesting(true)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .pink))
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage))
        }
        .onAppear {
            loadDataAsync()
        }
    }
    
    func loadDataAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            getUserInfo(email: globalObj.email)
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    func getUserInfo(email: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_user_info&email=" + email
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["user_info"] as! [String : Any]
                    print("AccountView.getUserInfo(): \(info)")
                    
                    if info["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        nick = info["nick"] as! String
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

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView().environmentObject(GlobalObj())
    }
}
