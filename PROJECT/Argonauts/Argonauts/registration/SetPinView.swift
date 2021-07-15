//
//  SetPinView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 23.06.2021.
//

import SwiftUI
import LocalAuthentication

struct SetPinView: View {
    @Binding var switcher: Views
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var pin: String = ""
    
    var body: some View {
        VStack {
            Text("Введите пин")
            Spacer()
            Text(pin)
                .onChange(of: pin) { pin in
                    if pin.count == 4 {
                        globalObj.pin = pin
                        switcher = .repeatPin
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
                                if pin != "" {
                                    pin.removeLast()
                                }
                            default:
                                pin.append(item.rawValue)
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
    }
}

//struct SetPinView_Previews: PreviewProvider {
//    static var previews: some View {
//        SetPinView()
//    }
//}
