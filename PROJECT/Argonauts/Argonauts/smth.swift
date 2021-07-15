//
//  File.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 23.06.2021.
//

import Foundation
import SwiftUI
import LocalAuthentication

enum numPadButton: String {
    case one = "1"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case six = "6"
    case seven = "7"
    case eight = "8"
    case nine = "9"
    case zero = "0"
    
    case bio = "bio"
    case del = "del"
    case dop = "dop"
}

func writeToDocDir(filename: String, text: String) {
    let ext = "txt"
    let docDirUrl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let fileUrl = docDirUrl.appendingPathComponent(filename).appendingPathExtension(ext)
    
    do {
        try text.write(to: fileUrl, atomically: true, encoding: String.Encoding.utf8)
    } catch let error as NSError {
        print("writeToDocDir(): error \(error)")
    }
}

extension String {
   var isNumeric: Bool {
     return !(self.isEmpty) && self.allSatisfy { $0.isNumber }
   }
}

let buttonsNoBio: [[numPadButton]] = [
    [.one, .two, .three],
    [.four, .five, .six],
    [.seven, .eight, .nine],
    [.dop, .zero, .del],
]

let buttonsWithBio: [[numPadButton]] = [
    [.one, .two, .three],
    [.four, .five, .six],
    [.seven, .eight, .nine],
    [.bio, .zero, .del],
]

class GlobalObj: ObservableObject {
    var email: String = ""
    var biometryType: String = ""
    var isEmailExists: Bool = false
    var tidCurr: Int = 0
    var tids: [Int] = []
    var sentPassCode: String = ""
    var pin: String = ""
    var transports: [Transport] = []
}

class Transport: ObservableObject, Identifiable {
    var tid: Int
    var nick: String
    var producted: Int?
    var mileage: Int?
    var engHours: Int?
    var diagDate: Date?
    var osagoDate: Date?
    
    init(tid: Int, nick: String, producted: Int?, mileage: Int?, engHours: Int?, diagDate: Date?, osagoDate: Date?) {
        self.tid = tid
        self.nick = nick
        self.producted = producted
        self.mileage = mileage
        self.engHours = engHours
        self.diagDate = diagDate
        self.osagoDate = osagoDate
    }
}

class Mileage: ObservableObject, Identifiable {
    var mid: Int
    var date: String
    var mileage: Int
    
    init(mid: Int, date: String, mileage: Int) {
        self.mid = mid
        self.date = date
        self.mileage = mileage
    }
}

class EngHour: ObservableObject, Identifiable {
    var ehid: Int
    var date: String
    var engHour: Int
    
    init(ehid: Int, date: String, engHour: Int) {
        self.ehid = ehid
        self.date = date
        self.engHour = engHour
    }
}

class Fuel {
    var fid: Int
    var date: String
    var fuel: Int
    var mileage: Int?
    var fillBrand: String?
    var fuelBrand: String?
    var fuelCost: Double?
    
    init(fid: Int, date: String, fuel: Int, mileage: Int?, fillBrand: String?, fuelBrand: String?, fuelCost: Double?) {
        self.fid = fid
        self.date = date
        self.fuel = fuel
        self.mileage = mileage
        self.fillBrand = fillBrand
        self.fuelBrand = fuelBrand
        self.fuelCost = fuelCost
    }
}

class Service {
    var sid: Int
    var date: String
    var serType: String
    var mileage: Int
    var matCost: Double?
    var wrkCost: Double?
    
    init(sid: Int, date: String, serType: String, mileage: Int, matCost: Double?, wrkCost: Double?) {
        self.sid = sid
        self.date = date
        self.serType = serType
        self.mileage = mileage
        self.matCost = matCost
        self.wrkCost = wrkCost
    }
}

class Material {
    var maid: Int
    var matInfo: String
    var wrkType: String
    var matCost: Double?
    var wrkCost: Double?
    
    init(maid: Int, matInfo: String, wrkType: String, matCost: Double?, wrkCost: Double?) {
        self.maid = maid
        self.matInfo = matInfo
        self.wrkType = wrkType
        self.matCost = matCost
        self.wrkCost = wrkCost
    }
}

//    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification), perform: { _ in
//        isUnlocked = false
//    })
//    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification), perform: { _ in
//        authenticate()
//    })

func buttonWidthNumPad(item: numPadButton) -> CGFloat {
    return (UIScreen.main.bounds.width - (5 * 12)) / 4
}

func buttonHeightNumPad(item: numPadButton) -> CGFloat {
    return (UIScreen.main.bounds.width - (5 * 12)) / 4
}

func feedbackSelect() {
//    let impactLight = UIImpactFeedbackGenerator(style: .light)
//    impactLight.impactOccurred()
    let selectionFeedback = UISelectionFeedbackGenerator()
    selectionFeedback.selectionChanged()
}

func feedbackError() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.error)
}



func getBioType() {
    let context = LAContext()
    var error: NSError?

    // check whether biometric authentication is possible
    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
        switch context.biometryType {
        case .faceID:
            print("authenticate: faceID")
//            globalObj.biometryType = "faceID"
        case .touchID:
            print("authenticate: touchID")
//            globalObj.biometryType = "touchID"
        default:
            print("authenticate: none")
//            globalObj.biometryType = "none"
        }
    } else {
//        globalObj.biometryType = "none"
    }
}
