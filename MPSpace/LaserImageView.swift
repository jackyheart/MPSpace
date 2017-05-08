//
//  LaserImageView.swift
//  MPSpace
//
//  Created by Jacky Tjoa on 9/12/15.
//  Copyright © 2015 Coolheart. All rights reserved.
//

import UIKit

class LaserImageView: UIImageView {

    @IBInspectable var shadowRadius:CGFloat = 2.0
    @IBInspectable var shadowOpacity:Float = 1.0
    @IBInspectable var shadowOffset:CGSize = CGSize(width: 0.0, height: -3.0);

    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        
        self.layer.shadowColor = UIColor.cyan.cgColor
        self.layer.shadowRadius = shadowRadius
        self.layer.shadowOpacity = shadowOpacity
        self.layer.shadowOffset = shadowOffset
        self.layer.masksToBounds = false
    }


}
