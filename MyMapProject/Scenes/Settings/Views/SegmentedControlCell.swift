//
//  SettingCellWithSegmentedControl.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 31.10.2021.
//  Copyright © 2021 Enes Kılıç. All rights reserved.
//

import UIKit

class SegmentedControlCell: UITableViewCell {
    
    var segmentedControl = UISegmentedControl()
    
    init() {
        super.init(style: UITableViewCell.CellStyle.default, reuseIdentifier: "reuseIdentifier")
    }
    
    init(labelText: String) {
        super.init(style: UITableViewCell.CellStyle.default, reuseIdentifier: "reuseIdentifier")
        setup()
        addLabel(with: labelText)
        addSegmentedControl()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        self.contentView.isUserInteractionEnabled = false
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
        UISegmentedControl.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor:UIColor.flatWhite()], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor:UIColor.systemBlue], for: .normal)
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
    
    func addSegmentedControl() {
        
        segmentedControl.backgroundColor = UIColor(hexString: K.colors.primaryColor)
        segmentedControl.selectedSegmentTintColor = UIColor.systemBlue
        segmentedControl.tintColor = UIColor(hexString: K.colors.thirdColor)
        
        segmentedControl.apportionsSegmentWidthsByContent = true
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(segmentedControl)
       
        segmentedControl.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        segmentedControl.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1).isActive = true
        segmentedControl.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.4).isActive = true
        segmentedControl.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0).isActive = true
        segmentedControl.layer.cornerRadius = 0
    }
}
