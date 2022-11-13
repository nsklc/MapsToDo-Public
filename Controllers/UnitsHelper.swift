//
//  UnitsHelper.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 20.03.2021.
//  Copyright © 2021 Enes Kılıç. All rights reserved.
//

import Foundation

class UnitsHelper {
    static var app: UnitsHelper = {
        return UnitsHelper()
    }()

    func getUnitForField(isShowAllUnitsSelected: Bool, isMeasureSystemMetric: Bool, area: Measurement<UnitArea>, circumference: Measurement<UnitLength>, distanceUnit: Int, areaUnit: Int) -> String {
        
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 4
        formatter.unitOptions = .providedUnit
        
        var content = ""
        
        if isShowAllUnitsSelected {
            
            if isMeasureSystemMetric {
                
                content += NSLocalizedString(" Area = ", comment: "") + "\( formatter.string(from: area.converted(to: UnitArea.squareCentimeters))) "
            
                content += NSLocalizedString("\n Area = ", comment: "") + "\( formatter.string(from: area.converted(to: UnitArea.squareMeters))) "
            
                content += NSLocalizedString("\n Area = ", comment: "") + "\( formatter.string(from: area.converted(to: UnitArea.squareKilometers))) "
            
                content += NSLocalizedString("\n Area = ", comment: "") + "\( formatter.string(from: area.converted(to: UnitArea.ares))) "
            
                content += NSLocalizedString("\n Area = ", comment: "") + "\( formatter.string(from: area.converted(to: UnitArea.hectares))) "
                
                switch distanceUnit {
                case 0:
                    content += NSLocalizedString("\n Circumference = ", comment: "") + "\( formatter.string(from: circumference.converted(to: UnitLength.centimeters))) "
                case 1:
                    content += NSLocalizedString("\n Circumference = ", comment: "") + "\( formatter.string(from: circumference.converted(to: UnitLength.meters))) "
                case 2:
                    content += NSLocalizedString("\n Circumference = ", comment: "") + "\( formatter.string(from: circumference.converted(to: UnitLength.kilometers))) "
                default:
                    break
                }
                
            } else {
                
                content += NSLocalizedString(" Area = ", comment: "") + "\( formatter.string(from: area.converted(to: UnitArea.squareInches))) "
                content += NSLocalizedString("\n Area = ", comment: "") + "\( formatter.string(from: area.converted(to: UnitArea.squareFeet))) "
                content += NSLocalizedString("\n Area = ", comment: "") + "\( formatter.string(from: area.converted(to: UnitArea.squareYards))) "
                content += NSLocalizedString("\n Area = ", comment: "") + "\( formatter.string(from: area.converted(to: UnitArea.squareMiles))) "
                content += NSLocalizedString("\n Area = ", comment: "") + "\( formatter.string(from: area.converted(to: UnitArea.acres))) "
                
                switch distanceUnit {
                case 0:
                    content += NSLocalizedString("\n Circumference = ", comment: "") + "\( formatter.string(from: circumference.converted(to: UnitLength.inches))) "
                case 1:
                    content += NSLocalizedString("\n Circumference = ", comment: "") + "\( formatter.string(from: circumference.converted(to: UnitLength.feet))) "
                case 2:
                    content += NSLocalizedString("\n Circumference = ", comment: "") + "\( formatter.string(from: circumference.converted(to: UnitLength.yards))) "
                case 3:
                    content += NSLocalizedString("\n Circumference = ", comment: "") + "\( formatter.string(from: circumference.converted(to: UnitLength.miles))) "
                default:
                    break
                }
            }
            
        } else {
            
            if isMeasureSystemMetric {
                switch areaUnit {
                case 0:
                    content += NSLocalizedString(" Area = ", comment: "") + "\( formatter.string(from: area.converted(to: UnitArea.squareCentimeters))) "
                case 1:
                    content += NSLocalizedString(" Area = ", comment: "") + "\( formatter.string(from: area.converted(to: UnitArea.squareMeters))) "
                case 2:
                    content += NSLocalizedString(" Area = ", comment: "") + "\( formatter.string(from: area.converted(to: UnitArea.squareKilometers))) "
                case 3:
                    content += NSLocalizedString(" Area = ", comment: "") + "\( formatter.string(from: area.converted(to: UnitArea.ares))) "
                case 4:
                    content += NSLocalizedString(" Area = ", comment: "") + "\( formatter.string(from: area.converted(to: UnitArea.hectares))) "
                default:
                    break
                }
                
                switch distanceUnit {
                case 0:
                    content += NSLocalizedString("\n Circumference = ", comment: "") + "\( formatter.string(from: circumference.converted(to: UnitLength.centimeters))) "
                case 1:
                    content += NSLocalizedString("\n Circumference = ", comment: "") + "\( formatter.string(from: circumference.converted(to: UnitLength.meters))) "
                case 2:
                    content += NSLocalizedString("\n Circumference = ", comment: "") + "\( formatter.string(from: circumference.converted(to: UnitLength.kilometers))) "
                default:
                    break
                }
            } else {
                switch areaUnit {
                case 0:
                    content += NSLocalizedString(" Area = ", comment: "") + "\( formatter.string(from: area.converted(to: UnitArea.squareInches))) "
                case 1:
                    content += NSLocalizedString(" Area = ", comment: "") + "\( formatter.string(from: area.converted(to: UnitArea.squareFeet))) "
                case 2:
                    content += NSLocalizedString(" Area = ", comment: "") + "\( formatter.string(from: area.converted(to: UnitArea.squareYards))) "
                case 3:
                    content += NSLocalizedString(" Area = ", comment: "") + "\( formatter.string(from: area.converted(to: UnitArea.squareMiles))) "
                case 4:
                    content += NSLocalizedString(" Area = ", comment: "") + "\( formatter.string(from: area.converted(to: UnitArea.acres))) "
                default:
                    break
                }
                
                switch distanceUnit {
                case 0:
                    content += NSLocalizedString("\n Circumference = ", comment: "") + "\( formatter.string(from: circumference.converted(to: UnitLength.inches))) "
                case 1:
                    content += NSLocalizedString("\n Circumference = ", comment: "") + "\( formatter.string(from: circumference.converted(to: UnitLength.feet))) "
                case 2:
                    content += NSLocalizedString("\n Circumference = ", comment: "") + "\( formatter.string(from: circumference.converted(to: UnitLength.yards))) "
                case 3:
                    content += NSLocalizedString("\n Circumference = ", comment: "") + "\( formatter.string(from: circumference.converted(to: UnitLength.miles))) "
                default:
                    break
                }
            }
        }
        
        return content
    }

