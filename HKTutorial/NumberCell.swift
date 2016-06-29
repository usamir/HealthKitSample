//
//  NumberCell.swift
//  HKTutorialPrototype
//
//  Created by samir on 29/06/16.
//  Copyright (c) 2016 samir. All rights reserved.
//

import UIKit

class NumberCell: UITableViewCell {
    
    @IBOutlet var numberTextField:UITextField!
    
    var doubleValue:Double {
        
        get {
            let numberString:NSString = NSString(string:numberTextField.text!)
            return numberString.doubleValue;
        }
    }
}


