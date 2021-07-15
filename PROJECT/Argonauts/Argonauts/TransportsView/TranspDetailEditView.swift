//
//  TranspInfoEditView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 01.07.2021.
//

import SwiftUI

struct TranspDetailEditView: View {
    @Binding var isPresented: Bool
    @State var tid: String
    @State var nick: String
    @State var producted: String
    @State var diagDate: Date
    @State var osagoDate: Date
    @State var diagDateStr: String
    @State var osagoDateStr: String
    @State var keys: [String] = ["Ник", "Год выпуска", "Пробег", "Моточасы", "Дата диаг. карты", "Дата ОСАГО"]
    @State var diagDateChanged: Bool
    @State var osagoDateChanged: Bool
    @Binding var values: [String]
    
    @State var alertMessage: String = ""
    
    @State var showAlert: Bool = false
    @State var isLoading: Bool = false
    
    var body: some View {
        ZStack {
            ScrollView {
                HStack {
                    Text(keys[0])
                    TextField(keys[0], text: $nick)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text(keys[1])
                    TextField(keys[1], text: $producted)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Дата получения действующей\nдиагностической карты")
                        .multilineTextAlignment(.center)
                    Spacer()
                    Toggle("", isOn: $diagDateChanged)
                        .labelsHidden()
                }
                DatePicker("", selection: $diagDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .disabled(!diagDateChanged)
                HStack {
                    Text("Дата оформления действующего\nполиса ОСАГО")
                        .multilineTextAlignment(.center)
                    Spacer()
                    Toggle("", isOn: $osagoDateChanged)
                        .labelsHidden()
                }
                DatePicker("", selection: $osagoDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .disabled(!osagoDateChanged)
                    .labelsHidden()
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
        .navigationBarTitle("Изменить", displayMode: .inline)
        .navigationBarItems(
            leading:
                Button(action: {
                    isPresented = false
                }, label: {
                    Text("Отменить")
                }),
            trailing:
                Button(action: {
                    loadDataAsync()
                }, label: {
                    Text("Сохранить")
                })
                .disabled(nick.isEmpty)
        )
    }
    
    func loadDataAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            if diagDateChanged {
                diagDateStr = convertDateToString(date: diagDate)
            }
            if osagoDateChanged {
                osagoDateStr = convertDateToString(date: osagoDate)
            }
            updateTranspInfo(tid: tid, nick: nick, producted: producted, diagDate: diagDateStr, osagoDate: osagoDateStr)
            DispatchQueue.main.async {
                isLoading = false
                if alertMessage == "" {
                    values[0] = nick
                    values[1] = producted
                    values[4] = diagDateStr
                    values[5] = osagoDateStr
                    isPresented = false
                }
            }
        }
    }
    
    func convertDateToString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let str = formatter.string(from: date)
        return str
    }
    
    func updateTranspInfo(tid: String, nick: String, producted: String, diagDate: String, osagoDate: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=update_transp_info&tid=" + tid + "&nick=" + nick + "&producted=" + producted + "&diag_date=" + diagDate + "&osago_date=" + osagoDate
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["update_transp_info"] as! [String : Any]
                    print("TranspDetailEdit.updateTranspInfo(): \(info)")
                    
                    if info["server_error"] != nil {
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

//struct TranspInfoEditView_Previews: PreviewProvider {
//    @Binding var d = true
//    static var previews: some View {
//        let date = Date()
//        TranspInfoEditView(isPresented: d, nick: "z", producted: "2005", mileage: "156", engHours: "456", diagDate: date, osagoDate: date)
//    }
//}
