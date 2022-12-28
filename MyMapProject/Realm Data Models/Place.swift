//
//  Place.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 6.10.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import Foundation
import RealmSwift

class Place: Overlay {
    let photos = List<String>()
    @objc dynamic var iconSize: Float = 0.003
    @objc dynamic var lastUpdateTime: Date = Date()
    @objc dynamic var markerPosition: Position? = Position()
}
