//
//  Item.swift
//  Todoey
//
//  Created by Enes Kılıç on 10.08.2020.
//  Copyright © 2020 App Brewery. All rights reserved.
//

import Foundation
import RealmSwift

class Item: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var title: String = ""
    @objc dynamic var lastUpdateTime = Date()
    @objc dynamic var startDate = Date().addingTimeInterval(60*60)
    @objc dynamic var endDate = Date().addingTimeInterval(60*60)
    @objc dynamic var note: String = ""
    @objc dynamic var status: Int = 0
    @objc dynamic var parentID = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
