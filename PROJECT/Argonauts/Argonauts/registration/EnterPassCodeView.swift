//
//  EnterPassCode.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 22.06.2021.
//

import SwiftUI

struct EnterPassCodeView: View {
    @Binding var switcher: Views
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var userPassCode: String = ""
    @State var text: String = "Ввeдите код"
    
    var body: some View {
        VStack {
            Button {
                switcher = .enterEmail
            } label: {
                Text("Назад")
            }
            Text(text)
            TextField("Код", text: $userPassCode)
                .keyboardType(.numberPad)
                .onChange(of: userPassCode) { _ in
                    if userPassCode.count == 4 {
                        if userPassCode == globalObj.sentPassCode {
                            switcher = .setPin
                        } else {
                            text = "Неверный код, попробуйте ещё раз"
                        }
                    } else {
                        text = "Введите код"
                    }
                }
        }
    }
}

//struct EnterPassCode_Previews: PreviewProvider {
//    static var previews: some View {
//        EnterPassCode(sentPassCode: "1234")
//    }
//}
