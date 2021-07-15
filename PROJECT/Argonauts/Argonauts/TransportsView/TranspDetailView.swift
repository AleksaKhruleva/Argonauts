//
//  TranspDetailView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 30.06.2021.
//

import SwiftUI

struct TranspDetailView: View {
    @State var tid: Int
    @State var nick: String
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var alertMessage: String = ""
    @State var transpInfo: [String : Any] = [:]
    @State var keys: [String] = ["Ник", "Год выпуска", "Пробег", "Моточасы", "Дата диаг. карты", "Дата ОСАГО"]
    @State var values: [String] = ["", "", "", "", "", ""]
    
    @State var isLoading: Bool = true
    @State var showTranspEditDetail: Bool = false
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            ScrollView {
                ForEach(Array(zip(keys, values)), id: \.0) { item in
                    HStack {
                        Text("\(item.0)")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(item.1)
                    }
                }
            }
            .listStyle(PlainListStyle())
            if isLoading {
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .allowsHitTesting(true)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .pink))
            }
        }
        .navigationBarTitle(values[0], displayMode: .inline)
        .navigationBarItems(
            trailing:
                Button(action: {
                    showTranspEditDetail = true
                }, label: {
                    Text("Изменить")
                })
                .disabled(!(alertMessage == ""))
        )
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage))
        }
        .sheet(isPresented: $showTranspEditDetail) {
            NavigationView {
                TranspDetailEditView(isPresented: $showTranspEditDetail, tid: String(tid), nick: values[0], producted: values[1], diagDate: convertStringToDate(string: values[4]), osagoDate: convertStringToDate(string: values[5]), diagDateStr: values[4], osagoDateStr: values[5], diagDateChanged: values[4] != "", osagoDateChanged: values[5] != "", values: $values)
            }
        }
        .onAppear {
            loadDataAsync()
        }
    }
    
    func convertStringToDate(string: String) -> Date {
        let formmater = DateFormatter()
        formmater.dateFormat = "yyyy-MM-dd"
        let date = formmater.date(from: string)
        return date ?? Date()
    }
    
    func loadDataAsync() {
        values = ["", "", "", "", "", ""]
        DispatchQueue.global(qos: .userInitiated).async {
            getTransportInfo(tid: String(tid))
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    func getTransportInfo(tid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_transport_info&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let dop = json["transport_info"] as! [[String : Any]]
                    let info = dop[0]
                    print("TranspDetailView.getTransportInfo(): \(info)")
                    
                    if info["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        values[0] = info["nick"] as! String
                        if info["producted"] is NSNull == false {
                            let producted = info["producted"] as! Int
                            values[1] = String(producted)
                        }
                        if info["mileage"] is NSNull == false {
                            let mileage = info["mileage"] as! Int
                            values[2] = String(mileage)
                        }
                        if info["eng_hour"] is NSNull == false {
                            let engHour = info["eng_hour"] as! Int
                            values[3] = String(engHour)
                        }
                        if info["diag_date"] is NSNull == false {
                            let diagDate = info["diag_date"] as! String
                            values[4] = diagDate
                        }
                        if info["osago_date"] is NSNull == false {
                            let osagoDate = info["osago_date"] as! String
                            values[5] = osagoDate
                        }
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

//struct TranspDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        TranspDetailView()
//    }
//}
