//
//  MapViewModel.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 9.11.2022.
//  Copyright © 2022 Enes Kılıç. All rights reserved.
//

import Foundation
import RealmSwift
import Firebase
import CoreLocation

protocol MapViewModelProtocol: AnyObject {
    var viewController: MapViewControllerProtocol? { get set }
    func notifyViewDidLoad(with latLon: (Double?, Double?))
    func notifyViewWillAppear()
}

class MapViewModel: MapViewModelProtocol {
  
    weak var viewController: MapViewControllerProtocol?
    
    let realm = try! Realm()
    
    private var userDefaults: Results<UserDefaults>?
    
    private var handle: AuthStateDidChangeListenerHandle?
    private let user = Auth.auth().currentUser
    
    init() {
        userDefaults = realm.objects(UserDefaults.self)
    }
    
    func notifyViewDidLoad(with latLon: (Double?, Double?)) {
        if userDefaults?.count == 0 {
            createUserDefaults(with: latLon)
        } else {
            if let userDefaults = userDefaults, let userDefaultsFirst = userDefaults.first {
                viewController?.setUserDefaultSettings(latitude: userDefaultsFirst.cameraPosition?.latitude, longitude: userDefaultsFirst.cameraPosition?.longitude, zoom: userDefaultsFirst.cameraPosition?.zoom, mapType: userDefaultsFirst.mapType, customMapStyle: userDefaultsFirst.customMapStyle, isBatterySaveModeActive: userDefaultsFirst.isBatterySaveModeActive)
            }
        }
    }
    
    private func createUserDefaults(with latLon: (Double?, Double?)) {
        let userDefault = UserDefaults()
        userDefault.title = ""
        userDefault.mapType = K.mapTypes.satellite
        userDefault.cameraPosition = CameraPosition()
        if let latitude = latLon.0, let longitude = latLon.1 {
            userDefault.cameraPosition?.latitude = latitude
            userDefault.cameraPosition?.longitude = longitude
        } else {
            userDefault.cameraPosition?.latitude = 37.3348
            userDefault.cameraPosition?.longitude = -122.0091
        }
        userDefault.cameraPosition?.zoom = 16.5
    
        do {
            try realm.write({
                realm.add(userDefault)
            })
        } catch {
            print("Error saving context, \(error)")
        }
        userDefaults = realm.objects(UserDefaults.self)
    }
    
    func notifyViewWillAppear() {
        if userDefaults?.first?.accountType != K.invites.accountTypes.proAccount {
            viewController?.arrangeUI(isProAccount: true)
        } else {
            viewController?.arrangeUI(isProAccount: false)
        }
    }
    
    
}

