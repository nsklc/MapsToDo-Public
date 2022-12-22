//
//  BaseAlertsHelper.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 22.12.2022.
//  Copyright © 2022 Enes Kılıç. All rights reserved.
//

import UIKit

class BaseAlertHelper {
    
    static let nc = NotificationCenter.default
    
    static func showBasicAlertWithAction(on vc: UIViewController, with title: String, message: String,  okAction: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
            okAction()
        }))
        DispatchQueue.main.async {
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    static func showBasicAlert(on vc: UIViewController, with title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
        alert.view.tintColor = UIColor.flatGreen()
        DispatchQueue.main.async {
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    static func errorAlert(on vc: UIViewController, with title: String, errorMessage: String) {
        let alert = UIAlertController(title: title,
                                      message: errorMessage,
                                      preferredStyle: .alert)
        let editItemsAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel)
        alert.addAction(editItemsAction)
        vc.present(alert, animated: true, completion: nil)
    }
    
    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
}
