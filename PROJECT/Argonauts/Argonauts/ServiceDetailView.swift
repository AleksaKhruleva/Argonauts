//
//  ServiceDetailView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 14.07.2021.
//

import SwiftUI

struct ServiceDetailView: View {
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var tid: Int
    @State var nick: String
    
    @State var alertMessage: String = ""
    
    @State var date: Date = Date()
    @State var serType: String = "Ремонт"
    @State var mileage: String = ""
    @State var matCost: String = ""
    @State var wrkCost: String = ""
    
    @State var showAlert: Bool = false
    @State var isLoading: Bool = false
    @State var showFields: Bool = false
    
    @State var services: [Service] = []
    
    @State var wrkTypes: [String] = ["Замена", "Ремонт", "Окраска", "Снятие/установка", "Регулировка"]
    
    var body: some View {
        ZStack {
            VStack {
                if showFields {
                    DatePicker("", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                    Picker("", selection: $serType) {
                        Text("Ремонт").tag("Ремонт")
                        Text("Тех. обслуживание").tag("Тех. обслуживание")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                    TextField("Пробег", text: $mileage)
                        .keyboardType(.numberPad)
                    TextField("Стоимость материалов", text: $matCost)
                        .keyboardType(.decimalPad)
                    TextField("Стоимость работ", text: $wrkCost)
                        .keyboardType(.decimalPad)
                    Button {
                        addService(tid: String(tid), date: date, serType: serType, mileage: mileage)
                    } label: {
                        Text("Добавить")
                    }
                }
                List {
                    ForEach(services, id: \.sid) { service in
                        Text(service.date)
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
        .navigationBarTitle(nick, displayMode: .inline)
        .navigationBarItems(trailing:
                                Button(action: {
                                    showFields.toggle()
                                }, label: {
                                    if showFields {
                                        Image(systemName: "minus")
                                    } else {
                                        Image(systemName: "plus")
                                    }
                                }))
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage))
        }
        .onAppear {
            loadDataAsync()
        }
    }
    
    func convert(obj: Any?) -> String {
        guard let obj = obj else {
            return ""
        }
        return String(describing: obj)
    }
    
    func loadDataAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let services = getService(tid: String(tid))
            DispatchQueue.main.async {
                self.services = services
                isLoading = false
            }
        }
    }
    
    func addMileageAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            addService(tid: String(tid), date: date, serType: serType, mileage: mileage)
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    func getService(tid: String) -> [Service] {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_service&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["get_service"] as! [[String : Any]]
                    print("ServiceDetailView.getService(): \(info)")
                    if info.isEmpty {
                        // empty
                    } else if info[0]["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        var services: [Service] = []
                        alertMessage = ""
                        for el in info {
                            var date = el["date"] as! String
                            date = date.replacingOccurrences(of: "T", with: " ")
                            date.removeLast(3)
                            
                            let service = Service(sid: el["sid"] as! Int, date: date, serType: el["ser_type"] as! String, mileage: el["mileage"] as! Int, matCost: el["mat_cost"] as? Float, wrkCost: el["wrk_cost"] as? Float)
                            services.append(service)
                        }
                        return services
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
        return []
    }
    
    func addService(tid: String, date: Date, serType: String, mileage: String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString = formatter.string(from: date)
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=add_service&tid=" + tid + "&date=" + dateString + "&ser_type=" + serType + "&mileage=" + mileage
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["add_service"] as! [String : Any]
                    print("ServiceDetailView.addService(): \(info)")
                    
                    if info["server_error"] != nil {
                        if info["err_code"] as! Int == 1062 {
                            alertMessage = "Запись с таким временем/пробегом уже есть"
                            showAlert = true
                        } else {
                            alertMessage = "Ошибка сервера"
                            showAlert = true
                        }
                    } else if info["sid"] == nil {
                        alertMessage = "Введены некорректные данные"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        services.append(Service(sid: info["sid"] as! Int, date: info["date"] as! String, serType: info["ser_type"] as! String, mileage: info["mileage"] as! Int, matCost: info["mat_cost"] as? Float, wrkCost: info["wrk_cost"] as? Float))
                        services.sort { $0.date > $1.date }
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
