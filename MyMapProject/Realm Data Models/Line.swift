//
//  Line.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 7.10.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import Foundation
import RealmSwift

class Line: Overlay {
    let photos = List<String>()
    @objc dynamic var length: Double = 0.0
    @objc dynamic var lastUpdateTime: Date = Date()
    var polylineMarkersPositions = List<Position>()
}
