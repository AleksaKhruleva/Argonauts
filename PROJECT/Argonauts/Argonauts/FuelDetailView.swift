//
//  RefuelDetailView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 13.07.2021.
//

import SwiftUI

struct FuelDetailView: View {
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var tid: Int
    @State var nick: String
    
    @State var alertMessage: String = ""
    
    @State var date: Date = Date()
    @State var mileage: String = ""
    @State var fuel: String = ""
    @State var fillBrand: String = ""
    @State var fuelBrand: String = ""
    @State var fuelCost: String = ""
    
    @State var showAlert: Bool = false
    @State var isLoading: Bool = false
    @State var showFields: Bool = false
    
    @State var fuels: [Fuel] = []
    
    var body: some View {
        ZStack {
            VStack {
                if showFields {
                    DatePicker("", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                    TextField("Пробег", text: $mileage)
                        .keyboardType(.numberPad)
                    TextField("Топливо", text: $fuel)
                        .keyboardType(.numberPad)
                    Text("Дополнительные поля")
                    TextField("Бренд заправки", text: $fillBrand)
                    TextField("Марка топлива", text: $fuelBrand)
                    TextField("Стоимость 1 литра", text: $fuelCost)
                        .keyboardType(.decimalPad)
                    Button {
                        addFuelAsync()
                    } label: {
                        Text("Добавить")
                    }
                }
                List {
                    ForEach(fuels, id: \.fid) { fuel in
                        HStack {
                            Text(fuel.date)
                            Spacer()
                            Text(convert(mileage: fuel.mileage))
                            Spacer()
                            Text("\(fuel.fuel)")
                        }
                    }
                    .onDelete(perform: deleteFuelAsync)
                }
                .navigationBarTitle(nick, displayMode: .inline)
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
    
    func convert(mileage: Int?) -> String {
        guard let mileage = mileage else {
            return ""
        }
        return String(mileage)
    }
    
    func addFuelAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            addFuel(tid: String(tid), date: date, mileage: mileage, fuel: fuel, fillBrand: fillBrand, fuelBrand: fuelBrand, fuelCost: fuelCost)
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    func loadDataAsync() {
        fuels = []
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let fuels = getFuel(tid: String(tid))
            DispatchQueue.main.async {
                self.fuels = fuels
                isLoading = false
            }
        }
    }
    
    func deleteFuelAsync(at offsets: IndexSet) {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let index = offsets[offsets.startIndex]
            let fid = fuels[index].fid
            deleteFuel(fid: String(fid), tid: String(tid))
            DispatchQueue.main.async {
                isLoading = false
                if alertMessage == "" {
                    fuels.remove(at: index)
                }
            }
        }
    }
    
    func deleteFuel(fid: String, tid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=delete_fuel&fid=" + fid + "&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["delete_fuel"] as! [String : Any]
                    print("FuelDetailView.deleteFuel(): \(info)")
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
    
    func addFuel(tid: String, date: Date, mileage: String, fuel: String, fillBrand: String, fuelBrand: String, fuelCost: String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString = formatter.string(from: date)
        
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=add_fuel&tid=" + tid + "&date=" + dateString + "&mileage=" + mileage + "&fuel=" + fuel + "&fill_brand=" + fillBrand + "&fuel_brand=" + fuelBrand + "&fuel_cost=" + fuelCost
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["add_fuel"] as! [String : Any]
                    print("FuelDetailView.addFuel(): \(info)")

                    if info["server_error"] != nil {
                        if info["err_code"] as! Int == 1062 {
                            alertMessage = "Запись с таким временем/пробегом уже есть"
                            showAlert = true
                        } else {
                            alertMessage = "Ошибка сервера"
                            showAlert = true
                        }
                    } else if info["fid"] == nil {
                        alertMessage = "Введены некорректные данные"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        fuels.append(Fuel(fid: info["fid"] as! Int, date: info["date"] as! String, fuel: info["fuel"] as! Int, mileage: info["mileage"] as? Int, fillBrand: info["fill_brand"] as? String, fuelBrand: info["fuel_brand"] as? String, fuelCost: info["fuel_cost"] as? Double))
                        fuels.sort { $0.date > $1.date }
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
    
    func getFuel(tid: String) -> [Fuel]{
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_fuel&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["get_fuel"] as! [[String : Any]]
                    print("FuelDetailView.getFuel(): \(info)")
                    if info.isEmpty {
                        // empty
                    } else if info[0]["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        var fuels: [Fuel] = []
                        for el in info {
                            var date = el["date"] as! String
                            date = date.replacingOccurrences(of: "T", with: " ")
                            date.removeLast(3)
                            let fuel = Fuel(fid: el["fid"] as! Int, date: date, fuel: el["fuel"] as! Int, mileage: el["mileage"] as? Int, fillBrand: el["fill_brand"] as? String, fuelBrand: el["fuel_brand"] as? String, fuelCost: el["fuel_cost"] as? Double)
                            fuels.append(fuel)
                        }
                        return fuels
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
}
