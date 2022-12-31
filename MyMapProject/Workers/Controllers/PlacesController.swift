//
//  PlacesController.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 19.10.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import Foundation
import GoogleMaps
import RealmSwift
import Firebase
import FirebaseFirestore

class PlacesController {
    let realm: Realm! = try? Realm()
    
    var userDefaults: Results<UserDefaults>?
    
    var places: Results<Place>?
    // var groundOverlays = [GMSGroundOverlay]()
    
    var placeMarkers = [GMSMarker]()
    
    var selectedPlaceMarker = GMSMarker()
    private lazy var updateTime = Date()
    lazy var updatedColor = ""
    lazy var updatedIconSize: Float = 0.003
    var selectedPlace = Place() {
        didSet {
            if let marker = placeMarkers.first(where: {$0.title == selectedPlace.id}) {
                selectedPlaceMarker = marker
            }
            updatedColor = selectedPlace.color
            updatedIconSize = selectedPlace.iconSize
        }
    }
    
    let db = Firestore.firestore()
    let user = Auth.auth().currentUser
    
    // MARK: - loadPlaces
    func loadPlaces() {
        places = realm.objects(Place.self)
    }
    // MARK: - init
    init(mapView: GMSMapView) {
        userDefaults = realm.objects(UserDefaults.self)
        listenPlaceDocuments(mapView: mapView)
        loadPlaces()
        
        if let places = places {
            for place in places {
                
                if let latitude = place.markerPosition?.latitude, let longitude = place.markerPosition?.longitude {
                                        
                    let newPlaceMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                    newPlaceMarker.title = place.id
                    // newPlaceMarker.icon = newPlaceMarker.icon?.withTintColor(UIColor(hexString: place.color) ?? UIColor.flatBlueDark() , renderingMode: .automatic)
                    newPlaceMarker.icon = makeIconView(title: "", color: place.color)
                    newPlaceMarker.isTappable = true
                    
                    placeMarkers.append(newPlaceMarker)
                    placeMarkers.last?.map = mapView
                }
            }
        }
    }
    // MARK: - addPlace
    func addPlace(title: String, color: String, mapView: GMSMapView, initialMarker: GMSMarker, id: String?, iconSize: Float?) {
        let place = Place()
        if let id = id {
            place.id = id
        }
        place.title = title
        place.color = color
        place.markerPosition = Position()
        place.markerPosition?.latitude = initialMarker.position.latitude
        place.markerPosition?.longitude = initialMarker.position.longitude
        updateTime = Date()
        place.lastUpdateTime = updateTime
        
        do {
            try realm.write({
                realm.add(place)
                savePlaceToCloud(place: place)
            })
        } catch {
            print("Error saving context, \(error)")
        }
        
        if let latitude = place.markerPosition?.latitude, let longitude = place.markerPosition?.longitude {
            
            let newPlaceMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            newPlaceMarker.title = place.id
            newPlaceMarker.icon = makeIconView(title: "", color: place.color)
            newPlaceMarker.isTappable = true
            
            placeMarkers.append(newPlaceMarker)
            placeMarkers.last?.map = mapView
            
        }
        loadPlaces()
    }
    // MARK: - checkTitleAvailable
    func checkTitleAvailable(title: String) -> String {
        var isValidName = true
        var errorMessage = "Place needs a title."
        if title.isEmpty {
            isValidName = false
            errorMessage = "Place needs a title."
        }
        for place in places! {
            if place.title == title {
                isValidName = false
                errorMessage = "Places can not has a same title."
            }
        }
        if isValidName {
            return "done"
        } else {
            return errorMessage
        }
    }
    // MARK: - changeGroundOverlayTappableBoolean
    func changeGroundOverlayTappableBoolean(to tapable: Bool) {
        for marker in placeMarkers {
            marker.isTappable = tapable
        }
    }
    // MARK: - setColor
    func setColor(color: String, place: Place, mapView: GMSMapView) {
        selectedPlaceMarker.map = nil
        updatedColor = color
        selectedPlaceMarker.icon = makeIconView(title: "", color: color)
        selectedPlaceMarker.map = mapView
    }
    // MARK: - makeIconView
    func makeIconView(title: String, color: String) -> UIImage {
        /*let label = UILabel(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        label.text = title
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center
        label.textColor = UIColor(hexString: color)
        let image = UIImage.imageWithLabel(label: label)
        
        let bottomImage = UIImage(systemName: K.systemImages.building2CropCircle)!.withTintColor(UIColor(hexString: color) ?? UIColor.flatMint())
        
        let topImage = image
        
        let size = CGSize(width: 4*500, height: 4*500)
        UIGraphicsBeginImageContext(size)
        
        let topImageAreaSize = CGRect(x: 0, y: 0, width: 4*500, height: 4*500)
        let bottomImageAreaSize = CGRect(x: 0, y: 2*500+(500/5), width: 4*500, height: 2*500)
        
        bottomImage.draw(in: bottomImageAreaSize)
        topImage.draw(in: topImageAreaSize, blendMode: .normal, alpha: 1)
        
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let DynamicView = UIImageView(image: newImage.imageScaled(to: CGSize(width: CGFloat(100), height: CGFloat(100))))
     
        UIGraphicsBeginImageContextWithOptions(DynamicView.frame.size, false, UIScreen.main.scale)
        DynamicView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let imageConverted: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        //return UIImageView(image: newImage.imageScaled(to: CGSize(width: CGFloat(500), height: CGFloat(500)))).image!
        return DynamicView.image!*/
        
        let tempmarker = GMSMarker(position: CLLocationCoordinate2D(latitude: 0, longitude: 0))
        
        let size: CGSize = tempmarker.icon?.size ?? CGSize(width: 100, height: 100)
        
        // let bottomImage = UIImage(systemName: "building.2.fill")!.imageScaled(to: size).withTintColor(UIColor(hexString: color) ?? UIColor.flatMint())
        let bottomImage = UIImage(systemName: "pin.fill")!.imageScaled(to: size).withTintColor(UIColor(hexString: color) ?? UIColor.flatMint())
        
        return bottomImage.imageScaled(to: CGSize(width: 35, height: 35))
    }
    // MARK: - increaseIconSize
    func increaseIconSize(place: Place, mapView: GMSMapView) {
       
    }
    // MARK: - decreaseIconSize
    func decreaseIconSize(place: Place, mapView: GMSMapView) {
     
    }
    
