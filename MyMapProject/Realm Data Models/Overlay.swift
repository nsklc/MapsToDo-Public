//
//  Overlay.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 12.11.2022.
//  Copyright © 2022 Enes Kılıç. All rights reserved.
//

import Foundation

import RealmSwift
import GoogleMaps

class Overlay: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var title: String = ""
    @objc dynamic var color: String = "f9e0ae"
    let items = List<Item>()
    
    override static func primaryKey() -> String? {
        "id"
    }
}
