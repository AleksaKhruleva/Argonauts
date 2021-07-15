//
//  HubView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 14.07.2021.
//

import SwiftUI

struct HubView: View {
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var showEngHourView: Bool = false
    @State var showMileageView: Bool = false
    
    var body: some View {
        VStack {
            NavigationLink(destination: EngHourView().environmentObject(globalObj), isActive: $showEngHourView, label: { EmptyView() })
            NavigationLink(destination: MileageView().environmentObject(globalObj), isActive: $showMileageView, label: { EmptyView() })
            Button(action: {
                showEngHourView = true
            }, label: {
                Text("EngHourView")
            })
            Button(action: {
                showMileageView = true
            }, label: {
                Text("MileageView")
            })
        }
    }
}
