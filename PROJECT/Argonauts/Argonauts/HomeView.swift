//
//  HomeView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 25.06.2021.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var globalObj: GlobalObj
    
    var body: some View {
        NavigationView {
            TabView {
                TransportsView()
                    .tabItem {
                        Label("Транспорт", systemImage: "car")
                    }
                    .environmentObject(globalObj)
                    .navigationBarHidden(true)
                
                //                HubView()
                //                    .tabItem {
                //                        Label("Центр", systemImage: "square.dashed")
                //                    }
                //                    .environmentObject(globalObj)
                //                    .navigationBarHidden(true)
                
                ServiceView()
                    .tabItem {
                        Label("Сервис", systemImage: "wrench.and.screwdriver")
                    }
                    .environmentObject(globalObj)
                    .navigationBarHidden(true)
                
                FuelView()
                    .tabItem {
                        Label("Заправка", systemImage: "drop")
                    }
                    .environmentObject(globalObj)
                    .navigationBarHidden(true)
                
                EngHourView()
                    .tabItem {
                        Label("Моточасы", systemImage: "bolt")
                    }
                    .environmentObject(globalObj)
                    .navigationBarHidden(true)
                
                MileageView()
                    .tabItem {
                        Label("Пробег", systemImage: "timer")
                    }
                    .environmentObject(globalObj)
                    .navigationBarHidden(true)
                
                AccountView()
                    .tabItem {
                        Label("Аккаунт", systemImage: "person")
                    }
                    .environmentObject(globalObj)
                    .navigationBarHidden(true)
            }
        }
//        .navigationViewStyle(StackNavigationViewStyle())
    }
}