    // MARK: - savePlaceToDB
    func savePlaceToDB(place: Place, placeMarker: GMSMarker) {
        updateTime = Date()
        if let marker = placeMarkers.first(where: {$0.title == place.id}) {
            marker.position.latitude = placeMarker.position.latitude
            marker.position.longitude = placeMarker.position.longitude
        }
        
        do {
            try realm.write({
                place.color = updatedColor
                place.iconSize = updatedIconSize
                let position = Position()
                position.latitude = placeMarker.position.latitude
                position.longitude = placeMarker.position.longitude
                place.markerPosition = position
                place.lastUpdateTime = updateTime
            })
        } catch {
            print("Error saving context, \(error)")
        }
        savePlaceToCloud(place: place)
    }
    // MARK: - changeTitle
    func changeTitle(for place: Place, title: String) {
        do {
            try self.realm.write({
                place.title = title
            })
        } catch {
            print("Error saving new items, \(error)")
        }
        changeTitleAtCloud(for: place, title: title)
    }
    // MARK: - Delete Place From DB
    func deletePlaceFromDB(place: Place) {
        if let placeMarker = placeMarkers.first(where: {$0.title == place.id}) {
            do {
                try self.realm.write {
                    self.realm.delete(place)
                    
                    selectedPlaceMarker = placeMarker
                    selectedPlaceMarker.map = nil
                    placeMarkers.remove(at: placeMarkers.firstIndex(of: selectedPlaceMarker)!)
                }
            } catch {
                print("Error Deleting category, \(error)")
            }
        }
    }
    
    // MARK: - FIREBASE
    
