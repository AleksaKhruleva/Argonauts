//
//  AddCarRequiredView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 28.06.2021.
//

import SwiftUI

struct AddTranspView: View {
    @Binding var switcher: Views
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var alertMessage: String = ""
    @State var showOptional: Bool = false
    @State var showAlert: Bool = false
    @State var isLoading: Bool = false
    
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
    
    var body: some View {
        ZStack {
            ScrollView {
                Text("Транспортное средство")
                Text("Обязательное поле")
                TextField("Ник транспортного средства", text: $nick)
                Group {
                    Text("Дополнительные поля")
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
                Button {
                    loadDataAsync()
                } label: {
                    Text("Продолжить")
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
                isLoading = false
                if alertMessage == "" {
                    switcher = .home
                }
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
                    let dop = json["add_transp"] as! [String : Any]
                    print("AddTransp.addTransp(): \(dop)")
                    
                    if dop["bad nick"] != nil {
                        print("AddTransp.addTransp(): bad nick")
                        alertMessage = "У вас уже есть транспортное средство с таким ником, выберите другой"
                        showAlert = true
                    } else if dop["server_error"] != nil {
                        print("AddTransp.addTransp(): server_error")
                        alertMessage = "Ошибка сервера, попробуйте ещё раз позже"
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

//struct AddCarRequiredView_Previews: PreviewProvider {
//    static var previews: some View {
//        AddTranspRequiredView().environmentObject(GlobalObj())
//    }
//}
