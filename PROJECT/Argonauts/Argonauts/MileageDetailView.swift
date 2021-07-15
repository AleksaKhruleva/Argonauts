//
//  MileageDetailView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 07.07.2021.
//

import SwiftUI

struct MileageDetailView: View {
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var tid: Int
    @State var nick: String
    
    @State var alertMessage: String = ""
    @State var mileage: String = ""
    @State var date: Date = Date()
    
    @State var showAlert: Bool = false
    @State var isLoading: Bool = false
    @State var showFields: Bool = false
    
    @State var mileages: [Mileage] = []
    
    var body: some View {
        ZStack {
            VStack {
                if showFields {
                    DatePicker("", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                    TextField("Пробег", text: $mileage)
                        .keyboardType(.numberPad)
                    Button {
                        addMileageAsync()
                    } label: {
                        Text("Добавить")
                    }
                }
                List {
                    ForEach(mileages, id: \.mid) { mileage in
                        HStack {
                            Text(mileage.date)
                            Spacer()
                            Text("\(mileage.mileage)")
                        }
                    }
                    .onDelete(perform: deleteMileageAsync)
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
    
    func deleteMileageAsync(at offsets: IndexSet) {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let index = offsets[offsets.startIndex]
            let mid = mileages[index].mid
            deleteMileage(mid: String(mid), tid: String(tid))
            DispatchQueue.main.async {
                isLoading = false
                if alertMessage == "" {
                    mileages.remove(at: index)
                }
            }
        }
    }
    
    func addMileageAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            addMileage(tid: String(tid), date: date, mileage: mileage)
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    func loadDataAsync() {
        mileages = []
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let mileages = getMileage(tid: String(tid))
            DispatchQueue.main.async {
                self.mileages = mileages
                isLoading = false
            }
        }
    }
    
    func deleteMileage(mid: String, tid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=delete_mileage&mid=" + mid + "&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["delete_mileage"] as! [String : Any]
                    print("MileageDetailView.deleteMileage(): \(info)")
                    
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
    
    func getMileage(tid: String) -> [Mileage] {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_mileage&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["get_mileage"] as! [[String : Any]]
                    print("MileageDetailView.getMileage(): \(info)")
                    
                    if info.isEmpty {
                        // empty
                    } else if info[0]["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        var mileages: [Mileage] = []
                        alertMessage = ""
                        for el in info {
                            var date = el["date"] as! String
                            date = date.replacingOccurrences(of: "T", with: " ")
                            date.removeLast(3)
                            
                            let mileage = Mileage(mid: el["mid"] as! Int, date: date, mileage: el["mileage"] as! Int)
                            mileages.append(mileage)
                        }
                        return mileages
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
    
    func addMileage(tid: String, date: Date, mileage: String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString = formatter.string(from: date)
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=add_mileage&tid=" + tid + "&date=" + dateString + "&mileage=" + mileage
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["add_mileage"] as! [String : Any]
                    print("MileageDetailView.addMileage(): \(info)")
                    
                    if info["server_error"] != nil {
                        if info["err_code"] as! Int == 1062 {
                            alertMessage = "Запись с таким временем/пробегом уже есть"
                            showAlert = true
                        } else {
                            alertMessage = "Ошибка сервера"
                            showAlert = true
                        }
                    } else if info["mid"] == nil {
                        alertMessage = "Введены некорректные данные"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        mileages.append(Mileage(mid: info["mid"] as! Int, date: dateString, mileage: Int(mileage)!))
                        mileages.sort { $0.date > $1.date }
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

//struct MileageDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        MileageDetailView()
//    }
//}