    // MARK: - savePlaceToCloud
    func savePlaceToCloud(place: Place) {
        if let user = user {
            var photos = [[String: Any]]()
            
            for photo in place.photos {
                photos.append([photo: ""])
            }
            
            self.db.collection(userDefaults!.first!.bossID).document("Places").collection("Places").document(place.id).setData(["updatedBy": user.uid, place.id: place.dictionaryWithValues(forKeys: ["title", "color", "iconSize"]), "position": place.markerPosition!.dictionaryWithValues(forKeys: ["latitude", "longitude"]), "photos": photos], merge: true) { error in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
            self.db.collection(user.uid).document("Places").setData([place.id: self.updateTime], merge: true)
        }
    }
    // MARK: - changeTitleAtCloud
    func changeTitleAtCloud(for place: Place, title: String) {
        if let user = user {
            self.db.collection(userDefaults!.first!.bossID).document("Places").collection("Places").document(place.id).setData(["updatedBy": user.uid, place.id: place.dictionaryWithValues(forKeys: ["title"])], merge: true)
            self.db.collection(user.uid).document("Places").setData([place.id: self.updateTime], merge: true)
        }
    }
    // MARK: - deletePlaceFromCloud
    func deletePlaceFromCloud(place: Place) {
        if user != nil {
            self.db.collection(userDefaults!.first!.bossID).document("Places").collection("Places").document(place.id).delete()
            self.db.collection(userDefaults!.first!.bossID).document("Places").updateData([place.id: FieldValue.delete()])
        }
    }
    // MARK: - listenPlaceDocuments
    func listenPlaceDocuments(mapView: GMSMapView) {
        if let user = user {
            self.db.collection(userDefaults!.first!.bossID).document("Places").collection("Places").addSnapshotListener { [self] querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                snapshot.documentChanges.forEach { diff in
                    // MARK: - added
                    if diff.type == .added {
                        addPlacesFromFireStore(diff, mapView: mapView)
                    }
                    // MARK: - modified
                    if diff.type == .modified {
                        // print("Modified place: \(diff.document.data())")
                        if let specificPlace = realm.object(ofType: Place.self, forPrimaryKey: diff.document.documentID) {
                            if selectedPlace == specificPlace {
                                let nc = NotificationCenter.default
                                nc.post(name: Notification.Name("EndEditing"), object: nil)
                            }
                            if diff.document.data()["updatedBy"] as? String != user.uid {
                                if let placeData = diff.document.data()[diff.document.documentID] as? [String: Any] {
                                    if let title = placeData["title"] as? String, let color = placeData["color"] as? String, let iconSize = placeData["iconSize"] as? Float, let position = diff.document.data()["position"] as? [String: Any] {
                                        if let lat = position["latitude"] as? Double, let lon = position["longitude"] as? Double {
                                            do {
                                                try realm.write({
                                                    if specificPlace.title != title {
                                                        specificPlace.title = title
                                                    }
                                                    if specificPlace.color != color {
                                                        specificPlace.color = color
                                                    }
                                                    if specificPlace.iconSize != iconSize {
                                                        specificPlace.iconSize = iconSize
                                                    }
                                                    if specificPlace.markerPosition?.latitude != lat {
                                                        specificPlace.markerPosition?.latitude = lat
                                                    }
                                                    if specificPlace.markerPosition?.longitude != lon {
                                                        specificPlace.markerPosition?.longitude = lon
                                                    }
                                                })
                                            } catch {
                                                print("Error saving context, \(error)")
                                            }
                                            if let marker = placeMarkers.first(where: {$0.title == specificPlace.id}) {
                                                marker.title = diff.document.documentID
                                                marker.icon = makeIconView(title: "", color: specificPlace.color)
                                                marker.position.latitude = lat
                                                marker.position.longitude = lon
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    // MARK: - removed
                    if diff.type == .removed {
                        // print("Removed place: \(diff.document.data())")
                        if let specificPlace = realm.object(ofType: Place.self, forPrimaryKey: diff.document.documentID) {
                            if selectedPlace != specificPlace {
                                deletePlaceFromDB(place: specificPlace)
                            } else {
                                let nc = NotificationCenter.default
                                nc.post(name: Notification.Name("EndEditing"), object: nil)
                                deletePlaceFromDB(place: specificPlace)
                            }
                        }
                    }
                }
            }
        }
    }
    // MARK: - addPlacesFromFireStore
    private func addPlacesFromFireStore(_ diff: DocumentChange, mapView: GMSMapView) {
        // print("New place: \(diff.document.data())")
        // print(diff.document.documentID)
        if realm.object(ofType: Place.self, forPrimaryKey: diff.document.documentID) != nil {
        } else {
            // if diff.document.data()["updatedBy"] as? String != user.uid {
            
            // print(diff.document.data())
            if let placeData = diff.document.data()[diff.document.documentID] as? [String: Any], let position = diff.document.data()["position"] as? [String: Any] {
                
                if let title = placeData["title"] as? String, let color = placeData["color"] as? String, let iconSize = placeData["iconSize"] as? Float {
                    if let lat = position["latitude"] as? Double, let lon = position["longitude"] as? Double {
                        let initialMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                        addPlace(title: title, color: color, mapView: mapView, initialMarker: initialMarker, id: diff.document.documentID, iconSize: iconSize)
                    }
                }
            }
            // }
        }
    }
}
