//
//  Group.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 30.09.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import Foundation
import RealmSwift

class Group: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var title: String = ""
    @objc dynamic var color: String = "f9e0ae"
    @objc dynamic var lastUpdateTime: Date = Date()
    let fields = List<Field>()
    let items = List<Item>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}


