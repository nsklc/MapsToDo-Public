//
//  Category.swift
//  Todoey
//
//  Created by Enes Kılıç on 10.08.2020.
//  Copyright © 2020 App Brewery. All rights reserved.
//

import Foundation
import RealmSwift
import GoogleMaps

class Field: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var title: String = ""
    @objc dynamic var color: String = "f9e0ae" 
    @objc dynamic var area: Double = 0.0
    @objc dynamic var circumference: Double = 0
    @objc dynamic var lastUpdateTime: Date = Date()
    var polygonMarkersPositions = List<Position>()
    let items = List<Item>()
    var parentGroup = LinkingObjects(fromType: Group.self, property: "fields")
    let photos = List<String>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class Position: Object {
    @objc dynamic var latitude: Double = 0
    @objc dynamic var longitude: Double = 0
    
}

