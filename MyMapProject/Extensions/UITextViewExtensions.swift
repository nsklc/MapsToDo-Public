//
//  UITextViewExtensions.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 10.11.2022.
//  Copyright © 2022 Enes Kılıç. All rights reserved.
//

import UIKit

extension UITextView {
    //MARK: - doneAccessory
    @IBInspectable var doneAccessory: Bool{
        get{
            return self.doneAccessory
        }
        set (hasDone) {
            if hasDone{
                addDoneButtonOnKeyboard()
            }
        }
    }
    //MARK: - addDoneButtonOnKeyboard
    func addDoneButtonOnKeyboard()
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Done", comment: ""), style: .done, target: self, action: #selector(self.doneButtonAction))
        
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.inputAccessoryView = doneToolbar
    }
    //MARK: - doneButtonAction
    @objc func doneButtonAction()
    {
        self.resignFirstResponder()
    }
}
