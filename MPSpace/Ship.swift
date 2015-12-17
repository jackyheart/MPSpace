//
//  Ship.swift
//  MPSpace
//
//  Created by Jacky Tjoa on 2/12/15.
//  Copyright © 2015 Coolheart. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class Ship: UIView {

    var peerID:MCPeerID! = nil
    private var nameLbl:UILabel! = nil
    private var healthLbl:UILabel! = nil
    var health:Int = 100 {
    
        didSet {
            
            if self.healthLbl != nil {
                self.healthLbl.text = "\(health)"
            }
        }
    }

    override init(frame:CGRect) {
        
        super.init(frame: frame)
    }
    
    init(frame:CGRect, imageName: String) {
    
        super.init(frame: frame)
        
        //border
        self.layer.borderColor = UIColor.yellowColor().CGColor
        self.layer.borderWidth = 2.0
        
        //ImageView
        let image = UIImage(named: imageName)!
        let imageView = UIImageView(image: image)
        imageView.frame = CGRectMake(0, 0, 130, 130)
        imageView.center = self.center
        self.addSubview(imageView)
        
        //Label (name)
        let offsetY_name:CGFloat = 90
        let lblFrame = CGRectMake(0, 0, self.frame.size.width + 20, 20)
        let label = UILabel(frame: lblFrame)
        label.center =  CGPoint(x: self.center.x, y: self.center.y + offsetY_name)
        label.font = UIFont(name: label.font.fontName, size: 17)
        label.textColor = UIColor.whiteColor()
        label.textAlignment = .Center
        label.text = kTextNotConnected
        self.addSubview(label)
        self.nameLbl = label // assign to local variable (private var)
        
        let offsetY_health:CGFloat = 20
        let lblFrame_health = CGRectMake(0, 0, self.frame.size.width + 20, 20)
        let label_health = UILabel(frame: lblFrame_health)
        label_health.center =  CGPoint(x: self.center.x, y: self.nameLbl.center.y + offsetY_health)
        label_health.font = UIFont(name: label.font.fontName, size: 17)
        label_health.textColor = UIColor.whiteColor()
        label_health.textAlignment = .Center
        label_health.text = String(health)
        self.addSubview(label_health)
        self.healthLbl = label_health // assign to local variable (private var)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func connected(peerID: MCPeerID) {
    
        self.peerID = peerID
        self.nameLbl.text = peerID.displayName
        health = 100
    }
    
    func disconnect() {
        
        self.peerID = nil
        self.nameLbl.text = kTextNotConnected
        self.health = 0
    }
}
