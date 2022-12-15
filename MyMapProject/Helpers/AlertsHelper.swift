//
//  AlertsHelper.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 1.04.2021.
//  Copyright © 2021 Enes Kılıç. All rights reserved.
//

import UIKit
import CoreLocation

struct AlertsHelper {
    
    static let nc = NotificationCenter.default
    
    private static func showBasicAlertWithAction(on vc: UIViewController, with title: String, message: String,  okAction: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
            okAction()
        }))
        DispatchQueue.main.async {
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private static func showBasicAlert(on vc: UIViewController, with title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
        alert.view.tintColor = UIColor.flatGreen()
        DispatchQueue.main.async {
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    static func addingExtraFieldAlert(on vc: UIViewController) {
        showBasicAlertWithAction(on: vc, with: NSLocalizedString("Oops!", comment: ""), message: NSLocalizedString("You have reached to free account field adding limit.To subscribe and get rid of this error, press OK.", comment: "")) {
            
            vc.navigationController?.popToRootViewController(animated: true)
            nc.post(name: Notification.Name("openPremiumViewController"), object: nil)
            
        }
    }
    
    static func addingExtraLineAlert(on vc: UIViewController) {
        showBasicAlertWithAction(on: vc, with: NSLocalizedString("Oops!", comment: ""), message: NSLocalizedString("You have reached to free account line adding limit.To subscribe and get rid of this error, press OK.", comment: "")) {
            
            vc.navigationController?.popToRootViewController(animated: true)
            nc.post(name: Notification.Name("openPremiumViewController"), object: nil)
            
        }
    }
    
    static func addingExtraPlaceAlert(on vc: UIViewController) {
        showBasicAlertWithAction(on: vc, with: NSLocalizedString("Oops!", comment: ""), message: NSLocalizedString("You have reached to free account place adding limit.To subscribe and get rid of this error, press OK.", comment: "")) {
            
            vc.navigationController?.popToRootViewController(animated: true)
            nc.post(name: Notification.Name("openPremiumViewController"), object: nil)
            
        }
    }
    
    static func addingExtraToDoItemAlert(on vc: UIViewController) {
        showBasicAlertWithAction(on: vc, with: NSLocalizedString("Oops!", comment: ""), message: NSLocalizedString("You have reached to free account item adding limit.To subscribe and get rid of this error, press OK.", comment: "")) {
            
            vc.navigationController?.popToRootViewController(animated: true)
            nc.post(name: Notification.Name("openPremiumViewController"), object: nil)
            
        }
    }
    
    static func addingExtraPhotoAlert(on vc: UIViewController) {
        showBasicAlertWithAction(on: vc, with: NSLocalizedString("Oops!", comment: ""), message: NSLocalizedString("You have reached to free account photo limit.To subscribe and get rid of this error, press OK.", comment: "")) {
            
            vc.navigationController?.popToRootViewController(animated: true)
            nc.post(name: Notification.Name("openPremiumViewController"), object: nil)
            
        }
    }
    
    static func adsAlert(on vc: UIViewController) {
        showBasicAlertWithAction(on: vc, with: NSLocalizedString("Bored with ads?", comment: ""), message: NSLocalizedString("Get Maps To Do Pro account, get rid of ads and limitations.", comment: "")) {
            
            vc.navigationController?.popToRootViewController(animated: true)
            nc.post(name: Notification.Name("openPremiumViewController"), object: nil)
            
        }
    }
    
    static func importFileTaskCompletedAlert(on vc: UIViewController) {
        showBasicAlert(on: vc, with: NSLocalizedString("Import File", comment: ""), message: NSLocalizedString("Importing file task is completed.", comment: ""))
    }
    
    static func exportFileTaskCompletedAlert(on vc: UIViewController) {
        
        let alert = UIAlertController(title: NSLocalizedString("Export File", comment: ""), message: NSLocalizedString("Exporting file task is completed. Now you can share the file.", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Share", comment: ""), style: .default, handler: { (action) in
            AlertsHelper.presentShareSheet(on: vc)
        }))
        DispatchQueue.main.async {
            vc.present(alert, animated: true, completion: nil)
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
    
    static func authInfoAlert(on: UIViewController, okAction: @escaping () -> Void) {
        showBasicAlertWithAction(on: on,
                                 with: NSLocalizedString("Auth info not found.", comment: ""),
                                 message: NSLocalizedString("For the usage of cloud synchronization, you need to sign in.", comment: "")) {
            okAction()
        }
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
    
    //MARK: - errorAlert
    static func errorAlert(on vc: UIViewController, with title: String, errorMessage: String) {
        let alert = UIAlertController(title: title,
                                      message: errorMessage,
                                      preferredStyle: .alert)
        let editItemsAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel)
        alert.addAction(editItemsAction)
        vc.present(alert, animated: true, completion: nil)
    }
    
    static func deleteAlert(on vc: UIViewController, with overlayType: OverlayType, overlayTitle: String, deleteAction: @escaping () -> Void) {
        var message = ""
        var title = String(format: NSLocalizedString("Delete %@", comment: ""), overlayTitle)
        switch overlayType {
        case .field:
            message = NSLocalizedString("Field's overlay, to-do items and photos will be deleted.", comment: "")
        case .line:
            message = NSLocalizedString("Line's overlay, to-do items and photos will be deleted.", comment: "")
        case .place:
            message = NSLocalizedString("Place's overlay, to-do items and photos will be deleted.", comment: "")
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
    
    //MARK: - importExportAlerts
    static func presentShareSheet(on vc: UIViewController) {
        let filename = getDocumentsDirectory().appendingPathComponent("mapstodo.geojson")
        let shareSheetVC = UIActivityViewController(activityItems: [filename], applicationActivities: nil)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if let popoverController = shareSheetVC.popoverPresentationController {
                popoverController.sourceView = vc.view //to set the source of your alert
                popoverController.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = [] //to hide the arrow of any particular direction
            }
        }
        vc.present(shareSheetVC, animated: true)
    }
    
    static func importExportAlert(on vc: UIViewController, importAction: @escaping () -> Void, exportAction: @escaping () -> Void) {
        let alert = UIAlertController(title: NSLocalizedString("Import/Export File", comment: ""),
                                      message: NSLocalizedString("Do you want to import or export GeoJSON file?", comment: ""),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Import", comment: ""), style: .default, handler: { _ in
            importAction()
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Export", comment: ""), style: .default, handler: { _ in
            exportAction()
        }))
        DispatchQueue.main.async {
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    static func exportTypesAlert(on vc: UIViewController, exportAction: @escaping (_ exportType: ExportTypes) -> Void) {
        let alert = UIAlertController(title: "Export File", message: "Export", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("All Fields", comment: ""), style: .default, handler: { _ in
            exportAction(.fields)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("All Lines", comment: ""), style: .default, handler: { _ in
            exportAction(.lines)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("All Places", comment: ""), style: .default, handler: { _ in
            exportAction(.places)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("All Overlays", comment: ""), style: .default, handler: { _ in
            exportAction(.all)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        DispatchQueue.main.async {
            vc.present(alert, animated: true, completion: nil)
        }
    }
}
