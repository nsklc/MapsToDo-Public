//
//  FieldsController.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 20.10.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import Foundation
import GoogleMaps
import RealmSwift
import Firebase
import FirebaseFirestore

class FieldsController {
    private let realm: Realm! = try? Realm()
    
    var userDefaults: Results<UserDefaults>?
    
    var groups: Results<Group>?
    var fields: Results<Field>?
    lazy var polygons = [GMSPolygon]()
    lazy var selectedPolygon = GMSPolygon()
    var selectedField = Field() {
        didSet {
            updatedArea = selectedField.area
            updatedCircumference = selectedField.circumference
            updatedColor = selectedField.color
            if let polygon = polygons.first(where: {$0.title == selectedField.id}) { selectedPolygon = polygon }
            selectedFieldMarkers.removeAll()
            for position in selectedField.polygonMarkersPositions {
                let marker = GMSMarker()
                marker.isDraggable = true
                marker.icon = UIImage(systemName: K.SystemImages.dotCircle)?.imageScaled(to: CGSize(width: 30, height: 30))
                marker.groundAnchor = .init(x: 0.5, y: 0.5)
                marker.position = CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude)
                selectedFieldMarkers.append(marker)
            }
        }
    }
    lazy var selectedFieldMarkers = [GMSMarker]()
    private(set) lazy var selectedFieldLengthMarkers = [GMSMarker]()
    
    private var mapView: GMSMapView?
    private lazy var updateTime = Date()
    private lazy var updatedColor = ""
    lazy var updatedArea: Double = 0
    lazy var updatedCircumference: Double = 0
    var grouplessGroupID: String = "703A9A36-8F4C-436A-A834-7E2C08C5917F"
    
    private var isGeodesic = true
    
    private let db = Firestore.firestore()
    private let user = Auth.auth().currentUser
    
    // MARK: - loadFieldsAndGroups
    func loadFieldsAndGroups() {
        fields = realm.objects(Field.self)
        groups = realm.objects(Group.self)
    }
    // MARK: - init
    init(mapView: GMSMapView) {
        userDefaults = realm.objects(UserDefaults.self)
        listenGroupsDocuments(mapView: mapView)
        listenFieldDocuments(mapView: mapView)
        loadFieldsAndGroups()
        
        /*
            fields?.forEach({ (field) in
                print(field.id)
            })
         */
        self.isGeodesic = userDefaults!.first!.isGeodesicActive
        
        if polygons.count > fields!.count {
            polygons.removeAll()
        }
        if let fields = fields {
            for field in fields {
                let newPolygon = GMSPolygon()
                newPolygon.title = field.id
                if let grouplessGroup = groups!.first(where: {$0.title == NSLocalizedString("Groupless Group", comment: "")}) {
                    grouplessGroupID = grouplessGroup.id
                    // print(grouplessGroupID)
                }
                
                if let parentGroup = field.parentGroup.first {
                    if parentGroup.id != grouplessGroupID {
                        if let color = UIColor(hexString: field.parentGroup.first!.color) {
                            newPolygon.fillColor = color
                        } else {
                            newPolygon.fillColor = UIColor(hexString: field.color) ?? UIColor.flatBlackDark()
                        }
                    } else {
                        newPolygon.fillColor = UIColor(hexString: field.color) ?? UIColor.flatBlackDark()
                    }
                } else {
                    newPolygon.fillColor = UIColor(hexString: field.color) ?? UIColor.flatBlackDark()
                }
                
                newPolygon.strokeColor = UIColor.flatBlackDark()
                newPolygon.strokeWidth = 1
                newPolygon.isTappable = true
                newPolygon.geodesic = isGeodesic
                let rect = GMSMutablePath()
                for position in field.polygonMarkersPositions {
                    rect.add(CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude))
                }
                newPolygon.path = rect
                polygons.append(newPolygon)
            }
        }
        for polygon in polygons {
            polygon.map = mapView
        }
        self.mapView = mapView
    }
    // MARK: - addField
    func addField(title: String, groupTitle: String, color: String, initialMarkers: [GMSMarker], id: String?, isGeodesic: Bool) {
        var fieldsGroup: Group?
        
        if realm.object(ofType: Group.self, forPrimaryKey: grouplessGroupID) == nil {
            
            let grouplessGroup = Group()
            grouplessGroup.title = NSLocalizedString("Groupless Group", comment: "")
            grouplessGroup.color = UIColor.flatLime().hexValue()
            grouplessGroup.id = "703A9A36-8F4C-436A-A834-7E2C08C5917F"
            do {
                try realm.write({
                    realm.add(grouplessGroup)
                })
            } catch {
                print("Error saving context, \(error)")
            }
            groups = realm.objects(Group.self)
            // grouplessGroupID = grouplessGroup.id
            saveGroupToCloud(group: grouplessGroup)
        }
        
        for group in groups! {
            if groupTitle == group.title {
                if group.color != color {
                    do {
                        try realm.write({
                            group.color = color
                            // realm.add(group)
                        })
                    } catch {
                        print("Error saving context, \(error)")
                    }
                    for field in group.fields {
                        setColor(colorHex: color, field: field)
                    }
                }
                
                fieldsGroup = group
            }
        }
        
        if fieldsGroup == nil {
            if !groupTitle.isEmpty {
                let newGroup = Group()
                newGroup.title = groupTitle
                newGroup.color = color
                fieldsGroup = newGroup
                do {
                    try realm.write({
                        realm.add(newGroup)
                        saveGroupToCloud(group: fieldsGroup!)
                    })
                } catch {
                    print("Error saving context, \(error)")
                }
                self.groups = realm.objects(Group.self)
            } else {
//                for group in groups! {
//                    if NSLocalizedString("Groupless Group", comment: "") == group.title {
//                        fieldsGroup = group
//                    }
                    if let group = groups!.first(where: {$0.id == grouplessGroupID}) {
                        fieldsGroup = group
                    }
//                }
            }
        }
        
        let field = Field()
        field.title = title
        field.color = color
        
        if let id = id {
            field.id = id
        }
        
        for initialMarker in initialMarkers {
            let position = Position()
            position.latitude = initialMarker.position.latitude
            position.longitude = initialMarker.position.longitude
            field.polygonMarkersPositions.append(position)
        }
        
        updateTime = Date()
        field.lastUpdateTime = updateTime
        
        do {
            try realm.write({
                realm.add(field)
                fieldsGroup?.fields.append(field)
                if id == nil {
                    saveFieldToCloud(field: field)
                }
            })
        } catch {
            print("Error saving context, \(error)")
        }
        let newPolygon = GMSPolygon()
        newPolygon.title = field.id
        if field.parentGroup.first?.id != grouplessGroupID {
            if let parentGroup = field.parentGroup.first {
                newPolygon.fillColor = UIColor(hexString: parentGroup.color)!
            } else {
                newPolygon.fillColor = UIColor(hexString: field.color)!
            }
        } else {
            newPolygon.fillColor = UIColor(hexString: field.color)!
        }
        newPolygon.strokeColor = UIColor.flatBlackDark()
        newPolygon.strokeWidth = 1
        newPolygon.geodesic = isGeodesic
        newPolygon.isTappable = true
        let rect = GMSMutablePath()
        for position in field.polygonMarkersPositions {
            rect.add(CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude))
        }
        newPolygon.path = rect
        polygons.append(newPolygon)
        polygons[polygons.count-1].map = mapView
        loadFieldsAndGroups()
    }
    // MARK: - checkTitleAvailable
    func checkTitleAvailable(title: String, groupTitle: String) -> String {
        var isValidName = true
        var errorMessage = NSLocalizedString("Field needs a title.", comment: "")
        if title.isEmpty {
            isValidName = false
            errorMessage = NSLocalizedString("Field needs a title.", comment: "")
        }
        guard let fields = fields else { return "" }
        for field in fields {
            if field.title == title {
                isValidName = false
                errorMessage = NSLocalizedString("Fields cannot have the same title.", comment: "")
            }
        }
        if isValidName {
            return "done"
        } else {
            return errorMessage
        }
    }
    
    // MARK: - changePolygonsTappableBoolean
    func changePolygonsTappableBoolean(to bool: Bool) {
        for polygon in polygons {
            polygon.isTappable = bool
        }
    }
    // MARK: - setColor
    func setColor(colorHex: String, field: Field) {
        if let polygon = polygons.first(where: {$0.title == field.id}), let color = UIColor(hexString: colorHex) {
            selectedPolygon = polygon
            polygon.map = nil
            updatedColor = colorHex
            polygon.fillColor = color
            polygon.map = mapView
        }
    }
    // MARK: - saveColor
    func saveColor(field: Field, color: String) {
        do {
            try realm.write({
                field.color = color
            })
        } catch {
            print("Error saving context, \(error)")
        }
    }
    // MARK: - setAreaAndCircumference
    func setAreaAndCircumference() {
        updatedArea = GMSGeometryArea((selectedPolygon.path!))
        updatedCircumference = GMSGeometryLength((selectedPolygon.path!)) + GMSGeometryDistance((selectedPolygon.path?.coordinate(at: 0))!,
                                                                                                (selectedPolygon.path?.coordinate(at: (selectedPolygon.path?.count())!-1))!)
    }
    // MARK: - saveFieldToDB
    func saveFieldToDB() {
        updateTime = Date()
        do {
            try realm.write({
                selectedField.color = updatedColor
                selectedField.area = updatedArea
                selectedField.circumference = updatedCircumference
                selectedField.lastUpdateTime = updateTime
                selectedField.polygonMarkersPositions.removeAll()
                for marker in selectedFieldMarkers {
                    let position = Position()
                    position.latitude = marker.position.latitude
                    position.longitude = marker.position.longitude
                    selectedField.polygonMarkersPositions.append(position)
                }
            })
        } catch {
            print("Error saving context, \(error)")
        }
    }
    
    // MARK: - deleteSelectedFieldFromDB +
    func deleteFieldFromDB(field: Field) {
        if let polygon = polygons.first(where: {$0.title == field.id}) {
            // Delete photos ?????
            
            polygons[polygons.firstIndex(of: polygon)!].map = nil
            polygon.map = nil
            polygons.remove(at: polygons.firstIndex(of: polygon)!)
            
            let infoView = InfoViewController()
            field.photos.forEach { (photoID) in
                let isDeleted = infoView.deleteImage(id: photoID)
                if isDeleted {
                    print("image Deleted")
                }
            }
            
            // realm.delete(realm.objects(Field.self).filter("id=%@",field.id))
            // if let fieldToDelete = realm.object(ofType: Field.self, forPrimaryKey: field.id) {
                do {
                    try self.realm.write {
                        field.parentGroup.first?.fields.remove(at: (field.parentGroup.first?.fields.index(of: field)!)!)
                        self.realm.delete(field)
                        
                    }
                } catch {
                    print("Error Deleting field, \(error)")
                }
            // }
        }
        
        if field == selectedField && !selectedFieldMarkers.isEmpty {
            for marker in selectedFieldMarkers {
                marker.map = nil
            }
            setHideSelectedFieldLengthMarkers(mapView: nil, remove: false)
        }
        
    }
    
    // MARK: - loadFields with groupTitle
    func loadFields(with groupTitle: String) {
        fields = realm.objects(Field.self).filter("ANY parentGroup.title = %@", groupTitle)
    }
    // MARK: - changeFieldTitle +
    func changeFieldTitle(field: Field, title: String) {
        do {
            try self.realm.write({
                field.title = title
            })
        } catch {
            print("Error chancing field's title, \(error)")
        }
    }
    // MARK: - addNewGroup +
    func addNewGroup(newGroup: Group) {
        do {
            try self.realm.write({
                realm.add(newGroup)
            })
        } catch {
            print("Error Changing Group Title, \(error)")
        }
    }
    // MARK: - changeGroupColor +
    func changeGroupColor(group: Group, color: String) {
        updatedColor = color
        do {
            try self.realm.write({
                group.color = color
                for field in group.fields {
                    field.color = color
                    if let polygon = polygons.first(where: {$0.title == field.id}) { polygon.fillColor = UIColor(hexString: color) }
                }
            })
        } catch {
            print("Error Changing Group Title, \(error)")
        }
    }
    // MARK: - changeGroupTitle +
    func changeGroupTitle(group: Group, title: String) {
        do {
            try self.realm.write({
                group.title = title
            })
        } catch {
            print("Error Changing Group Title, \(error)")
        }
    }
    // MARK: - changeFieldGroup +
    func changeFieldGroup(field: Field, oldGroup: Group, newGroup: Group, polygon: GMSPolygon) {
        do {
            try self.realm.write {
                newGroup.fields.append(field)
                oldGroup.fields.remove(at: oldGroup.fields.index(of: field)!)
                field.color = newGroup.color
            }
        } catch {
            print("Error Changing Field's Group, \(error)")
        }
        polygon.map = nil
        polygon.fillColor = UIColor(hexString: newGroup.color)
        polygon.map = mapView
    }
    // MARK: - deleteGroupFromDB +
    func deleteGroupFromDB(group: Group) {
        if let groupToDelete = realm.object(ofType: Group.self, forPrimaryKey: group.id) {
            do {
                try self.realm.write {
                    self.realm.delete(groupToDelete)
                }
            } catch {
                print("Error Deleting field, \(error)")
            }
        }
    }
    
    // MARK: - FIREBASE
    
    // MARK: - saveFieldToCloud
    func saveFieldToCloud(field: Field) {
        if let user = user {
            var positions = [[String: Any]]()
            
            for position in field.polygonMarkersPositions {
                positions.append(position.dictionaryWithValues(forKeys: ["latitude", "longitude"]))
            }
            
            var photos = [[String: Any]]()
            
            for photo in field.photos {
                photos.append([photo: ""])
            }
            
            let fieldGroup = field.parentGroup.first!
            
            db.collection(userDefaults!.first!.bossID).document("Fields").collection("Fields").document(field.id).setData([field.id: field.dictionaryWithValues(forKeys: ["title", "color", "area", "circumference"]), "positions": positions, "photos": photos, "group": fieldGroup.id]) { [self] err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    // print("Document successfully written!")
                    db.collection(userDefaults!.first!.bossID).document("Fields").setData(["updatedBy": user.uid, field.id: self.updateTime], merge: true)
                }
            }
        }
    }
    // MARK: - saveGroupToCloud
    func saveGroupToCloud(group: Group) {
        if let user = user {
            db.collection(userDefaults!.first!.bossID).document("Groups").collection("Groups").document(group.id).setData(["updatedBy": user.uid, group.id: group.dictionaryWithValues(forKeys: ["title", "color"])]) { [self] err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    // print("Document successfully written!")
                    db.collection(userDefaults!.first!.bossID).document("Groups").setData(["updatedBy": user.uid, group.id: self.updateTime], merge: true)
                }
            }
        }
    }
    // MARK: - changeFieldGroupAtCloud
    func changeFieldGroupAtCloud(field: Field, newGroup: Group) {
        if let user = user {
            db.collection(userDefaults!.first!.bossID).document("Fields").collection("Fields").document(field.id).setData(["updatedBy": user.uid, "group": newGroup.id], merge: true)
        }
    }
    // MARK: - changeFieldTitleAtCloud
    func changeFieldTitleAtCloud(field: Field, title: String) {
        if let user = user {
            db.collection(userDefaults!.first!.bossID).document("Fields").collection("Fields").document(field.id).setData(["updatedBy": user.uid, field.id: field.dictionaryWithValues(forKeys: ["title"])], merge: true)
        }
    }
    // MARK: - deleteFieldFromCloud
    func deleteFieldFromCloud(field: Field) {
        if userDefaults?.first?.accountType == K.invites.accountTypes.proAccount {
            self.db.collection(userDefaults!.first!.bossID).document("Fields").collection("Fields").document(field.id).delete()
            self.db.collection(userDefaults!.first!.bossID).document("Fields").updateData([field.id: FieldValue.delete()])
        }
    }
    // MARK: - deleteGroupFromCloud
    func deleteGroupFromCloud(group: Group) {
        if userDefaults?.first?.accountType == K.invites.accountTypes.proAccount {
            self.db.collection(userDefaults!.first!.bossID).document("Groups").collection("Groups").document(group.id).delete()
            self.db.collection(userDefaults!.first!.bossID).document("Groups").updateData([group.id: FieldValue.delete()])
        }
    }
    // MARK: - changeGroupTitleAtCloud
    func changeGroupTitleAtCloud(group: Group, title: String) {
        if let user = user {
            self.db.collection(userDefaults!.first!.bossID).document("Groups").collection("Groups").document(group.id).setData(["updatedBy": user.uid, group.id: group.dictionaryWithValues(forKeys: ["title"])], merge: true)
            self.db.collection(userDefaults!.first!.bossID).document("Groups").setData(["updatedBy": user.uid, group.id: updateTime], merge: true)
        }
    }
    // MARK: - changeGroupColorAtCloud
    func changeGroupColorAtCloud(group: Group, color: String) {
        if let user = user {
            self.db.collection(userDefaults!.first!.bossID).document("Groups").collection("Groups").document(group.id).setData(["updatedBy": user.uid, group.id: group.dictionaryWithValues(forKeys: ["color"])], merge: true)
            self.db.collection(userDefaults!.first!.bossID).document("Groups").setData(["updatedBy": user.uid, group.id: updateTime], merge: true)
        }
    }
    
    // MARK: - listenGroupsDocuments
    func listenGroupsDocuments(mapView: GMSMapView) {
        if let user = user {
            self.db.collection(userDefaults!.first!.bossID).document("Groups").collection("Groups").addSnapshotListener { [self] querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                if realm.object(ofType: Group.self, forPrimaryKey: grouplessGroupID) == nil {
                    
                    let grouplessGroup = Group()
                    grouplessGroup.title = NSLocalizedString("Groupless Group", comment: "")
                    grouplessGroup.color = UIColor.flatLime().hexValue()
                    grouplessGroup.id = "703A9A36-8F4C-436A-A834-7E2C08C5917F"
                    do {
                        try realm.write({
                            realm.add(grouplessGroup)
                        })
                    } catch {
                        print("Error saving context, \(error)")
                    }
                    groups = realm.objects(Group.self)
                    // grouplessGroupID = grouplessGroup.id
                    saveGroupToCloud(group: grouplessGroup)
                }
                snapshot.documentChanges.forEach { diff in
                    /*if let groupData = diff.document.data()[diff.document.documentID] as? [String:Any] {
                        if let groupTitle = groupData["title"] as? String {
                            if groupTitle == NSLocalizedString("Groupless Group", comment: "") {
                                self.grouplessGroupID = diff.document.documentID
                            }
                        }
                    }*/
                    // MARK: - added
                    if diff.type == .added {
                        // print("New group: \(diff.document.data())")
                        // print(diff.document.documentID)
                        if realm.object(ofType: Group.self, forPrimaryKey: diff.document.documentID) != nil {
                        } else {
                            // if diff.document.data()["updatedBy"] as? String != user.uid {
                                if diff.document.documentID != grouplessGroupID {
                                    let group = Group()
                                    group.id = diff.document.documentID
                                    // print(diff.document.data())
                                    if let groupData = diff.document.data()[diff.document.documentID] as? [String: Any] {
                                        if let title = groupData["title"] as? String, let color = groupData["color"] as? String {
                                            group.title = title
                                            group.color = color
                                        }
                                    }
                                    do {
                                        try realm.write({
                                            realm.add(group)
                                        })
                                    } catch {
                                        print("Error saving context, \(error)")
                                    }
                                }
                            // }
                        }
                    }
                    // MARK: - modified
                    if diff.type == .modified {
                        // print("Modified group: \(diff.document.data())")
                        if let specificGroup = realm.object(ofType: Group.self, forPrimaryKey: diff.document.documentID) {
                            if diff.document.data()["updatedBy"] as? String != user.uid {
                                if diff.document.documentID != grouplessGroupID {
                                    var color1: String?
                                    if let groupData = diff.document.data()[diff.document.documentID] as? [String: Any] {
                                        if let title = groupData["title"] as? String, let color = groupData["color"] as? String {
                                            print("title")
                                            do {
                                                try realm.write({
                                                    if specificGroup.title != title {
                                                        specificGroup.title = title
                                                    }
                                                    if specificGroup.color != color {
                                                        specificGroup.color = color
                                                        color1 = color
                                                    }
                                                })
                                            } catch {
                                                print("Error saving context, \(error)")
                                            }
                                        }
                                        if let color = color1 {
                                            if specificGroup.id != grouplessGroupID {
                                                changeGroupColor(group: specificGroup, color: color)
                                                print("changeGroupColor")
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            
                        }
                    }
                    // MARK: - removed
                    if diff.type == .removed {
                        // print("Removed group: \(diff.document.data())")
                        if let specificGroup = realm.object(ofType: Group.self, forPrimaryKey: diff.document.documentID) {
                            deleteGroupFromDB(group: specificGroup)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - listenFieldDocuments
    func listenFieldDocuments(mapView: GMSMapView) {
        if let user = user {
            self.db.collection(userDefaults!.first!.bossID).document("Fields").collection("Fields").addSnapshotListener { [self] querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                snapshot.documentChanges.forEach { diff in
                    // MARK: - added
                    if diff.type == .added {
                        // print("New field: \(diff.document.data())")
                        // print(grouplessGroupID)
                        // print(diff.document.documentID)
                        if realm.object(ofType: Field.self, forPrimaryKey: diff.document.documentID) != nil {
                        } else {
                            // if diff.document.data()["updatedBy"] as? String != user.uid {
                                var markers = [GMSMarker]()
                                if let positions = diff.document.data()["positions"] as? [[String: Any]] {
                                    for position in positions {
                                        if let lat = position["latitude"] as? Double, let lon = position["longitude"] as? Double {
                                            let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                                            markers.append(marker)
                                        }
                                    }
                                }
                                if let fieldData = diff.document.data()[diff.document.documentID] as? [String: Any] {
                                    if let title = fieldData["title"] as? String, let color = fieldData["color"] as? String, let groupID = diff.document.data()["group"] as? String {
                                        
                                        let docRef = db.collection(userDefaults!.first!.bossID).document("Groups").collection("Groups").document(groupID)

                                        docRef.getDocument { (document, _) in
                                            if let document = document, document.exists {
                                                if let groupArray = document[groupID] as? [String: Any] {
                                                    if let groupTitle = groupArray["title"] as? String {
                                                        addField(title: title, groupTitle: groupTitle, color: color, initialMarkers: markers, id: diff.document.documentID, isGeodesic: isGeodesic)
                                                    }
                                                }
                                            } else {
                                                print("Document does not exist---")
                                            }
                                        }
                                    }
                                }
                            // }
                        }
                    }
                    // MARK: - modified
                    if diff.type == .modified {
                        // print("Modified field: \(diff.document.data())")
                        if let specificField = realm.object(ofType: Field.self, forPrimaryKey: diff.document.documentID) {
                            if selectedField == specificField && selectedFieldMarkers.count != 0 {
                                let nc = NotificationCenter.default
                                nc.post(name: Notification.Name("EndEditing"), object: nil)
                            }
                            if diff.document.data()["updatedBy"] as? String != user.uid {
                                if let fieldData = diff.document.data()[diff.document.documentID] as? [String: Any] {
                                    if let title = fieldData["title"] as? String, let color = fieldData["color"] as? String {
                                        do {
                                            try realm.write({
                                                if specificField.title != title {
                                                    specificField.title = title
                                                }
                                                if let polygon = polygons.first(where: {$0.title == specificField.id}) {
                                                    specificField.color = color
                                                    polygon.fillColor = UIColor(hexString: color) ?? UIColor.flatBlackDark()
                                                }
                                            })
                                        } catch {
                                            print("Error saving context, \(error)")
                                        }
                                    }
                                    if let groupID = diff.document.data()["group"] as? String {
                                        if groupID != specificField.parentGroup.first!.id {
                                            if let newGroup = groups!.first(where: {$0.id == groupID}) {
                                                if let polygon = polygons.first(where: {$0.title == specificField.id}) {
                                                    changeFieldGroup(field: specificField, oldGroup: specificField.parentGroup.first!, newGroup: newGroup, polygon: polygon)
                                                    setColor(colorHex: newGroup.color, field: specificField)
                                                    saveColor(field: specificField, color: newGroup.color)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                if let positions = diff.document.data()["positions"] as? [[String: Double]] {
                                    do {
                                        try realm.write({
                                            specificField.polygonMarkersPositions.removeAll()
                                            for position in positions {
                                                if let lat = position["latitude"], let lon = position["longitude"] {
                                                    let fieldPosition = Position()
                                                    fieldPosition.latitude = lat
                                                    fieldPosition.longitude = lon
                                                    specificField.polygonMarkersPositions.append(fieldPosition)
                                                }
                                            }
                                            if let polygon = polygons.first(where: {$0.title == specificField.id}) {
                                                updatePolygon(field: specificField, polygon: polygon, mapView: mapView)
                                            }
                                            
                                        })
                                    } catch {
                                        print("Error saving context, \(error)")
                                    }
                                }
                            }
                        }
                    }
                    // MARK: - removed
                    if diff.type == .removed {
                        // print("Removed field: \(diff.document.data())")
                        if let specificField = realm.object(ofType: Field.self, forPrimaryKey: diff.document.documentID) {
                            if selectedField != specificField {
                                deleteFieldFromDB(field: specificField)
                            } else {
                                if selectedFieldMarkers.count == 0 {
                                    deleteFieldFromDB(field: specificField)
                                } else {
                                    let nc = NotificationCenter.default
                                    nc.post(name: Notification.Name("EndEditing"), object: nil)
                                    deleteFieldFromDB(field: specificField)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    // MARK: - updatePolygon
    func updatePolygon(field: Field, polygon: GMSPolygon, mapView: GMSMapView) {
        let path = GMSMutablePath()
        for position in field.polygonMarkersPositions {
            path.add(CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude))
        }
        polygon.map = nil
        polygon.path = path
        polygon.map = mapView
    }
    
    // MARK: - LENGTH MARKERS
    
    // MARK: - arrangeSelectedFieldLengthMarker
    func arrangeSelectedFieldLengthMarker(i: Int, inside: Bool, add: Bool, isMetric: Bool, distanceUnit: Int) {
        let secondIndex = i
        
        var firstIndex: Int {
            get {
                if secondIndex != 0 {
                    return i - 1
                } else {
                    return selectedFieldMarkers.count - 1
                }
            }
        }
        
        var thirdIndex: Int {
            get {
                if secondIndex != selectedFieldMarkers.count - 1 {
                    return i + 1
                } else {
                    return 0
                }
            }
        }
        
        if inside {
            let tempMarker = GMSMarker(position: GMSUnproject( GMSMapPointInterpolate(GMSProject((selectedFieldMarkers[firstIndex].position)), GMSProject((selectedFieldMarkers[secondIndex].position)), 0.5)))
            let tempLength = GMSGeometryDistance(selectedFieldMarkers[firstIndex].position, selectedFieldMarkers[secondIndex].position)
            tempMarker.groundAnchor = .init(x: 0.5, y: 0.5)
            tempMarker.isTappable = false
            tempMarker.title = "lengthMarker"
            tempMarker.iconView = UIImage.makeIconView(iconSize: 50, length: tempLength, isMetric: isMetric, distanceUnit: distanceUnit, isTappable: tempMarker.isTappable)
            
            if add {
                if firstIndex != selectedFieldLengthMarkers.count {
                    selectedFieldLengthMarkers[firstIndex].map = nil
                    selectedFieldLengthMarkers.remove(at: firstIndex)
                    
                    selectedFieldLengthMarkers.insert(tempMarker, at: firstIndex)
                } else {
                    selectedFieldLengthMarkers[firstIndex-1].map = nil
                    selectedFieldLengthMarkers.remove(at: firstIndex-1)
                    
                    selectedFieldLengthMarkers.insert(tempMarker, at: firstIndex-1)
                }
                tempMarker.map = mapView
            } else {
                selectedFieldLengthMarkers[firstIndex].position = tempMarker.position
                selectedFieldLengthMarkers[firstIndex].iconView = tempMarker.iconView
            }
            let tempMarker1 = GMSMarker(position: GMSUnproject( GMSMapPointInterpolate(GMSProject((selectedFieldMarkers[secondIndex].position)), GMSProject((selectedFieldMarkers[thirdIndex].position)), 0.5)))
            let tempLength1 = GMSGeometryDistance(selectedFieldMarkers[secondIndex].position, selectedFieldMarkers[thirdIndex].position)
            tempMarker1.groundAnchor = .init(x: 0.5, y: 0.5)
            tempMarker1.isTappable = false
            tempMarker1.title = "lengthMarker"
            tempMarker1.iconView = UIImage.makeIconView(iconSize: 50, length: tempLength1, isMetric: isMetric, distanceUnit: distanceUnit, isTappable: tempMarker1.isTappable)
            
            if add {
                selectedFieldLengthMarkers.insert(tempMarker1, at: secondIndex)
                tempMarker1.map = mapView
            } else {
                selectedFieldLengthMarkers[secondIndex].position = tempMarker1.position
                selectedFieldLengthMarkers[secondIndex].iconView = tempMarker1.iconView
            }
        }
    }
    // MARK: - setSelectedFieldLengthMarkers
    func setSelectedFieldLengthMarkers(isMetric: Bool, distanceUnit: Int) {
        for i in 0...selectedFieldMarkers.count-1 {
            let firstIndex = i
            var secondIndex = i+1
            if i == selectedFieldMarkers.count-1 {
                secondIndex = 0
            }
            let tempMarker = GMSMarker(position: GMSUnproject( GMSMapPointInterpolate(GMSProject((selectedFieldMarkers[firstIndex].position)),
                                                                                      GMSProject((selectedFieldMarkers[secondIndex].position)), 0.5)))
            let tempLength = GMSGeometryDistance(selectedFieldMarkers[firstIndex].position, selectedFieldMarkers[secondIndex].position)
            tempMarker.groundAnchor = .init(x: 0.5, y: 0.5)
            tempMarker.isTappable = false
            tempMarker.title = "lengthMarker"
            tempMarker.iconView = UIImage.makeIconView(iconSize: 50, length: tempLength, isMetric: isMetric, distanceUnit: distanceUnit, isTappable: tempMarker.isTappable)
            
            selectedFieldLengthMarkers.append(tempMarker)
        }
    }
    // MARK: - setHideSelectedFieldLengthMarkers
    func setHideSelectedFieldLengthMarkers(mapView: GMSMapView?, remove: Bool) {
        for marker in selectedFieldLengthMarkers {
            marker.map = mapView
        }
        if mapView == nil && remove {
            selectedFieldLengthMarkers.removeAll()
        }
    }
    // MARK: - deleteSelectedFieldLengthMarker
    func deleteSelectedFieldLengthMarker(index: Int, isMetric: Bool, distanceUnit: Int) {
        var firstIndex = index
        var secondIndex = index
        if index == 0 {
            firstIndex = index
            secondIndex = selectedFieldLengthMarkers.count-2
            selectedFieldLengthMarkers.removeFirst().map = nil
        } else if index == selectedFieldLengthMarkers.count-1 {
            firstIndex = 0
            secondIndex = index-1
            selectedFieldLengthMarkers.popLast()?.map = nil
        } else {
            firstIndex = index
            secondIndex = index-1
            selectedFieldLengthMarkers.remove(at: firstIndex).map = nil
        }
        
        let tempMarker1 = GMSMarker(position: GMSUnproject( GMSMapPointInterpolate(GMSProject((selectedFieldMarkers[firstIndex].position)), GMSProject((selectedFieldMarkers[secondIndex].position)), 0.5)))
        let tempLength1 = GMSGeometryDistance(selectedFieldMarkers[firstIndex].position, selectedFieldMarkers[secondIndex].position)
        
        tempMarker1.groundAnchor = .init(x: 0.5, y: 0.5)
        tempMarker1.isTappable = false
        tempMarker1.title = "lengthMarker"
        
        tempMarker1.iconView = UIImage.makeIconView(iconSize: 50, length: tempLength1, isMetric: isMetric, distanceUnit: distanceUnit, isTappable: tempMarker1.isTappable)
        
        selectedFieldLengthMarkers[secondIndex].position = tempMarker1.position
        selectedFieldLengthMarkers[secondIndex].iconView = tempMarker1.iconView
    }
    
    private var index = 0
    
    // MARK: - setEditableSelectedLineLengthMarker
    func setEditableSelectedFieldLengthMarker(index: Int) {
        for marker in selectedFieldLengthMarkers {
            marker.isDraggable = false
            marker.isTappable = false
            
            let tempView = marker.iconView
            tempView?.layer.borderWidth = 0
            tempView?.layer.borderColor = UIColor.systemBlue.cgColor
            marker.iconView = tempView
        }
        if index != 0 {
            selectedFieldLengthMarkers[index].isTappable = true
            selectedFieldLengthMarkers[index-1].isTappable = true
            
            var tempView = selectedFieldLengthMarkers[index].iconView
            tempView?.layer.borderWidth = 1
            tempView?.layer.borderColor = UIColor.systemBlue.cgColor
            selectedFieldLengthMarkers[index].iconView = tempView
            
            tempView = selectedFieldLengthMarkers[index-1].iconView
            tempView?.layer.borderWidth = 1
            tempView?.layer.borderColor = UIColor.systemBlue.cgColor
            selectedFieldLengthMarkers[index-1].iconView = tempView
        } else {
            selectedFieldLengthMarkers[index].isTappable = true
            selectedFieldLengthMarkers[selectedFieldLengthMarkers.count-1].isTappable = true
            
            var tempView = selectedFieldLengthMarkers[index].iconView
            tempView?.layer.borderWidth = 1
            tempView?.layer.borderColor = UIColor.systemBlue.cgColor
            selectedFieldLengthMarkers[index].iconView = tempView
            
            tempView = selectedFieldLengthMarkers[selectedFieldLengthMarkers.count-1].iconView
            tempView?.layer.borderWidth = 1
            tempView?.layer.borderColor = UIColor.systemBlue.cgColor
            selectedFieldLengthMarkers[selectedFieldLengthMarkers.count-1].iconView = tempView
        }
        
        self.index = index
    }
    // MARK: - setEdgeLength
    func setEdgeLength(lengthMarkerIndex: Int, edgeLength: Double) -> GMSMarker? {
        
        if index != 0 && index != selectedFieldMarkers.count-1 {
            if lengthMarkerIndex == index {
                let oldLength = GMSGeometryDistance(selectedFieldMarkers[index].position, selectedFieldMarkers[index + 1].position)
                let a = edgeLength / oldLength
                let newPosition = GMSGeometryInterpolate(selectedFieldMarkers[index].position, selectedFieldMarkers[index + 1].position, a)
                selectedFieldMarkers[index + 1].position = newPosition
                return selectedFieldMarkers[index + 1]
            } else {
                let oldLength = GMSGeometryDistance(selectedFieldMarkers[index].position, selectedFieldMarkers[index - 1].position)
                let a = edgeLength / oldLength
                let newPosition = GMSGeometryInterpolate(selectedFieldMarkers[index].position, selectedFieldMarkers[index - 1].position, a)
                selectedFieldMarkers[index - 1].position = newPosition
                return selectedFieldMarkers[index - 1]
            }
        } else if index == 0 {
            if lengthMarkerIndex == index {
                let oldLength = GMSGeometryDistance(selectedFieldMarkers[index].position, selectedFieldMarkers[index + 1].position)
                let a = edgeLength / oldLength
                let newPosition = GMSGeometryInterpolate(selectedFieldMarkers[index].position, selectedFieldMarkers[index + 1].position, a)
                selectedFieldMarkers[index + 1].position = newPosition
                return selectedFieldMarkers[index + 1]
            } else {
                let oldLength = GMSGeometryDistance(selectedFieldMarkers[index].position, selectedFieldMarkers[selectedFieldMarkers.count - 1].position)
                let a = edgeLength / oldLength
                let newPosition = GMSGeometryInterpolate(selectedFieldMarkers[index].position, selectedFieldMarkers[selectedFieldMarkers.count - 1].position, a)
                selectedFieldMarkers[selectedFieldMarkers.count - 1].position = newPosition
                return selectedFieldMarkers[selectedFieldMarkers.count - 1]
            }
        } else {
            if lengthMarkerIndex == index {
                let oldLength = GMSGeometryDistance(selectedFieldMarkers[index].position, selectedFieldMarkers[0].position)
                let a = edgeLength / oldLength
                let newPosition = GMSGeometryInterpolate(selectedFieldMarkers[index].position, selectedFieldMarkers[0].position, a)
                selectedFieldMarkers[0].position = newPosition
                return selectedFieldMarkers[0]
            } else {
                let oldLength = GMSGeometryDistance(selectedFieldMarkers[index].position, selectedFieldMarkers[index - 1].position)
                let a = edgeLength / oldLength
                let newPosition = GMSGeometryInterpolate(selectedFieldMarkers[index].position, selectedFieldMarkers[index - 1].position, a)
                selectedFieldMarkers[index - 1].position = newPosition
                return selectedFieldMarkers[index - 1]
            }
        }
    }
}
