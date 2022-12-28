//
//  ImportExportAlerts.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 22.12.2022.
//  Copyright © 2022 Enes Kılıç. All rights reserved.
//

import UIKit

class ImportExportAlertsHelper: BaseAlertHelper {
    
    static func importFileTaskCompletedAlert(on vc: UIViewController) {
        showBasicAlert(on: vc, with: NSLocalizedString("Import File", comment: ""), message: NSLocalizedString("Importing file task is completed.", comment: ""))
    }
    
    static func exportFileTaskCompletedAlert(on vc: UIViewController) {
        
        let alert = UIAlertController(title: NSLocalizedString("Export File", comment: ""), message: NSLocalizedString("Exporting file task is completed. Now you can share the file.", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Share", comment: ""), style: .default, handler: { (_) in
            ImportExportAlertsHelper.presentShareSheet(on: vc)
        }))
        DispatchQueue.main.async {
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    static func presentShareSheet(on vc: UIViewController) {
        let filename = getDocumentsDirectory().appendingPathComponent("mapstodo.geojson")
        let shareSheetVC = UIActivityViewController(activityItems: [filename], applicationActivities: nil)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if let popoverController = shareSheetVC.popoverPresentationController {
                popoverController.sourceView = vc.view
                popoverController.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
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
