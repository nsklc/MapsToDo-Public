//
//  UIImageExtensions.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 10.11.2022.
//  Copyright © 2022 Enes Kılıç. All rights reserved.
//

import UIKit

extension UIImage {
    class func imageWithLabel(label: UILabel) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0.0)
        label.layer.render(in: UIGraphicsGetCurrentContext()!)
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
    }
    
    static func makeIconView(iconSize: Int, length: Double, isMetric: Bool, distanceUnit: Int, isTappable: Bool) -> UIImageView {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: iconSize, height: iconSize/2))
        label.backgroundColor = UIColor(hexString: K.Colors.primaryColor)
        let lengthWithUnit = Measurement.init(value: length, unit: UnitLength.meters)
        
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 2
        formatter.unitOptions = .providedUnit
        
        if isMetric {
            switch distanceUnit {
            case 0:
                label.text = formatter.string(from: lengthWithUnit.converted(to: UnitLength.centimeters))
            case 1:
                label.text = formatter.string(from: lengthWithUnit.converted(to: UnitLength.meters))
            case 2:
                label.text = formatter.string(from: lengthWithUnit.converted(to: UnitLength.kilometers))
            default:
                break
            }
        } else {
            switch distanceUnit {
            case 0:
                label.text = formatter.string(from: lengthWithUnit.converted(to: UnitLength.inches))
            case 1:
                label.text = formatter.string(from: lengthWithUnit.converted(to: UnitLength.feet))
            case 2:
                label.text = formatter.string(from: lengthWithUnit.converted(to: UnitLength.yards))
            case 3:
                label.text = formatter.string(from: lengthWithUnit.converted(to: UnitLength.miles))
            default:
                break
            }
        }
        
        label.sizeToFit()
        label.textColor = UIColor.flatBlack()
        label.adjustsFontSizeToFitWidth = true
    
        if isTappable {
            label.layer.borderWidth = 1
            label.layer.borderColor = UIColor.systemBlue.cgColor
        }
        
        let image = UIImage.imageWithLabel(label: label)
        return UIImageView(image: image)
    }
    static func makeIconView(iconSize: Int, lat: Double, lon: Double) -> UIImageView {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: iconSize, height: iconSize/2))
        label.backgroundColor = UIColor(hexString: K.Colors.primaryColor)
        label.text = "Lat: \(String(format: "%.4f", lat)) Lon: \(String(format: "%.4f", lon))"
        label.sizeToFit()
        label.textColor = UIColor.flatBlack()
        label.adjustsFontSizeToFitWidth = true
        let image = UIImage.imageWithLabel(label: label)
        return UIImageView(image: image)
    }
}
