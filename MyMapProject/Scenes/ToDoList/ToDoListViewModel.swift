//
//  ToDoListViewModel.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 11.11.2022.
//  Copyright © 2022 Enes Kılıç. All rights reserved.
//

import Foundation
import RealmSwift
import Firebase
import FirebaseFirestore

protocol ToDoListViewModelProtocol: AnyObject {
    var viewController: ToDoListViewControllerProtocol? { get set }
    func checkIsToDoItemsCountAtLimit() -> Bool
    func addNewToDoItemsToOverlay(title: String, overlay: Overlay)
    func addToDoItemsForAllGroup(group: Group, title: String)
    func getToDoItemsCount(itemType: TodoItemType) -> Int
    func getItem(for itemType: TodoItemType, with index: Int) -> Item?
    func loadItemsWithGroup(selectedGroup: Group)
    func loadItemsWithField(selectedField: Field)
    func loadItemsWithLine(selectedLine: Line)
    func loadItemsWithPlace(selectedPlace: Place)
    func filterToDoItems(filterText: String)
    func listenItemDocuments(parentID: String, overlay: Overlay)
    func deleteItem(at indexPath: IndexPath, itemType: TodoItemType)
}

class ToDoListViewModel: ToDoListViewModelProtocol {
    
    weak var viewController: ToDoListViewControllerProtocol?
    
    let realm: Realm! = try? Realm()
    private var userDefaults: UserDefaults!
    var todoItems: Results<Item>?
    var groupTodoItems: Results<Item>?
    
