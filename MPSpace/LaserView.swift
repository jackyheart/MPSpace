//
//  LaserView.swift
//  MPSpace
//
//  Created by Jacky Tjoa on 9/12/15.
//  Copyright © 2015 Coolheart. All rights reserved.
//

import UIKit

@IBDesignable
class LaserView: UIImageView {
    
    @IBInspectable var shadowRadius:CGFloat = 0.4
    @IBInspectable var shadowOpacity:Float = 0.9
    @IBInspectable var shadowOffset:CGSize = CGSizeMake(0.0, -3.0);
    var direction:CGFloat = 1
    private var playerIndex = 1

    //cyan: A3EEFF
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(frame:CGRect, playerIndex:Int) {
    
        super.init(frame: frame)
        self.playerIndex = playerIndex
        
        if playerIndex == 1 {
            self.image = UIImage(named: "laser_blue")
        } else if playerIndex == 2 {
            self.image = UIImage(named: "laser_red")
        }
        
        print("LaserView init frame, playerIdx")
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    
    /*
    override func drawRect(rect: CGRect) {
        // Drawing code
        
        print("LaserView drawRect")
        
        var shadowColor = UIColor.cyanColor().CGColor
        var borderColor = UIColor(red: 0.35, green: 0.6, blue: 0.9, alpha: 1.0).CGColor
        
        if playerIndex == 2 {
        
            shadowColor = UIColor.redColor().CGColor
            borderColor = UIColor(red: 0.9, green: 0.6, blue: 0.35, alpha: 1.0).CGColor
        }
        
        self.layer.shadowColor = shadowColor
        self.layer.shadowRadius = shadowRadius
        self.layer.shadowOpacity = shadowOpacity
        self.layer.shadowOffset = shadowOffset
        
        self.layer.borderColor = borderColor
        self.layer.borderWidth = 0.5
        self.layer.cornerRadius = 5
        self.layer.masksToBounds = false
    }
    */
}
