//
//  Group.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 30.09.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import Foundation
import RealmSwift

class Group: Overlay {
    @objc dynamic var lastUpdateTime: Date = Date()
    let fields = List<Field>()
}


