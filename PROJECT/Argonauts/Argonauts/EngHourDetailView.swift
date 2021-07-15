//
//  EngHourDetailView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 09.07.2021.
//

import SwiftUI

struct EngHourDetailView: View {
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var tid: Int
    @State var nick: String
    
    @State var ehid: Int = 0
    @State var alertMessage: String = ""
    @State var engHour: String = ""
    @State var date: Date = Date()
    
    @State var showAlert: Bool = false
    @State var isLoading: Bool = false
    @State var showFields: Bool = false
    
    @State var engHours: [EngHour] = []
    
    var body: some View {
        ZStack {
            VStack {
                if showFields {
                    DatePicker("", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                    TextField("Моточасы", text: $engHour)
                        .keyboardType(.numberPad)
                    Button {
                        addEngHourAsync()
                    } label: {
                        Text("Добавить")
                    }
                }
                List {
                    ForEach(engHours, id: \.ehid) { engHour in
                        HStack {
                            Text(engHour.date)
                            Spacer()
                            Text("\(engHour.engHour)")
                        }
                    }
                    .onDelete(perform: deleteEngHourAsync)
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
    
    func deleteEngHourAsync(at offsets: IndexSet) {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let index = offsets[offsets.startIndex]
            ehid = engHours[index].ehid
            deleteEngHour(ehid: String(ehid), tid: String(tid))
            DispatchQueue.main.async {
                isLoading = false
                if alertMessage == "" {
                    engHours.remove(at: index)
                }
            }
        }
    }
    
    func addEngHourAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            addEngHour(tid: String(tid), date: date, engHour: engHour)
            DispatchQueue.main.async {
                engHour = ""
                isLoading = false
            }
        }
    }
    
    func loadDataAsync() {
        engHours = []
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let engHours = getEngHour(tid: String(tid))
            DispatchQueue.main.async {
                self.engHours = engHours
                isLoading = false
            }
        }
    }
    
    func deleteEngHour(ehid: String, tid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=delete_eng_hour&ehid=" + ehid + "&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["delete_eng_hour"] as! [String : Any]
                    print("EngHourDetailView.deleteEngHour(): \(info)")
                    
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
    
    func getEngHour(tid: String) -> [EngHour] {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_eng_hour&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["get_eng_hour"] as! [[String : Any]]
                    print("EngHourDetailView.getEngHour(): \(info)")
                    
                    if info.isEmpty {
                        // empty
                    } else if info[0]["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        var engHours: [EngHour] = []
                        alertMessage = ""
                        for el in info {
                            var date = el["date"] as! String
                            date = date.replacingOccurrences(of: "T", with: " ")
                            date.removeLast(3)
                            
                            let engHour = EngHour(ehid: el["ehid"] as! Int, date: date, engHour: el["eng_hour"] as! Int)
                            engHours.append(engHour)
                        }
                        return engHours
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
    
    func addEngHour(tid: String, date: Date, engHour: String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString = formatter.string(from: date)
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=add_eng_hour&tid=" + tid + "&date=" + dateString + "&eng_hour=" + engHour
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["add_eng_hour"] as! [String : Any]
                    print("EngHourDetailView.addEngHour(): \(info)")
                    
                    if info["server_error"] != nil {
                        if info["err_code"] as! Int == 1062 {
                            alertMessage = "Запись с таким временем/пробегом уже есть"
                            showAlert = true
                        } else {
                            alertMessage = "Ошибка сервера"
                            showAlert = true
                        }
                    } else if info["ehid"] == nil {
                        alertMessage = "Введены некорректные данные"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        engHours.append(EngHour(ehid: info["ehid"] as! Int, date: dateString, engHour: Int(engHour)!))
                        engHours.sort { $0.date > $1.date }
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
