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

class Field: Overlay {
    let photos = List<String>()
    @objc dynamic var area: Double = 0.0
    @objc dynamic var circumference: Double = 0
    @objc dynamic var lastUpdateTime: Date = Date()
    var polygonMarkersPositions = List<Position>()
    
    var parentGroup = LinkingObjects(fromType: Group.self, property: "fields")
}

class Position: Object {
    @objc dynamic var latitude: Double = 0
    @objc dynamic var longitude: Double = 0
    
}
