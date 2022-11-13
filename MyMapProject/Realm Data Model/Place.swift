//
//  Place.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 6.10.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import Foundation
import RealmSwift

class Place: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var title: String = ""
    @objc dynamic var color: String = "f9e0ae"
    @objc dynamic var iconSize: Float = 0.003
    @objc dynamic var lastUpdateTime: Date = Date()
    @objc dynamic var markerPosition: Position? = Position()
    let items = List<Item>()
    let photos = List<String>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

