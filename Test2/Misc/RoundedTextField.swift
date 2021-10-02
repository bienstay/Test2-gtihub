//
//  RoundedTextField.swift
//  FoodPin
//
//  Created by maciulek on 05/04/2021.
//

import UIKit

class RoundedTextField: UITextField {

    let padding = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
    
    override func textRect(forBounds bounds: CGRect) -> CGRect { return bounds.inset(by: padding) }
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect { return bounds.inset(by: padding) }
    override func editingRect(forBounds bounds: CGRect) -> CGRect { return bounds.inset(by: padding) }
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.borderWidth = 1.0
        if #available(iOS 13, *) { self.layer.borderColor = UIColor.systemGray5.cgColor }
        else { self.layer.borderColor = UIColor.lightGray.cgColor }
        self.layer.cornerRadius = 10.0
        self.layer.masksToBounds = true
    }
}

