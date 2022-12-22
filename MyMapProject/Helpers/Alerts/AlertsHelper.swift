//
//  AlertsHelper.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 1.04.2021.
//  Copyright © 2021 Enes Kılıç. All rights reserved.
//

import UIKit
import CoreLocation

class AlertsHelper: BaseAlertHelper {
    
    static func showLimitReachedAlert(on vc: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
            vc.navigationController?.popToRootViewController(animated: true)
            nc.post(name: Notification.Name("openPremiumViewController"), object: nil)
        }))
        DispatchQueue.main.async {
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    static func addingExtraFieldAlert(on vc: UIViewController) {
        showLimitReachedAlert(on: vc, title: NSLocalizedString("Oops!", comment: ""), message: NSLocalizedString("You have reached the free account field adding limit. To subscribe and get rid of this error, press OK.", comment: ""))
    }
    
    static func addingExtraLineAlert(on vc: UIViewController) {
        showLimitReachedAlert(on: vc, title: NSLocalizedString("Oops!", comment: ""), message: NSLocalizedString("You have reached the free account line adding limit. To subscribe and get rid of this error, press OK.", comment: ""))
    }
    
    static func addingExtraPlaceAlert(on vc: UIViewController) {
        showLimitReachedAlert(on: vc, title: NSLocalizedString("Oops!", comment: ""), message: NSLocalizedString("You have reached the free account place adding limit. To subscribe and get rid of this error, press OK.", comment: ""))
    }
    
    static func addingExtraToDoItemAlert(on vc: UIViewController) {
        showLimitReachedAlert(on: vc, title: NSLocalizedString("Oops!", comment: ""), message: NSLocalizedString("You have reached the free account item adding limit. To subscribe and get rid of this error, press OK.", comment: ""))
    }
    
    static func addingExtraPhotoAlert(on vc: UIViewController) {
        showLimitReachedAlert(on: vc, title: NSLocalizedString("Oops!", comment: ""), message: NSLocalizedString("You have reached the free account photo limit. To subscribe and get rid of this error, press OK.", comment: ""))
    }
    
    static func savingPhotoAlert(on vc: UIViewController) {
        showLimitReachedAlert(on: vc, title: NSLocalizedString("Oops!", comment: ""), message: NSLocalizedString("An error happend while deleting the image.", comment: ""))
    }
    
    static func thereIsNoPhotoAlert(on vc: UIViewController) {
        showLimitReachedAlert(on: vc, title: NSLocalizedString("Oops!", comment: "There is no image to delete"), message: NSLocalizedString("", comment: ""))
    }
    
    static func adsAlert(on vc: UIViewController) {
        showBasicAlertWithAction(on: vc, with: NSLocalizedString("Bored with ads?", comment: ""), message: NSLocalizedString("Get Maps To Do Pro account, get rid of ads and limitations.", comment: "")) {
            
            vc.navigationController?.popToRootViewController(animated: true)
            nc.post(name: Notification.Name("openPremiumViewController"), object: nil)
            
        }
    }
    
    static func didTapMarkerAlert(on vc: UIViewController, placeholderTitle: String, unitLength: UnitLength, okAction: @escaping (_ length: Double, _ unitLength: UnitLength) -> Void) {
        
        let ac = UIAlertController(title: NSLocalizedString("Enter Length", comment: ""), message: NSLocalizedString("The selected point will stay fixed and the edge will be extended.", comment: ""), preferredStyle: .alert)
        ac.addTextField()
        guard let textFields = ac.textFields else { return }
        textFields[0].keyboardType = .decimalPad
        textFields[0].placeholder = placeholderTitle
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .destructive)
        let submitAction = UIAlertAction(title: NSLocalizedString("Submit", comment: ""), style: .default) { _ in
            if let length = Double(textFields[0].text!) {
                okAction(length, unitLength)
            }
        }
        ac.addAction(cancelAction)
        ac.addAction(submitAction)
        vc.present(ac, animated: true)
    }
    
    static func moveCornerAlert(on vc: UIViewController, position: CLLocationCoordinate2D, okAction: @escaping (_ newPosition: CLLocationCoordinate2D) -> Void) {
        let alert = UIAlertController(title: NSLocalizedString("Enter Coordinates", comment: ""),
                                      message: "",
                                      preferredStyle: .alert)
        alert.addTextField()
        guard let latTextField = alert.textFields?[0] else { return }
        latTextField.keyboardType = .decimalPad
        latTextField.text = String(format: "%.4f",
                                   position.latitude)
        latTextField.clearButtonMode = .always
        latTextField.borderStyle = .roundedRect
        
        let latLabel = UILabel(frame: CGRect(x: 0,
                                             y: 0,
                                             width: 20,
                                             height: 20))
        latLabel.text = NSLocalizedString("Lat",
                                          comment: "")
        
        latTextField.leftView = latLabel
        latTextField.leftViewMode = .always
        latTextField.leftViewRect(forBounds: CGRect(x: latTextField.bounds.midX, y: latTextField.bounds.midY, width: 0, height: 0))
        
        alert.addTextField()
        guard let lonTextField = alert.textFields?[1] else { return }
        
        lonTextField.keyboardType = .decimalPad
        lonTextField.text = String(format: "%.4f", position.longitude)
        lonTextField.clearButtonMode = .always
        lonTextField.borderStyle = .roundedRect
        
        let lonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        
        lonLabel.text = NSLocalizedString("Lon", comment: "")
        lonTextField.leftView = lonLabel
        lonTextField.leftViewMode = .always
        lonTextField.leftViewRect(forBounds: CGRect(x: lonTextField.bounds.midX, y: lonTextField.bounds.midY, width: 0, height: 0))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Submit", comment: ""), style: .default, handler: { (uiAlertAction) in
            if let latText = latTextField.text, let lonText = lonTextField.text {
                if let latitude = Double(latText), let longitude = Double(lonText) {
                    okAction(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                }
            }
        }))
        vc.present(alert, animated: true, completion: nil)
    }
    
    static func deleteAlert(on vc: UIViewController, with dataType: DataTypes, overlayTitle: String?, deleteAction: @escaping () -> Void) {
        var message = ""
        var title = String(format: NSLocalizedString("Delete %@", comment: ""), overlayTitle ?? "")
        switch dataType {
        case .field:
            message = NSLocalizedString("Field's overlay, to-do items and photos will be deleted.", comment: "")
        case .line:
            message = NSLocalizedString("Line's overlay, to-do items and photos will be deleted.", comment: "")
        case .place:
            message = NSLocalizedString("Place's overlay, to-do items and photos will be deleted.", comment: "")
        case .group:
            message = K.deleteGroupWithAllFields
        case .item:
            message = NSLocalizedString("Item will be deleted.", comment: "")
        case .image:
            title = NSLocalizedString("Delete this image", comment: "")
        }
        
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive, handler: { _ in
            deleteAction()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        vc.present(alert, animated: true, completion: nil)
    }
    
    static func overlayActionSheet(on vc: UIViewController, overlayTitle: String, editOverlayAction: @escaping (() -> Void), editItemsAction: @escaping () -> Void, infoPageAction: @escaping () -> Void) {
        let alert = UIAlertController(title: String(format: NSLocalizedString("For %@", comment: ""), overlayTitle) , message: "", preferredStyle: .actionSheet)
        
        let titleAttributes = [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Bold", size: 25)!, NSAttributedString.Key.foregroundColor: UIColor.black]
        let titleString = NSAttributedString(string: String(format: NSLocalizedString("For %@", comment: ""), overlayTitle), attributes: titleAttributes)
        alert.setValue(titleString, forKey: "attributedTitle")
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Edit overlay", comment: ""), style: .default, handler: { _ in
            editOverlayAction()
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Edit items", comment: ""), style: .default, handler: { _ in
            editItemsAction()
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Open info page", comment: ""), style: .default, handler: { _ in
            infoPageAction()
        }))
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .destructive, handler: nil))
            
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = vc.view //to set the source of your alert
                popoverController.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = [] //to hide the arrow of any particular direction
            }
        }
        vc.present(alert, animated: true, completion: nil)
    }
    
    static func changeTitleAlert(on vc: UIViewController, title: String, overlayType: DataTypes, validNameAction: @escaping (_ newTitle: String) -> Void) {
        var textField = UITextField()
        
        let alert = UIAlertController(title: String(format: NSLocalizedString("Change %@'s Title", comment: ""), title), message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: NSLocalizedString("Change", comment: ""), style: .default) { (action) in
            if let newTitle = textField.text {
                var isValidName = true
                var errorMessage = ""
                if newTitle.count == 0 {
                    isValidName = false
                    switch overlayType {
                    case .field:
                        errorMessage = NSLocalizedString("Field needs a title.", comment: "")
                    case .line:
                        errorMessage = NSLocalizedString("Line needs a title.", comment: "")
                    case .place:
                        errorMessage = NSLocalizedString("Place needs a title.", comment: "")
                    case .group:
                        errorMessage = NSLocalizedString("Group needs a title.", comment: "")
                    case .item:
                        break
                    case .image:
                        break
                    }
                }
                
                if isValidName {
                    validNameAction(newTitle)
                } else {
                    let alert = UIAlertController(title: errorMessage, message: "", preferredStyle: .alert)
                    
                    let editItemsAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel) { (action) in
                        //self.arrowButton.isHidden = false
                    }
                    
                    alert.addAction(editItemsAction)
                    
                    vc.present(alert, animated: true, completion: nil)
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { (action) in
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = NSLocalizedString("New Title", comment: "")
            textField = alertTextField
            alertTextField.delegate = vc as? any UITextFieldDelegate
        }
        
        alert.addAction(action)
        alert.addAction(cancelAction)
        
        vc.present(alert, animated: true, completion: nil)
    }
    
    static func restoreSubscriptionAlert(on vc: UIViewController) {
        showBasicAlert(on: vc,
                       with: NSLocalizedString("Restore Subscription", comment: ""),
                       message: NSLocalizedString("For restoring purpose, any subscription info not found.", comment: ""))
    }
    
    static func changeFieldGroupAlert(on vc: UIViewController, fieldTitle: String, changeAction: @escaping (_ newTitle: String) -> Void) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: String(format: NSLocalizedString("Change %@'s Group", comment: ""), fieldTitle), message: "", preferredStyle: .alert)
       
        let action = UIAlertAction(title: NSLocalizedString("Change", comment: ""), style: .default) { _ in
            if let title = textField.text {
                changeAction(title)
            }
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { (action) in
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = NSLocalizedString("New Group Title", comment: "")
            textField = alertTextField
            alertTextField.delegate = vc as? any UITextFieldDelegate
        }
        
        alert.addAction(action)
        alert.addAction(cancelAction)
       
        vc.present(alert, animated: true, completion: nil)
    }
    
    //MARK: - ToDoAlerts
    
    static func addNewItemAlert(on vc: UIViewController, itemType: TodoItemType, addItemAction: @escaping (_ title: String) -> Void, forAllGroupAction: @escaping (_ title: String) -> Void) {
        var textField = UITextField()
        
        let alert = UIAlertController(title: NSLocalizedString("Add New Item", comment: ""), message: "", preferredStyle: .alert)
        
        var actionTitle = ""
        switch itemType {
        case .groupsItem:
            actionTitle = NSLocalizedString("Add Items as Shared Group Item", comment: "")
        case .fieldsItem:
            actionTitle = NSLocalizedString("Add Field Item", comment: "")
        case .linesItem:
            actionTitle = NSLocalizedString("Add Line Item", comment: "")
        case .placesItem:
            actionTitle = NSLocalizedString("Add Place Item", comment: "")
        }
        
        let action = UIAlertAction(title: actionTitle, style: .default) { (action) in
            if let title = textField.text {
                addItemAction(title)
            }
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = NSLocalizedString("Create new item", comment: "")
            textField = alertTextField
            alertTextField.delegate = vc as? any UITextFieldDelegate
        }
        
        alert.addAction(action)
        
        if itemType == TodoItemType.groupsItem {
            let action1 = UIAlertAction(title: NSLocalizedString("Add Items as Individual Field Item", comment: ""), style: .default) { _ in
                if let title = textField.text {
                    forAllGroupAction(title)
                }
            }
            alert.addAction(action1)
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        vc.present(alert, animated: true, completion: nil)
    }
}