    func getUnitForLine(isShowAllUnitsSelected: Bool, isMeasureSystemMetric: Bool, length: Measurement<UnitLength>, distanceUnit: Int) -> String {
        
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 4
        formatter.unitOptions = .providedUnit
        
        var content = ""
        
        if isShowAllUnitsSelected {
            if isMeasureSystemMetric {
                content += NSLocalizedString(" Length = ", comment: "") + "\( formatter.string(from: length.converted(to: UnitLength.centimeters))) \n"
                content += NSLocalizedString(" Length = ", comment: "") + "\( formatter.string(from: length.converted(to: UnitLength.meters))) \n"
                content += NSLocalizedString(" Length = ", comment: "") + "\( formatter.string(from: length.converted(to: UnitLength.kilometers)))"
            } else {
                content += NSLocalizedString(" Length = ", comment: "") + "\( formatter.string(from: length.converted(to: UnitLength.inches))) \n"
                content += NSLocalizedString(" Length = ", comment: "") + "\( formatter.string(from: length.converted(to: UnitLength.feet))) \n"
                content += NSLocalizedString(" Length = ", comment: "") + "\( formatter.string(from: length.converted(to: UnitLength.yards))) \n"
                content += NSLocalizedString(" Length = ", comment: "") + "\( formatter.string(from: length.converted(to: UnitLength.miles))) "
            }
        } else {
            if isMeasureSystemMetric {
                switch distanceUnit {
                case 0:
                    content += NSLocalizedString(" Length = ", comment: "") + "\( formatter.string(from: length.converted(to: UnitLength.centimeters))) "
                case 1:
                    content += NSLocalizedString(" Length = ", comment: "") + "\( formatter.string(from: length.converted(to: UnitLength.meters))) "
                case 2:
                    content += NSLocalizedString(" Length = ", comment: "") + "\( formatter.string(from: length.converted(to: UnitLength.kilometers))) "
                default:
                    break
                }
            } else {
                switch distanceUnit {
                case 0:
                    content += NSLocalizedString(" Length = ", comment: "") + "\( formatter.string(from: length.converted(to: UnitLength.inches))) "
                case 1:
                    content += NSLocalizedString(" Length = ", comment: "") + "\( formatter.string(from: length.converted(to: UnitLength.feet))) "
                case 2:
                    content += NSLocalizedString(" Length = ", comment: "") + "\( formatter.string(from: length.converted(to: UnitLength.yards))) "
                case 3:
                    content += NSLocalizedString(" Length = ", comment: "") + "\( formatter.string(from: length.converted(to: UnitLength.miles))) "
                default:
                    break
                }
            }
        }
        
        return content
        
    }
    
    func getPlaceholderAndUnitLengthType(isMeasureSystemMetric: Bool, distanceUnit: Int) -> [String:UnitLength] {
        
        if isMeasureSystemMetric {
            switch distanceUnit {
            case 0:
                return [NSLocalizedString("cm", comment: ""):UnitLength.centimeters]
            case 1:
                return [NSLocalizedString("m", comment: ""):UnitLength.meters]
            case 2:
                return [NSLocalizedString("km", comment: ""):UnitLength.kilometers]
            default:
                break
            }
        } else {
            switch distanceUnit {
            case 0:
                return [NSLocalizedString("in", comment: ""):UnitLength.inches]
            case 1:
                return [NSLocalizedString("ft", comment: ""):UnitLength.feet]
            case 2:
                return [NSLocalizedString("yd", comment: ""):UnitLength.yards]
            case 3:
                return [NSLocalizedString("mi", comment: ""):UnitLength.miles]
            default:
                break
            }
        }
        
        return ["asd":UnitLength.centimeters]
    }
    
}
