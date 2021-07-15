//
//  TranspAddView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 03.07.2021.
//

import SwiftUI

struct TranspAddView: View {
    @Binding var isPresented: Bool
    
    @State var nick: String = ""
    @State var producted: String = ""
    @State var mileage: String = ""
    @State var engHour: String = ""
    @State var diagDate: Date = Date()
    @State var osagoDate: Date = Date()
    @State var osagoLife: Date = Date()
    
    @State var isOn1: Bool = false
    @State var isOn2: Bool = false
    @State var isOn3: Bool = false
    @State var isOn4: Bool = false
    @State var isOn5: Bool = false
    
    @State var showAlert: Bool = false
    @State var alertMessage: String = ""
    @State var isLoading: Bool = false
    
    @EnvironmentObject var globalObj: GlobalObj
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                Text("Обязательное поле")
                    .font(.system(size: 15))
                TextField("Ник", text: $nick)
                    .disableAutocorrection(true)
                Text("Дополнительные поля")
                    .font(.system(size: 15))
                HStack {
                    TextField("Год выпуска", text: $producted)
                        .disabled(!isOn1)
                    Toggle("", isOn: $isOn1)
                        .labelsHidden()
                        .onChange(of: isOn1, perform: { _ in
                            producted = ""
                        })
                }
                HStack {
                    TextField("Текущий пробег", text: $mileage)
                        .disabled(!isOn2)
                    Toggle("", isOn: $isOn2)
                        .labelsHidden()
                        .onChange(of: isOn2, perform: { _ in
                            mileage = ""
                        })
                }
                HStack {
                    TextField("Моточасы", text: $engHour)
                        .disabled(!isOn3)
                    Toggle("", isOn: $isOn3)
                        .labelsHidden()
                        .onChange(of: isOn3, perform: { _ in
                            engHour = ""
                        })
                }
                HStack {
                    Text("Дата получения действующей\nдиагностической карты")
                        .multilineTextAlignment(.center)
                    Spacer()
                    Toggle("", isOn: $isOn4)
                        .labelsHidden()
                }
                DatePicker("", selection: $diagDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .disabled(!isOn4)
                HStack {
                    Text("Дата оформления действующего\nполиса ОСАГО")
                        .multilineTextAlignment(.center)
                    Spacer()
                    Toggle("", isOn: $isOn5)
                        .labelsHidden()
                }
                DatePicker("", selection: $osagoDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .disabled(!isOn5)
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
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("Добавление", displayMode: .inline)
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
                    Text("Добавить")
                })
                .alert(isPresented: $showAlert, content: {
                    Alert(title: Text("Ошибка"), message: Text(alertMessage))
                })
                .disabled(nick.isEmpty)
        )
    }
    
    func loadDataAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            var diagDateFormatted = ""
            var osagoDateFormatted = ""
            
            if isOn4 {
                let formatter = DateFormatter()
                formatter.dateFormat = "YYYY-MM-dd"
                diagDateFormatted = formatter.string(from: diagDate)
            }
            
            if isOn5 {
                let formatter = DateFormatter()
                formatter.dateFormat = "YYYY-MM-dd"
                osagoDateFormatted = formatter.string(from: osagoDate)
            }
            
            addTransp(email: globalObj.email, nick: nick, producted: producted, mileage: mileage, engHour: engHour, diagDate: diagDateFormatted, osagoDate: osagoDateFormatted)
            DispatchQueue.main.async {
                if alertMessage == "" {
                    isPresented = false
                }
                isLoading = false
            }
        }
    }
    
    func addTransp(email: String, nick: String, producted: String, mileage: String, engHour: String, diagDate: String, osagoDate: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=add_transp&email=" + email + "&nick=" + nick + "&producted=" + producted + "&mileage=" + mileage + "&eng_hour=" + engHour + "&diag_date=" + diagDate + "&osago_date=" + osagoDate
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["add_transp"] as! [String : Any]
                    print("TranspAddView.addTransp(): \(info)")
                    
                    if info["bad nick"] != nil {
                        print("TranspAddView.addTransp(): bad nick")
                        alertMessage = "У вас уже есть транспортное средство с таким ником, выберите другой"
                        showAlert = true
                    } else if info["server_error"] != nil {
                        print("TranspAddView.addTransp(): server_error")
                        alertMessage = "Ошибка сервера, попробуйте ещё раз позже"
                        showAlert = true
                    } else if info["mileage"] != nil {
                        let dop = info["mileage"] as! [String : Any]
                        if dop["server_error"] != nil {
                            alertMessage = "Ошибка сервера"
                            showAlert = true
                        }
                    } else if info["eng_hour"] != nil {
                        let dop = info["eng_hour"] as! [String : Any]
                        if dop["server_error"] != nil {
                            alertMessage = "Ошибка сервера"
                            showAlert = true
                        }
                    } else {
                        alertMessage = ""
                    }
                }
            } catch let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
            }
        }
    }
}

//struct TranspAddView_Previews: PreviewProvider {
//    @State var isp = true
//    static var previews: some View {
//        TranspAddView()
//    }
//}
