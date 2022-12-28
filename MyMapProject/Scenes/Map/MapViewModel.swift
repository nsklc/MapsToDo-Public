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
    func createNewMarker(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) -> GMSMarker
    func findClosestMarkers(newMarker: GMSMarker, markers: [GMSMarker]) -> (Int, Int)
}

class MapViewModel: NSObject, MapViewModelProtocol {
    
    weak var viewController: MapViewControllerProtocol?
    
    let realm: Realm! = try? Realm()
    
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
        locationManager.location
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
    
    // Marker adding helpers
    func createNewMarker(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) -> GMSMarker {
        let newMarker = GMSMarker()
        newMarker.map = mapView
        newMarker.isDraggable = true
        newMarker.icon = UIImage(systemName: K.SystemImages.dotCircle)?.imageScaled(to: CGSize(width: 30, height: 30))
        newMarker.groundAnchor = .init(x: 0.5, y: 0.5)
        newMarker.position = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return newMarker
    }
    
    func findClosestMarkers(newMarker: GMSMarker, markers: [GMSMarker]) -> (Int, Int) {
        var closestMarkerIndex = 0
        var secondClosestMarkerIndex = 0
        var closestDistance = Double.greatestFiniteMagnitude
        var secondClosestDistance = Double.greatestFiniteMagnitude
        for i in 0..<markers.count {
            let distance = GMSGeometryDistance(newMarker.position, markers[i].position)
            if distance < closestDistance {
                secondClosestDistance = closestDistance
                secondClosestMarkerIndex = closestMarkerIndex
                closestDistance = distance
                closestMarkerIndex = i
            } else if distance < secondClosestDistance {
                secondClosestDistance = distance
                secondClosestMarkerIndex = i
            }
        }
        return (closestMarkerIndex, secondClosestMarkerIndex)
    }
    
    fileprivate func createUserDefaults() {
        let userDefaults = UserDefaults()
        userDefaults.title = ""
        userDefaults.mapType = K.MapTypes.satellite
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
    // MARK: - Location Manager delegates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        viewController?.setMapViewLocationEnabled(isEnabled: true)
    }
}
