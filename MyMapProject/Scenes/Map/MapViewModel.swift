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
import GoogleMaps

protocol MapViewModelProtocol: AnyObject {
    var userDefaults: UserDefaults! { get }
    var viewController: MapViewControllerProtocol? { get set }
    func notifyViewDidLoad()
    func saveCameraPosition(latitude: Double, longitude: Double, zoom: Float)
    func saveMapType(with mapType: String)
    func getMyLocation() -> CLLocation?
}

class MapViewModel: NSObject, MapViewModelProtocol {
    
    weak var viewController: MapViewControllerProtocol?
    
    let realm = try! Realm()
    
    var userDefaults: UserDefaults!
    private let locationManager = CLLocationManager()
    
    private var handle: AuthStateDidChangeListenerHandle?
    private let user = Auth.auth().currentUser
    
    override init() {
        
    }
    
    func notifyViewDidLoad() {
        
        // Get userDefaults in the realm
        let allUserDefaults = realm.objects(UserDefaults.self)
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.delegate = self
                self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
                self.locationManager.startUpdatingLocation()
            }
        }
        
        if allUserDefaults.count == 0 {
            createUserDefaults()
        } else {
            userDefaults = allUserDefaults.first
        }
        
        viewController?.setMapView(latitude: userDefaults.cameraPosition?.latitude,
                                   longitude: userDefaults.cameraPosition?.longitude,
                                   zoom: userDefaults.cameraPosition?.zoom,
                                   mapType: userDefaults.mapType,
                                   customMapStyle: userDefaults.customMapStyle,
                                   isBatterySaveModeActive: userDefaults.isBatterySaveModeActive)
        
        
        if let userID = user?.uid {
            do {
                try realm.write({
                    userDefaults.bossID = userID
                    userDefaults.bossEmail = user?.email ?? ""
                })
            } catch {
                print("Error saving context, \(error)")
            }
        }
    }
    
    func getMyLocation() -> CLLocation? {
        return locationManager.location
    }
    
    func saveCameraPosition(latitude: Double, longitude: Double, zoom: Float) {
        do {
            try realm.write({
                userDefaults.cameraPosition?.latitude = latitude
                userDefaults.cameraPosition?.longitude = longitude
                userDefaults.cameraPosition?.zoom = zoom
                realm.add(userDefaults)
            })
        } catch {
            print(K.errorSavingContext + " \(error)")
        }
    }
    
    func saveMapType(with mapType: String) {
        do {
            try realm.write({
                userDefaults.mapType = mapType
                realm.add(userDefaults)
            })
        } catch {
            print(K.errorSavingContext + "\(error)")
        }
    }
    
    fileprivate func createUserDefaults() {
        let userDefaults = UserDefaults()
        userDefaults.title = ""
        userDefaults.mapType = K.mapTypes.satellite
        userDefaults.cameraPosition = CameraPosition()
        if let latitude = locationManager.location?.coordinate.latitude, let longitude = locationManager.location?.coordinate.longitude {
            userDefaults.cameraPosition?.latitude = latitude
            userDefaults.cameraPosition?.longitude = longitude
        } else {
            userDefaults.cameraPosition?.latitude = 37.3348
            userDefaults.cameraPosition?.longitude = -122.0091
        }
        userDefaults.cameraPosition?.zoom = 16.5
        
        do {
            try realm.write({
                realm.add(userDefaults)
            })
        } catch {
            print("Error saving context, \(error)")
        }
        self.userDefaults = userDefaults
    }
    
}

extension MapViewModel: CLLocationManagerDelegate {
    //MARK: - Location Manager delegates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        viewController?.setMapViewLocationEnabled(isEnabled: true)
    }
}


