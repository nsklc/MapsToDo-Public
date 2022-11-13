//
//  AlertsHelper.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 1.04.2021.
//  Copyright © 2021 Enes Kılıç. All rights reserved.
//

import UIKit

struct AlertsHelper {
    
    static let nc = NotificationCenter.default
    
    private static func showBasicAlertWithAction(on vc: UIViewController, with title: String, message: String,  okAction: @escaping () -> Void  ) {
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
    
    static func exportFileTaskCompletedAlert(on vc: UIViewController, isGeoJson: Bool) {
        
        let alert = UIAlertController(title: NSLocalizedString("Export File", comment: ""), message: NSLocalizedString("Exporting file task is completed. Now you can share the file.", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Share", comment: ""), style: .default, handler: { (action) in
            AlertsHelper.presentShareSheet(on: vc, isGeoJson: isGeoJson)
        }))
        DispatchQueue.main.async {
            vc.present(alert, animated: true, completion: nil)
        }
        
    }
    
    static func presentShareSheet(on vc: UIViewController, isGeoJson: Bool) {
        
        var filename = getDocumentsDirectory().appendingPathComponent("mapstodo.kml")
        
        if isGeoJson {
            filename = getDocumentsDirectory().appendingPathComponent("mapstodo.geojson")
        }
        
        
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
    
    private static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
