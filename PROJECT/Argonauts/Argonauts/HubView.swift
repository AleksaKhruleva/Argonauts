//
//  HubView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 14.07.2021.
//

import SwiftUI

struct HubView: View {
    @EnvironmentObject var globalObj: GlobalObj
    @State var show: String? = nil
//    @State var selection: Int
    
    @State var s: Bool = false
    
    var body: some View {
        VStack {
            NavigationLink(destination: EngHourView().environmentObject(globalObj).navigationBarTitle("Моточасы", displayMode: .inline), isActive: $s, label: { EmptyView() })
            Button {
                s = true
            } label: {
                Text("Мотачасы")
            }
            
            
            //        if show == nil {
            //            VStack {
            //                Button {
            //                    show = "EngHourView"
            //                } label: {
            //                    Label("Моточасы", systemImage: "bolt")
            //                }
            //                Button {
            //                    show = "EngHourView"
            //                } label: {
            //                    Label("Пробег", systemImage: "timer")
            //                }
            //            }
            //        } else if show == "EngHourView" {
            //            EngHourView()
            //                .onAppear {
            //                    selection = 1
            //                }
            //        } else if show == "MileageView" {
            //            MileageView()
            //                .onAppear {
            //                    selection = 1
            //                }
            //        }
        }
    }
}
