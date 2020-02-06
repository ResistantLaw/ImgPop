//
//  FilterCell.swift
//  ImgPop
//
//  Created by Austin Whitelaw on 2/4/20.
//  Copyright © 2020 Austin Whitelaw. All rights reserved.
//

import UIKit

class FilterCell: UICollectionViewCell {
    
    let checkButton = UIButton()
    let filter: CIFilter = CIFilter()
    
    var buttonAction: (() -> Void)? = nil
    
    override func layoutSubviews() {
        checkButton.setImage(UIImage(named: "uncheckbox"), for: .normal)
        checkButton.setImage(UIImage(named: "checkbox"), for: .selected)
        checkButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(checkButton)
        checkButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 20).isActive = true
        checkButton.leadingAnchor.constraint(equalTo: self.leadingAnchor , constant: 20).isActive = true
        checkButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        checkButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        checkButton.addTarget(self, action: #selector(checkButtonPressed), for: .touchUpInside)
        
        super.layoutSubviews()
    }
    
    @objc func checkButtonPressed() {
        if let action = buttonAction {
            action()
        }
    }
    
}
