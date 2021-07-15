//
//  RowMaterial.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 15.07.2021.
//

import SwiftUI

struct RowMaterial: View {
    @State var matInfo: String
    @State var wrkType: String
    @State var matCost: Double?
    @State var wrkCost: Double?
    //    @State var matInfo: String = "Wrench"
    //    @State var wrkType: String = "Change"
    //    @State var matCost: Double? = 123.123
    //    @State var wrkCost: Double? = 123123.123
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(matInfo)
            Text(wrkType)
            if convert(obj: matCost) != "" {
                Text("Стоимость детали: \(convert(obj: matCost))")
            }
            if convert(obj: wrkCost) != "" {                
                Text("Стоимость работы: \(convert(obj: wrkCost))")
            }
        }
    }
    
    func convert(obj: Double?) -> String{
        guard let obj = obj else {
            return ""
        }
        
        if floor(obj) == obj {
            return String(Int(obj))
        }
        
        return String(describing: obj)
    }
}

//struct RowMaterial_Previews: PreviewProvider {
//    static var previews: some View {
//        RowMaterial()
//    }
//}
