//
//  SwitchViewCell.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 31.10.2021.
//  Copyright © 2021 Enes Kılıç. All rights reserved.
//

import UIKit

class SwitchViewCell: UITableViewCell {
    
    let switchUI = UISwitch(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
    
    init(labelText: String, switchDefaultValue: Bool) {
        super.init(style: UITableViewCell.CellStyle.default, reuseIdentifier: "reuseIdentifier")
        setup()
        addLabel(with: labelText)
        addSwitchUI()
        switchUI.isOn = switchDefaultValue
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        backgroundColor = UIColor.clear
        self.contentView.isUserInteractionEnabled = false
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
    }
    
    func addLabel(with labelText: String) {
        let label = UILabel()
        self.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor.clear
        label.heightAnchor.constraint(equalTo: self.safeAreaLayoutGuide.heightAnchor, constant: 0).isActive = true
        label.widthAnchor.constraint(equalTo: self.safeAreaLayoutGuide.widthAnchor, multiplier: 0.6).isActive = true
        label.leftAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leftAnchor).isActive = true
        
        label.text = labelText
        label.textAlignment = .center
        label.numberOfLines = 2
    }
    
    func addSwitchUI() {
        let switchView = UIView()
        self.addSubview(switchView)
       
        switchView.translatesAutoresizingMaskIntoConstraints = false
        switchView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        switchView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
        switchView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.4).isActive = true
        switchView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        
        switchView.layer.cornerRadius = 9
        switchView.clipsToBounds = true
        switchView.backgroundColor = UIColor.clear
        
        
        self.addSubview(switchUI)
        switchUI.translatesAutoresizingMaskIntoConstraints = false
        switchUI.centerXAnchor.constraint(equalTo: switchView.centerXAnchor).isActive = true
        switchUI.centerYAnchor.constraint(equalTo: switchView.centerYAnchor).isActive = true
        
        switchUI.onTintColor = UIColor(hexString: K.colors.secondaryColor)
    }
}
