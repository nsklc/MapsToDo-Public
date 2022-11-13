//
//  Line.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 7.10.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import Foundation
import RealmSwift

class Line: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var title: String = ""
    @objc dynamic var color: String = "f9e0ae"
    @objc dynamic var length: Double = 0.0
    @objc dynamic var lastUpdateTime: Date = Date()
    var polylineMarkersPositions = List<Position>()
    let items = List<Item>()
    let photos = List<String>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

