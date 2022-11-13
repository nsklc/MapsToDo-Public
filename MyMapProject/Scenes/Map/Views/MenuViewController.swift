//
//  MenuViewController.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 20.09.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import UIKit

enum MenuType: Int {
    case home
    case groups
    case fields
    case lines
    case places
    case settings
    case importFile
}

class MenuViewController: UITableViewController {
    
    var didTapMenuType: ((MenuType) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hexString: K.colors.thirdColor)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let menutype = MenuType(rawValue: indexPath.row) else { return }
        
        dismiss(animated: true) { [weak self] in
            self?.didTapMenuType?(menutype)
        }
        
    }

}
