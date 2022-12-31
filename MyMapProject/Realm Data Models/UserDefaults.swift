//
//  userDefaults.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 4.10.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import Foundation
import RealmSwift

class UserDefaults: Object {
    @objc dynamic var title: String = ""
    @objc dynamic var cameraPosition: CameraPosition?
    @objc dynamic var mapType: String?
    @objc dynamic var mapIconsColor: String = UIColor.flatRed().hexValue()
    
    @objc dynamic var showDistancesBetweenTwoCorners = true
    @objc dynamic var isMeasureSystemMetric = true
    
    @objc dynamic var isShowAllUnitsSelected = false
    @objc dynamic var distanceUnit = 2
    @objc dynamic var areaUnit = 2
    
    @objc dynamic var isGeodesicActive = true
    
    @objc dynamic var isBatterySaveModeActive = false
    @objc dynamic var isLowDataModeActive = false
    
    @objc dynamic var accountType = K.Invites.AccountTypes.freeAccount
    @objc dynamic var bossID = UUID().uuidString
    @objc dynamic var bossEmail = ""
    @objc dynamic var userRole = "admin"
    
    let subscriptions = List<subscription>()
    
    @objc dynamic var customMapStyle = ""
    @objc dynamic var customMapDefaultStyle = ""
    @objc dynamic var roads: Float = 1.0
    @objc dynamic var landmarks: Float = 1.0
    @objc dynamic var labels: Float = 1.0
}

class CameraPosition: Object {
    @objc dynamic var latitude: Double = 0
    @objc dynamic var longitude: Double = 0
    @objc dynamic var zoom: Float = 0
}

class subscription: Object {
    @objc dynamic var identifier = ""
    @objc dynamic var expirationDate = Date()
}
