//
//  ArrayExtensions.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 10.11.2022.
//  Copyright © 2022 Enes Kılıç. All rights reserved.
//

import Foundation

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()
        
        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }
    
    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}
