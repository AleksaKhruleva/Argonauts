//
//  ContentView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 31.05.2021.
//

import SwiftUI
import LocalAuthentication

struct ContentView: View {
    
    @State var isUnlocked: Bool = false
    @EnvironmentObject var globalObj: GlobalObj
    
    var body: some View {
        VStack {
            Group {
                Spacer()
                Text(isUnlocked ? "Unlocked" : "Locked")
                Spacer()
                Text("email: \(globalObj.email)")
                Text("bioType: \(globalObj.biometryType)")
                Text("isEmailExists: " + (globalObj.isEmailExists ? "true" : "false"))
                Spacer()
            }
            Button {
                authenticate()
            } label: {
                Image(systemName: "faceid")
                    .font(.largeTitle)
                    .foregroundColor(.black)
            }
            Spacer()
            Text("wsd")
            Spacer()
        }
        .onAppear {
            authenticate()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification), perform: { _ in
            isUnlocked = false
        })
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification), perform: { _ in
            authenticate()
        })
//        .navigationBarTitle("aa")
//        .navigationBarBackButtonHidden(true)
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
                print("authenticate: faceID")
                globalObj.biometryType = "faceID"
            case .touchID:
                print("authenticate: touchID")
                globalObj.biometryType = "touchID"
            default:
                print("authenticate: none")
                globalObj.biometryType = "none"
            }

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                // authentication has now completed
                DispatchQueue.main.async {
                    if success {
                        isUnlocked = true
    //                        self.isUnlocked = true
                        // authenticated successfully
                    } else {
                        // there was a problem
                    }
                }
            }
        } else {
            print("no bio")
            // no biometrics
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
