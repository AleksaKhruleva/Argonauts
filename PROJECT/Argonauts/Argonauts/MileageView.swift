//
//  MileageAdd.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 07.07.2021.
//

import SwiftUI

struct MileageView: View {
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var tid: Int = 0
    @State var nick: String = ""
    @State var alertMessage: String = ""
    
    @State var showMileageDetail: Bool = false
    @State var isLoading: Bool = false
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                NavigationLink(destination: MileageDetailView(tid: tid, nick: nick).environmentObject(globalObj), isActive: $showMileageDetail, label: { EmptyView() })
                List(globalObj.transports) { transport in
                    HStack {
                        Text(transport.nick)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        tid = transport.tid
                        nick = transport.nick
                        showMileageDetail = true
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
        .navigationBarTitle("Пробег", displayMode: .inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage))
        }
        .onAppear {
            loadDataAsync()
        }
    }
    
    func loadDataAsync() {
        isLoading = true
        globalObj.transports = []
        DispatchQueue.global(qos: .userInitiated).async {
            let transports = getTidTnick(email: globalObj.email)
            DispatchQueue.main.async {
                globalObj.transports = transports
                isLoading = false
            }
        }
    }
    
    func getTidTnick(email: String) -> [Transport] {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_tid_tnick&email=" + email
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["tid_nick"] as! [[String : Any]]
                    print("TransportsView.getTidTnick(): \(info)")
                    var transports: [Transport] = []
                    
                    if info.isEmpty {
                        // empty
                    } else if info[0]["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        for el in info {
                            let transport = Transport(tid: el["tid"] as! Int, nick: el["nick"] as! String, producted: nil, mileage: nil, engHours: nil, diagDate: nil, osagoDate: nil)
                            transports.append(transport)
                        }
                        return transports
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
