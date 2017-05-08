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
    fileprivate var nameLbl:UILabel! = nil
    fileprivate var healthLbl:UILabel! = nil
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
        //self.layer.borderColor = UIColor.yellowColor().CGColor
        //self.layer.borderWidth = 2.0
        
        //ImageView
        let image = UIImage(named: imageName)!
        let imageView = UIImageView(image: image)
        imageView.frame = CGRect(x: 0, y: 0, width: 130, height: 130)
        imageView.center = self.center
        self.addSubview(imageView)
        
        //Label (name)
        let offsetY_name:CGFloat = 90
        let lblFrame = CGRect(x: 0, y: 0, width: self.frame.size.width + 20, height: 20)
        let label = UILabel(frame: lblFrame)
        label.center =  CGPoint(x: self.center.x, y: self.center.y + offsetY_name)
        label.font = UIFont(name: label.font.fontName, size: 17)
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.text = kTextNotConnected
        self.addSubview(label)
        self.nameLbl = label // assign to local variable (private var)
        
        let offsetY_health:CGFloat = 20
        let lblFrame_health = CGRect(x: 0, y: 0, width: self.frame.size.width + 20, height: 20)
        let label_health = UILabel(frame: lblFrame_health)
        label_health.center =  CGPoint(x: self.center.x, y: self.nameLbl.center.y + offsetY_health)
        label_health.font = UIFont(name: label.font.fontName, size: 17)
        label_health.textColor = UIColor.white
        label_health.textAlignment = .center
        label_health.text = String(health)
        self.addSubview(label_health)
        self.healthLbl = label_health // assign to local variable (private var)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func connected(_ peerID: MCPeerID) {
    
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
