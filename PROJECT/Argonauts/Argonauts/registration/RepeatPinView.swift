//
//  RepeatPinView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 24.06.2021.
//

import SwiftUI

struct RepeatPinView: View {
    @Binding var switcher: Views
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var pinRepeat: String = ""
    @State var text: String = "Введите пин повторно"
    @State var alertMessage: String = ""
    
    @State var isLoading: Bool = false    
    @State var isExists: Bool = false
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                Button {
                    switcher = .setPin
                } label: {
                    Text("Назад")
                }
                Text(text)
                Spacer()
                Text(pinRepeat)
                    .onChange(of: pinRepeat) { pinRepeat in
                        if pinRepeat.count == 4 {
                            if self.pinRepeat == globalObj.pin {
                                let textToWrite = globalObj.email + "\n" + globalObj.pin
                                writeToDocDir(filename: "pinInfo", text: textToWrite)
                                loadDataAsync()
                            } else {
                                text = "Попробуйте еще раз"
                            }
                        }
                    }
                Spacer()
                ForEach(buttonsNoBio, id: \.self) { row in
                    HStack {
                        ForEach(row, id: \.self) { item in
                            Button(action: {
                                switch item.rawValue {
                                case "dop":
                                    print("dop")
                                case "del":
                                    if pinRepeat != "" {
                                        pinRepeat.removeLast()
                                    }
                                default:
                                    pinRepeat.append(item.rawValue)
                                }
                            }, label: {
                                if item.rawValue == "del" {
                                    Image(systemName: "delete.left")
                                } else if item.rawValue == "dop" {
                                    Text("")
                                } else {
                                    Text(item.rawValue)
                                }
                            })
                        }
                    }
                }
                Spacer()
            }
            .alert(isPresented: $showAlert, content: {
                Alert(title: Text("Ошибка"), message: Text(alertMessage))
            })
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
            isEmailExists(email: globalObj.email)
            DispatchQueue.main.async {
                isLoading = false
                if isExists {
                    switcher = .home
                } else if isExists == false && alertMessage == "" {
                    switcher = .createAccount
                }
            }
        }
    }
    
    func isEmailExists(email: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=is_email_exists&email=" + email
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let dop = json["user"] as! [String : Any]
                    print("RepeatPinView.isEmailExists(): \(dop)")
                    if dop["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else if dop["no"] != nil {
                        alertMessage = ""
                        isExists = false
                    } else {
                        alertMessage = ""
                        isExists = true
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

//struct RepeatPinView_Previews: PreviewProvider {
//    static var previews: some View {
//        RepeatPinView()
//    }
//}