    private let db = Firestore.firestore()
    private let user = Auth.auth().currentUser
    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        userDefaults = realm.objects(UserDefaults.self).first
    }
    
    func checkIsToDoItemsCountAtLimit() -> Bool {
        if userDefaults.accountType == K.invites.accountTypes.freeAccount {
            if let itemCount = todoItems?.count, itemCount >= K.FreeAccountLimitations.todoItemLimit {
                return true
            }
        }
        return false
    }
    
    func addNewToDoItemsToOverlay(title: String, overlay: Overlay) {
        do {
            try self.realm.write({
                let newItem = Item()
                newItem.title = title
                newItem.lastUpdateTime = Date()
                overlay.items.append(newItem)
                newItem.parentID = overlay.id
                self.saveItemToCloud(item: newItem)
                self.viewController?.reloadTableViewData()
            })
        } catch {
            print("Error saving new items, \(error)")
        }
    }
    
    func addToDoItemsForAllGroup(group: Group, title: String) {
        for currentField in group.fields {
            addNewToDoItemsToOverlay(title: title, overlay: currentField)
        }
    }
    
    func getToDoItemsCount(itemType: TodoItemType) -> Int {
        switch itemType {
        case .groupsItem:
            return groupTodoItems?.count ?? 1
        case .fieldsItem:
            return (groupTodoItems?.count ?? 0) + (todoItems?.count ?? 0)
        case .linesItem:
            return todoItems?.count ?? 1
        case .placesItem:
            return todoItems?.count ?? 1
        }
    }
    
    func getItem(for itemType: TodoItemType, with index: Int) -> Item? {
        if itemType == .fieldsItem || itemType == .groupsItem {
            if let groupTodoItems = groupTodoItems, index < groupTodoItems.count {
                return groupTodoItems[index]
            } else if let todoItems = todoItems, let groupTodoItems = groupTodoItems {
                return todoItems[index - groupTodoItems.count]
            }
        } else if let todoItems = todoItems {
            return todoItems[index]
        }
        return nil
    }
    
    // MARK: - loadItemsWithGroup
    func loadItemsWithGroup(selectedGroup: Group) {
        groupTodoItems = selectedGroup.items.sorted(byKeyPath: "startDate", ascending: true)
        viewController?.reloadTableViewData()
    }
    // MARK: - loadItemsWithField
    func loadItemsWithField(selectedField: Field) {
        todoItems = selectedField.items.sorted(byKeyPath: "startDate", ascending: true)
        viewController?.reloadTableViewData()
    }
    // MARK: - loadItemsWithLine
    func loadItemsWithLine(selectedLine: Line) {
        todoItems = selectedLine.items.sorted(byKeyPath: "startDate", ascending: true)
        viewController?.reloadTableViewData()
    }
    // MARK: - deleteItem
    func deleteItem(at indexPath: IndexPath, itemType: TodoItemType) {
        if itemType == TodoItemType.fieldsItem || itemType == TodoItemType.groupsItem {
            if indexPath.row < groupTodoItems!.count {
                if let itemForDeletion = self.groupTodoItems?[indexPath.row] {
                    deleteItemFromCloud(item: itemForDeletion)
                    do {
                        try self.realm.write {
                            self.realm.delete(itemForDeletion)
                            viewController?.reloadTableViewData()
                        }
                    } catch {
                        print("Error Deleting item, \(error)")
                    }
                }
            } else {
                if let itemForDeletion = self.todoItems?[indexPath.row - groupTodoItems!.count] {
                    deleteItemFromCloud(item: itemForDeletion)
                    do {
                        try self.realm.write {
                            self.realm.delete(itemForDeletion)
                            viewController?.reloadTableViewData()
                        }
                    } catch {
                        print("Error Deleting item, \(error)")
                    }
                }
            }
        } else {
            if let itemForDeletion = self.todoItems?[indexPath.row] {
                deleteItemFromCloud(item: itemForDeletion)
                do {
                    try self.realm.write {
                        self.realm.delete(itemForDeletion)
                        viewController?.reloadTableViewData()
                    }
                } catch {
                    print("Error Deleting item, \(error)")
                }
            }
        }
    }
    // MARK: - loadItemsWithPlace
    func loadItemsWithPlace(selectedPlace: Place) {
        todoItems = selectedPlace.items.sorted(byKeyPath: "startDate", ascending: true)
        viewController?.reloadTableViewData()
    }
    
    func filterToDoItems(filterText: String) {
        todoItems = todoItems?.filter("title CONTAINS[cd] %@", filterText).sorted(byKeyPath: "startDate", ascending: true)
        viewController?.reloadTableViewData()
    }
    
    // MARK: - saveItemToCloud
    func saveItemToCloud(item: Item) {
        if user != nil {
            db.collection(userDefaults.bossID).document("Items").collection("Items").document(item.id).setData(item.dictionaryWithValues(forKeys: ["title", "startDate", "endDate", "note", "status", "parentID"])) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                    // db.collection(user.uid).document("Items").setData([item.id : self.updateTime], merge: true)
                }
            }
        }
    }
    // MARK: - deleteItemFromCloud
    func deleteItemFromCloud(item: Item) {
        if user != nil {
            self.db.collection(userDefaults.bossID).document("Items").collection("Items").document(item.id).delete()
        }
    }
    // MARK: - listenItemDocuments
    func listenItemDocuments(parentID: String, overlay: Overlay) {
        if user != nil {
            self.db.collection(userDefaults.bossID).document("Items").collection("Items").whereField("parentID", isEqualTo: parentID).addSnapshotListener { [self] querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                snapshot.documentChanges.forEach { diff in
                    if diff.type == .added {
                        print("New item: \(diff.document.data())")
                        // print(diff.document.documentID)
                        if realm.object(ofType: Item.self, forPrimaryKey: diff.document.documentID) != nil {
                        } else {
                            // if diff.document.data()["updatedBy"] as? String != user.uid {
                            let item = Item()
                            item.id = diff.document.documentID
                            let itemData = diff.document.data()
                            if let title = itemData["title"] as? String,
                               let status = itemData["status"] as? Int,
                               let startDate = itemData["startDate"] as? Timestamp,
                               let endDate = itemData["endDate"] as? Timestamp,
                               let note = itemData["note"] as? String {
                                item.title = title
                                item.status = status
                                item.startDate = startDate.dateValue()
                                item.endDate = endDate.dateValue()
                                item.note = note
                            }
                            do {
                                try realm.write({
                                    realm.add(item)
                                    overlay.items.append(item)
                                })
                            } catch {
                                print("Error saving context, \(error)")
                            }
                        }
                        viewController?.reloadTableViewData()
                    }
                    if diff.type == .modified {
                        print("Modified item: \(diff.document.data())")
                        if let specificItem = realm.object(ofType: Item.self, forPrimaryKey: diff.document.documentID) {
                            // if diff.document.data()["updatedBy"] as? String != user.uid {
                            let itemData = diff.document.data()
                            
                            if let title = itemData["title"] as? String,
                               let status = itemData["status"] as? Int,
                               let startDate = itemData["startDate"] as? Timestamp,
                               let endDate = itemData["endDate"] as? Timestamp,
                                let note = itemData["note"] as? String {
                                do {
                                    try realm.write({
                                        if specificItem.title != title {
                                            specificItem.title = title
                                        }
                                        if specificItem.status != status {
                                            specificItem.status = status
                                        }
                                        if specificItem.startDate != startDate.dateValue() {
                                            specificItem.startDate = startDate.dateValue()
                                        }
                                        if specificItem.endDate != endDate.dateValue() {
                                            specificItem.endDate = endDate.dateValue()
                                        }
                                        if specificItem.note != note {
                                            specificItem.note = note
                                        }
                                    })
                                } catch {
                                    print("Error saving context, \(error)")
                                }
                            }
                            viewController?.reloadTableViewData()
                        } else {
                            
                        }
                    }
                    if diff.type == .removed {
                        print("Removed item: \(diff.document.data())")
                        if let specificItem = realm.object(ofType: Item.self, forPrimaryKey: diff.document.documentID) {
                            do {
                                try self.realm.write {
                                    self.realm.delete(specificItem)
                                }
                            } catch {
                                print("Error Deleting item, \(error)")
                            }
                        }
                        viewController?.reloadTableViewData()
                    }
                }
            }
        }
    }
}
