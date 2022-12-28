//
//  FieldPolygon.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 10.11.2022.
//  Copyright © 2022 Enes Kılıç. All rights reserved.
//

import Foundation
import GoogleMaps
import RealmSwift

class FieldPolygon: GMSPolygon {
    
    private let realm: Realm! = try? Realm()
    var field: Field?
    
    func setColor(with color: UIColor) {
        strokeColor = color
        do {
            try realm.write({
                field?.color = color.hexValue()
            })
        } catch {
            print("Error saving context, \(error)")
        }
    }
}
