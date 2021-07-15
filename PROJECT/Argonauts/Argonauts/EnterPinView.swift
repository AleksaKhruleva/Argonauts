//
//  EnterPinView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 30.06.2021.
//

import SwiftUI
import LocalAuthentication

struct EnterPinView: View {
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var pin: String = ""
    @State var text: String = "Введите пин"
    @State var pinInfo: [String] = []
    @State var isLoading: Bool = false
    
    @State var showNext: Bool = false
    
    var body: some View {
        if showNext {
            HomeView()
        } else {
            ZStack {
                VStack {
                    Text(text)
                    Text(pin)
                        .onChange(of: pin) { pin in
                            if pin.count == 4 {
                                if pin == pinInfo[1] {
                                    showNext = true
                                } else {
                                    text = "Попробуйте снова"
                                }
                            } else {
                                text = "Введите пин"
                            }
                        }
                    ForEach(buttonsWithBio, id: \.self) { row in
                        HStack {
                            ForEach(row, id: \.self) { item in
                                Button(action: {
                                    switch item.rawValue {
                                    case "bio":
                                        authenticate()
                                    case "del":
                                        if pin != "" {
                                            pin.removeLast()
                                        }
                                    default:
                                        pin.append(item.rawValue)
                                    }
                                }, label: {
                                    if item.rawValue == "del" {
                                        Image(systemName: "delete.left")
                                    } else if item.rawValue == "bio" {
                                        if globalObj.biometryType == "faceID" {
                                            Image(systemName: "faceid")
                                        } else if globalObj.biometryType == "touchID" {
                                            Image(systemName: "touchid")
                                        } else {
                                            Text("")
                                        }
                                    } else {
                                        Text(item.rawValue)
                                    }
                                })
                            }
                        }
                    }
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
                loadDataAsync()
                authenticate()
            }
        }
    }
    
    func loadDataAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            writeToDocDir(filename: "pinInfo", text: "Oo@ll.aa\n2222")
            readPinInfo()
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        // check whether biometric authentication is possible
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // it's possible, so go ahead and use it
            let reason = "We need to unlock your data"
            
            switch context.biometryType {
            case .faceID:
                print("EnterPinView.authenticate(): faceID")
                globalObj.biometryType = "faceID"
            case .touchID:
                print("EnterPinView.authenticate(): touchID")
                globalObj.biometryType = "touchID"
            default:
                print("EnterPinView.authenticate(): none")
                globalObj.biometryType = "none"
            }
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                // authentication has now completed
                DispatchQueue.main.async {
                    if success {
                        showNext = true
                        // authenticated successfully
                    } else {
                        // there was a problem
                        print("EnterPinView.authenticate(): unsuccessful")
                    }
                }
            }
        } else {
            // no biometrics
            print("EnterPinView.authenticate(): bio unavailable")
            globalObj.biometryType = "none"
        }
    }
    
    func readPinInfo() {
        let filename: String = "pinInfo.txt"
        do {
            let docDirUrl =  try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileUrl = docDirUrl.appendingPathComponent(filename)
            
            do {
                let contentFromFile = try NSString(contentsOf: fileUrl, encoding: String.Encoding.utf8.rawValue)
                pinInfo = contentFromFile.components(separatedBy: "\n")
                print("EnterPinView.readPinInfo(): \(pinInfo)")
                globalObj.email = pinInfo[0]
            } catch let error as NSError {
                print("EnterPinView.readPinInfo(): \(error)")
            }
            
        } catch let error as NSError {
            print("EnterPinView.readPinInfo(): \(error)")
        }
    }
}

struct EnterPinView_Previews: PreviewProvider {
    static var previews: some View {
        EnterPinView().environmentObject(GlobalObj())
    }
}
