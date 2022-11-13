//
//  LinesController.swift
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

class LinesController {
    let realm = try! Realm()
    
    var userDefaults: Results<UserDefaults>?
    
    var lines: Results<Line>?
    var polylines = [GMSPolyline]()
    var selectedPolyline = GMSPolyline()
    lazy var updatedColor = ""
    lazy var updatedLength: Double = 0
    var selectedLine = Line() {
        didSet {
            if let polyline = polylines.first(where: {$0.title == selectedLine.id}) {
                selectedPolyline = polyline
            }
            selectedLineMarkers.removeAll()
            for position in selectedLine.polylineMarkersPositions {
                let marker = GMSMarker()
                marker.isDraggable = true
                marker.icon = UIImage(systemName: K.systemImages.dotCircle)?.imageScaled(to: CGSize(width: 30, height: 30))
                //marker.iconView =  UIImageView(image: UIImage(systemName: "dot.circle"))
                //marker.iconView?.tintColor = UIColor.flatBlackDark()
                marker.groundAnchor = .init(x: 0.5, y: 0.5)
                marker.position = CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude)
                selectedLineMarkers.append(marker)
            }
            updatedColor = selectedLine.color
            updatedLength = selectedLine.length
        }
    }
    var selectedLineMarkers = [GMSMarker]()
    var selectedLineLengthMarkers = [GMSMarker]()
    let db = Firestore.firestore()
    let user = Auth.auth().currentUser
    
    private lazy var updateTime = Date()
    //MARK: - loadLines
    func loadLines() {
        lines = realm.objects(Line.self)
    }
    //MARK: - init
    init(mapView: GMSMapView, isGeodesic: Bool) {
        userDefaults = realm.objects(UserDefaults.self)
        listenLineDocuments(mapView: mapView)
        loadLines()
        if let lines = lines {
            for line in lines {
                let newPolyline = GMSPolyline()
                newPolyline.title = line.id
                newPolyline.geodesic = isGeodesic
                newPolyline.strokeColor = UIColor(hexString: line.color)!
                newPolyline.strokeWidth = 5
                newPolyline.isTappable = true
                let rect = GMSMutablePath()
                for position in line.polylineMarkersPositions {
                    rect.add(CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude))
                }
                newPolyline.path = rect
                polylines.append(newPolyline)
            }
        }
        for polyline in polylines {
            polyline.map = mapView
        }
    }
    //MARK: - addLine
    func addLine(title: String, color: String, initialMarkers: [GMSMarker], mapView: GMSMapView, isGeodesic: Bool, id: String?) {
        let line = Line()
        if let id = id {
            line.id = id
        }
        line.title = title
        line.color = color
        
        for initialMarker in initialMarkers {
            let position = Position()
            position.latitude = initialMarker.position.latitude
            position.longitude = initialMarker.position.longitude
            line.polylineMarkersPositions.append(position)
        }
        updateTime = Date()
        line.lastUpdateTime = updateTime
        
        let newPolyline = GMSPolyline()
        newPolyline.title = line.id
        newPolyline.strokeColor = UIColor(hexString: line.color)!
        newPolyline.strokeWidth = 5
        newPolyline.isTappable = true
        let rect = GMSMutablePath()
        for position in line.polylineMarkersPositions {
            rect.add(CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude))
        }
        do {
            try realm.write({
                line.length = GMSGeometryLength(rect)
                realm.add(line)
                
                saveLineToCloud(line: line)
                
            })
        } catch {
            print("Error saving context, \(error)")
        }
        newPolyline.path = rect
        polylines.append(newPolyline)
        polylines[polylines.count-1].map = mapView
        loadLines()
    }
    //MARK: - checkTitleAvailable
    func checkTitleAvailable(title: String) -> String {
        var isValidName = true
        var errorMessage = "Line needs a title."
        if title.count == 0 {
            isValidName = false
            errorMessage = "Line needs a title."
        }
        for line in lines! {
            if line.title == title {
                isValidName = false
                errorMessage = "Lines can not has a same title."
            }
        }
        if isValidName {
            return "done"
        } else {
            return errorMessage
        }
    }
    //MARK: - changePolylinesTappableBoolean
    func changePolylinesTappableBoolean(to tapable: Bool) {
        for polyline in polylines {
            polyline.isTappable = tapable
        }
    }
    //MARK: - setColor
    func setColor(color: String, line: Line, mapView: GMSMapView){
        selectedPolyline.map = nil
        updatedColor = color
        selectedPolyline.strokeColor = UIColor(hexString: color)!
        selectedPolyline.map = mapView
    }
    //MARK: - setSelectedLineLength
    func setSelectedLineLength (length: Double) {
        updatedLength = length
    }
    
    //MARK: - saveLineToDB
    func saveLineToDB(line: Line) {
        do {
            try realm.write({
                line.polylineMarkersPositions.removeAll()
                for marker in selectedLineMarkers {
                    line.color = updatedColor
                    selectedLine.length = updatedLength
                    let position = Position()
                    position.latitude = marker.position.latitude
                    position.longitude = marker.position.longitude
                    selectedLine.polylineMarkersPositions.append(position)
                }
            })
        } catch {
            print("Error saving context, \(error)")
        }
        saveLineToCloud(line: selectedLine)
    }
    //MARK: - deleteSelectedLineFromDB
    func deleteSelectedLineFromDB(line: Line) {
        if let polyline = polylines.first(where: {$0.title == line.id}) {
            do {
                try self.realm.write {
                    self.realm.delete(line)
                    
                    polylines[polylines.firstIndex(of: polyline)!].map = nil
                    polyline.map = nil
                    polylines.remove(at: polylines.firstIndex(of: polyline)!)
                }
            } catch {
                print("Error Deleting category, \(error)")
            }
        }
        
        
        if line == selectedLine && selectedLineMarkers.count != 0 {
            for marker in selectedLineMarkers {
                marker.map = nil
            }
            setHideSelectedLineLengthMarkers(mapView: nil, remove: true)
        }
    }
    //MARK: - changeTitle +
    func changeTitle(for line: Line, title: String) {
        do {
            try self.realm.write({
                line.title = title
            })
        } catch {
            print("Error saving new items, \(error)")
        }
        changeTitleAtCloud(for: line, title: title)
    }
    
    //MARK: - FIREBASE
    
    //MARK: - saveLineToCloud
    func saveLineToCloud(line: Line) {
        if let user = user {
            var positions = [[String : Any]]()
            
            for position in line.polylineMarkersPositions {
                positions.append(position.dictionaryWithValues(forKeys: ["latitude", "longitude"]))
            }
            
            var photos = [[String : Any]]()
            
            for photo in line.photos {
                photos.append([photo:""])
            }
            
            self.db.collection(userDefaults!.first!.bossID).document("Lines").collection("Lines").document(line.id).setData(["updatedBy": user.uid, line.id: line.dictionaryWithValues(forKeys: ["title", "color", "length"]), "positions": positions, "photos": photos], merge: true)
            self.db.collection(user.uid).document("Lines").setData([line.id : self.updateTime], merge: true)
        }
    }
    
    //MARK: - changeTitle
    func changeTitleAtCloud(for line: Line, title: String) {
        if let user = user {
            self.db.collection(userDefaults!.first!.bossID).document("Lines").collection("Lines").document(line.id).setData(["updatedBy": user.uid, line.id: line.dictionaryWithValues(forKeys: ["title"])], merge: true)
            self.db.collection(user.uid).document("Lines").setData([line.id : self.updateTime], merge: true)
        }
    }
    
    //MARK: - deleteLineFromCloud
    func deleteLineFromCloud(line: Line) {
        if userDefaults?.first?.accountType == K.invites.accountTypes.proAccount {
            self.db.collection(userDefaults!.first!.bossID).document("Lines").collection("Lines").document(line.id).delete()
            self.db.collection(userDefaults!.first!.bossID).document("Lines").updateData([line.id : FieldValue.delete()])
        }
    }
    
    //MARK: - listenLineDocuments
    func listenLineDocuments(mapView: GMSMapView) {
        if let user = user {
            self.db.collection(userDefaults!.first!.bossID).document("Lines").collection("Lines").addSnapshotListener { [self] querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                snapshot.documentChanges.forEach { diff in
                    //MARK: - added
                    if (diff.type == .added) {
                        //print("New line: \(diff.document.data())")
                        //print(diff.document.documentID)
                        if realm.object(ofType: Line.self, forPrimaryKey: diff.document.documentID) != nil {
                            
                        } else {
                            //if diff.document.data()["updatedBy"] as? String != user.uid {
                            let line = Line()
                            line.id = diff.document.documentID
                            //print(diff.document.data())
                            if let lineData = diff.document.data()[diff.document.documentID] as? [String:Any] {
                                if let title = lineData["title"] as? String, let color = lineData["color"] as? String,let positions = diff.document.data()["positions"] as? [[String:Any]] {
                                    line.title = title
                                    line.color = color
                                    
                                    var initialMarkers = [GMSMarker]()
                                    
                                    for position in positions {
                                        if let lat = position["latitude"] as? Double, let lon = position["longitude"] as? Double {
                                            let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                                            initialMarkers.append(marker)
                                        }
                                    }
                                    
                                    addLine(title: title, color: color, initialMarkers: initialMarkers, mapView: mapView, isGeodesic: userDefaults!.first!.isGeodesicActive, id: diff.document.documentID)
                                }
                            }
                        }
                    }
                    //MARK: - modified
                    if (diff.type == .modified) {
                        //print("Modified line: \(diff.document.data())")
                        if let specificLine = realm.object(ofType: Line.self, forPrimaryKey: diff.document.documentID) {
                            if selectedLine == specificLine && selectedLineMarkers.count != 0 {
                                let nc = NotificationCenter.default
                                nc.post(name: Notification.Name("EndEditing"), object: nil)
                            }
                            
                            if diff.document.data()["updatedBy"] as? String != user.uid {
                                if let lineData = diff.document.data()[diff.document.documentID] as? [String:Any] {
                                    if let title = lineData["title"] as? String, let color = lineData["color"] as? String, let length = lineData["length"] as? Double {
                                        do {
                                            try realm.write({
                                                if specificLine.length != length {
                                                    specificLine.length = length
                                                }
                                                if let polyline = polylines.first(where: {$0.title == specificLine.id}) {
                                                    if specificLine.title != title {
                                                        specificLine.title = title
                                                    }
                                                    if specificLine.color != color {
                                                        specificLine.color = color
                                                        polyline.strokeColor = UIColor(hexString: color) ?? UIColor.flatRed()
                                                    }
                                                }
                                            })
                                        } catch {
                                            print("Error saving context, \(error)")
                                        }
                                    }
                                }
                                if let positions = diff.document.data()["positions"] as? [[String:Double]] {
                                    do {
                                        try realm.write({
                                            specificLine.polylineMarkersPositions.removeAll()
                                            for position in positions {
                                                if let lat = position["latitude"], let lon = position["longitude"] {
                                                    let linePosition = Position()
                                                    linePosition.latitude = lat
                                                    linePosition.longitude = lon
                                                    specificLine.polylineMarkersPositions.append(linePosition)
                                                }
                                            }
                                            if let polyline = polylines.first(where: {$0.title == specificLine.id}) {
                                                updatePolyline(line: specificLine, polyline: polyline, mapView: mapView)
                                            }
                                            
                                        })
                                    } catch {
                                        print("Error saving context, \(error)")
                                    }
                                }
                            }
                        }
                    }
                    //MARK: - removed
                    if (diff.type == .removed) {
                        //print("Removed line: \(diff.document.data())")
                        
                        if let specificLine = realm.object(ofType: Line.self, forPrimaryKey: diff.document.documentID) {
                            if selectedLine != specificLine {
                                deleteSelectedLineFromDB(line: specificLine)
                            } else {
                                if selectedLineMarkers.count == 0 {
                                    deleteSelectedLineFromDB(line: specificLine)
                                } else {
                                    let nc = NotificationCenter.default
                                    nc.post(name: Notification.Name("EndEditing"), object: nil)
                                    deleteSelectedLineFromDB(line: specificLine)
                                }
                            }
                        }
                        
                    }
                }
            }
        }
    }
    
    //MARK: - updatePolyline
    func updatePolyline(line: Line, polyline: GMSPolyline, mapView: GMSMapView) {
        let path = GMSMutablePath()
        for position in line.polylineMarkersPositions {
            path.add(CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude))
        }
        polyline.title = line.id
        polyline.strokeColor = UIColor(hexString: line.color)!
        polyline.strokeWidth = 5
        //newPolyline.isTappable = true
        polyline.path = path
        polyline.map = mapView
    }
    
    //MARK: - LENGTH MARKERS
    
    //MARK: - arrangeSelectedLineLengthMarker
    func arrangeSelectedLineLengthMarker(i: Int, inside: Bool, add: Bool, mapView: GMSMapView, isMetric: Bool, distanceUnit: Int) {
        
        if inside {
            let tempMarker = GMSMarker(position: GMSUnproject( GMSMapPointInterpolate(GMSProject((selectedLineMarkers[i-1].position)), GMSProject((selectedLineMarkers[i].position)), 0.5)))
            let tempLength = GMSGeometryDistance(selectedLineMarkers[i-1].position, selectedLineMarkers[i].position)
            tempMarker.groundAnchor = .init(x: 0.5, y: 0.5)
            tempMarker.isTappable = false
            tempMarker.title = "lengthMarker"
            tempMarker.iconView = UIImage.makeIconView(iconSize: 50, length: tempLength, isMetric: isMetric, distanceUnit: distanceUnit, isTappable: tempMarker.isTappable)
            if add {
                selectedLineLengthMarkers[i-1].map = nil
                selectedLineLengthMarkers.remove(at: i-1)
                
                selectedLineLengthMarkers.insert(tempMarker, at: i-1)
                tempMarker.map = mapView
            } else {
                selectedLineLengthMarkers[i-1].position = tempMarker.position
                selectedLineLengthMarkers[i-1].iconView = tempMarker.iconView
            }
            let tempMarker1 = GMSMarker(position: GMSUnproject( GMSMapPointInterpolate(GMSProject((selectedLineMarkers[i].position)), GMSProject((selectedLineMarkers[i+1].position)), 0.5)))
            let tempLength1 = GMSGeometryDistance(selectedLineMarkers[i].position, selectedLineMarkers[i+1].position)
            tempMarker1.groundAnchor = .init(x: 0.5, y: 0.5)
            tempMarker1.isTappable = false
            tempMarker1.title = "lengthMarker"
            tempMarker1.iconView = UIImage.makeIconView(iconSize: 50, length: tempLength1, isMetric: isMetric, distanceUnit: distanceUnit, isTappable: tempMarker1.isTappable)
            if add {
                selectedLineLengthMarkers.insert(tempMarker1, at: i)
                tempMarker1.map = mapView
            } else {
                selectedLineLengthMarkers[i].position = tempMarker1.position
                selectedLineLengthMarkers[i].iconView = tempMarker1.iconView
            }
        } else {
            if add || (!add && i == 0) {
                let tempMarker = GMSMarker(position: GMSUnproject( GMSMapPointInterpolate(GMSProject((selectedLineMarkers[i].position)), GMSProject((selectedLineMarkers[i+1].position)), 0.5)))
                let tempLength = GMSGeometryDistance(selectedLineMarkers[i].position, selectedLineMarkers[i+1].position)
                tempMarker.groundAnchor = .init(x: 0.5, y: 0.5)
                tempMarker.isTappable = false
                tempMarker.title = "lengthMarker"
                tempMarker.iconView = UIImage.makeIconView(iconSize: 50, length: tempLength, isMetric: isMetric, distanceUnit: distanceUnit, isTappable: tempMarker.isTappable)
                if add && (i != 0){
                    selectedLineLengthMarkers.append(tempMarker)
                    tempMarker.map = mapView
                } else if add && (i == 0) {
                    selectedLineLengthMarkers.insert(tempMarker, at: 0)
                    tempMarker.map = mapView
                } else {
                    selectedLineLengthMarkers[i].position = tempMarker.position
                    selectedLineLengthMarkers[i].iconView = tempMarker.iconView
                }
            } else {
                let tempMarker = GMSMarker(position: GMSUnproject( GMSMapPointInterpolate(GMSProject((selectedLineMarkers[i-1].position)), GMSProject((selectedLineMarkers[i].position)), 0.5)))
                let tempLength = GMSGeometryDistance(selectedLineMarkers[i-1].position, selectedLineMarkers[i].position)
                tempMarker.groundAnchor = .init(x: 0.5, y: 0.5)
                tempMarker.isTappable = false
                tempMarker.title = "lengthMarker"
                tempMarker.iconView = UIImage.makeIconView(iconSize: 50, length: tempLength, isMetric: isMetric, distanceUnit: distanceUnit, isTappable: tempMarker.isTappable)
                if add {
                    selectedLineLengthMarkers.append(tempMarker)
                    tempMarker.map = mapView
                } else {
                    selectedLineLengthMarkers[i-1].position = tempMarker.position
                    selectedLineLengthMarkers[i-1].iconView = tempMarker.iconView
                }
            }
        }
    }
    
    //MARK: - setSelectedLineLengthMarkers
    func setSelectedLineLengthMarkers(isMetric: Bool, distanceUnit: Int) {
        for i in 0...selectedLineMarkers.count-2 {
            let tempMarker = GMSMarker(position: GMSUnproject( GMSMapPointInterpolate(GMSProject((selectedLineMarkers[i].position)), GMSProject((selectedLineMarkers[i+1].position)), 0.5)))
            let tempLength = GMSGeometryDistance(selectedLineMarkers[i].position, selectedLineMarkers[i+1].position)
            tempMarker.groundAnchor = .init(x: 0.5, y: 0.5)
            tempMarker.isTappable = false
            tempMarker.title = "lengthMarker"
            tempMarker.iconView = UIImage.makeIconView(iconSize: 50, length: tempLength, isMetric: isMetric, distanceUnit: distanceUnit, isTappable: tempMarker.isTappable)
            selectedLineLengthMarkers.append(tempMarker)
        }
    }
    //MARK: - setHideSelectedLineLengthMarkers
    func setHideSelectedLineLengthMarkers(mapView: GMSMapView?, remove: Bool) {
        for marker in selectedLineLengthMarkers {
            marker.map = mapView
        }
        if mapView == nil && remove {
            selectedLineLengthMarkers.removeAll()
        }
    }
    //MARK: - deleteSelectedLineLengthMarker
    func deleteSelectedLineLengthMarker(index: Int, isMetric: Bool, distanceUnit: Int) {
        if index == 0 {
            selectedLineLengthMarkers.removeFirst().map = nil
        } else if index == selectedLineLengthMarkers.count {
            selectedLineLengthMarkers.popLast()?.map = nil
        } else {
            selectedLineLengthMarkers.remove(at: index).map = nil
            let tempMarker = GMSMarker(position: GMSUnproject( GMSMapPointInterpolate(GMSProject((selectedLineMarkers[index-1].position)), GMSProject((selectedLineMarkers[index].position)), 0.5)))
            let tempLength = GMSGeometryDistance(selectedLineMarkers[index-1].position, selectedLineMarkers[index].position)
            tempMarker.groundAnchor = .init(x: 0.5, y: 0.5)
            tempMarker.isTappable = false
            tempMarker.title = "lengthMarker"
            tempMarker.iconView = UIImage.makeIconView(iconSize: 50, length: tempLength, isMetric: isMetric, distanceUnit: distanceUnit, isTappable: tempMarker.isTappable)
            
            selectedLineLengthMarkers[index-1].position = tempMarker.position
            selectedLineLengthMarkers[index-1].iconView = tempMarker.iconView
        }
    }
    
    private var index = 0
    
    //MARK: - setEditableSelectedLineLengthMarker
    func setEditableSelectedLineLengthMarker(index: Int) {
        for marker in selectedLineLengthMarkers {
            marker.isDraggable = false
            marker.isTappable = false
            
            let tempView = marker.iconView
            tempView?.layer.borderWidth = 0
            tempView?.layer.borderColor = UIColor.systemBlue.cgColor
            marker.iconView = tempView
        }
        if index != selectedLineMarkers.count - 1 {
            selectedLineLengthMarkers[index].isTappable = true
            
            var tempView = selectedLineLengthMarkers[index].iconView
            tempView?.layer.borderWidth = 1
            tempView?.layer.borderColor = UIColor.systemBlue.cgColor
            selectedLineLengthMarkers[index].iconView = tempView
            
            if index != 0 {
                selectedLineLengthMarkers[index-1].isTappable = true
                
                tempView = selectedLineLengthMarkers[index-1].iconView
                tempView?.layer.borderWidth = 1
                tempView?.layer.borderColor = UIColor.systemBlue.cgColor
                selectedLineLengthMarkers[index-1].iconView = tempView
            }
        } else {
            selectedLineLengthMarkers[index-1].isTappable = true
            
            let tempView = selectedLineLengthMarkers[index-1].iconView
            tempView?.layer.borderWidth = 1
            tempView?.layer.borderColor = UIColor.systemBlue.cgColor
            selectedLineLengthMarkers[index-1].iconView = tempView
        }
        self.index = index
    }
    //MARK: - setEdgeLength
    func setEdgeLength(lengthMarkerIndex: Int, edgeLength: Double) -> GMSMarker? {
        if lengthMarkerIndex == index && index != selectedLineMarkers.count-1 {
            let oldLength = GMSGeometryDistance(selectedLineMarkers[index].position, selectedLineMarkers[index + 1].position)
            let a = edgeLength / oldLength
            let newPosition = GMSGeometryInterpolate(selectedLineMarkers[index].position, selectedLineMarkers[index + 1].position, a)
            selectedLineMarkers[index + 1].position = newPosition
            return selectedLineMarkers[index + 1]
        } else {
            let oldLength = GMSGeometryDistance(selectedLineMarkers[index].position, selectedLineMarkers[index - 1].position)
            let a = edgeLength / oldLength
            let newPosition = GMSGeometryInterpolate(selectedLineMarkers[index].position, selectedLineMarkers[index - 1].position, a)
            selectedLineMarkers[index - 1].position = newPosition
            return selectedLineMarkers[index - 1]
        }
    }
    
}
//MARK: - extension UIImage
extension UIImage {
    static func makeIconView(iconSize: Int, length : Double, isMetric: Bool, distanceUnit: Int, isTappable: Bool) -> UIImageView {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: iconSize, height: iconSize/2))
        label.backgroundColor = UIColor(hexString: K.colors.primaryColor)
        let lengthWithUnit = Measurement.init(value: length, unit: UnitLength.meters)
        
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 2
        formatter.unitOptions = .providedUnit
        
        if isMetric {
            switch distanceUnit {
            case 0:
                label.text = formatter.string(from:lengthWithUnit.converted(to: UnitLength.centimeters))
            case 1:
                label.text = formatter.string(from:lengthWithUnit.converted(to: UnitLength.meters))
            case 2:
                label.text = formatter.string(from:lengthWithUnit.converted(to: UnitLength.kilometers))
            default:
                break
            }
        } else {
            switch distanceUnit {
            case 0:
                label.text = formatter.string(from:lengthWithUnit.converted(to: UnitLength.inches))
            case 1:
                label.text = formatter.string(from:lengthWithUnit.converted(to: UnitLength.feet))
            case 2:
                label.text = formatter.string(from:lengthWithUnit.converted(to: UnitLength.yards))
            case 3:
                label.text = formatter.string(from:lengthWithUnit.converted(to: UnitLength.miles))
            default:
                break
            }
        }
        
        label.sizeToFit()
        label.textColor = UIColor.flatBlack()
        label.adjustsFontSizeToFitWidth = true
    
        if isTappable {
            label.layer.borderWidth = 1
            label.layer.borderColor = UIColor.systemBlue.cgColor
        }
        
        let image = UIImage.imageWithLabel(label: label)
        return UIImageView(image: image)
    }
    static func makeIconView(iconSize: Int, lat: Double, lon: Double) -> UIImageView {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: iconSize, height: iconSize/2))
        label.backgroundColor = UIColor(hexString: K.colors.primaryColor)
        label.text = "Lat: \(String(format: "%.4f", lat)) Lon: \(String(format: "%.4f", lon))"
        label.sizeToFit()
        label.textColor = UIColor.flatBlack()
        label.adjustsFontSizeToFitWidth = true
        let image = UIImage.imageWithLabel(label: label)
        return UIImageView(image: image)
    }
}
