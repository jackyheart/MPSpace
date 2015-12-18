//
//  ViewController.swift
//  MPSpace
//
//  Created by Jacky Tjoa on 2/12/15.
//  Copyright © 2015 Coolheart. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import AVFoundation

extension Double {
    var degreesToRadians : CGFloat {
        return CGFloat(self) * CGFloat(M_PI) / 180.0
    }
}

let kTextNotConnected = "Not Connected"
let kTextAdvertising = "Advertising..."
let kTextNotAdvertising = "Not Advertising"
let TAG_PLAYER1 = 1
let TAG_PLAYER2 = 2
let HEALTH_DECREMENT = 10
let kMaxHealth = 100

class ViewController: UIViewController, MCAdvertiserAssistantDelegate, MCBrowserViewControllerDelegate, MCSessionDelegate {

    @IBOutlet weak var falconImgView: UIImageView!
    @IBOutlet weak var xwingImgView: UIImageView!
    @IBOutlet weak var gameOverScreen: UIView!
    @IBOutlet weak var winningLbl: UILabel!
    
    //Multipeer Connectivity
    let kServiceType = "multi-peer-chat"
    var myPeerID:MCPeerID! = nil
    var session:MCSession! = nil
    var browser:MCBrowserViewController!
    var advertiser:MCAdvertiserAssistant! = nil
    private var isAdvertising:Bool = false
    var shipArray:[Ship] = []
    var laserArray:[LaserView] = []
    var laserSoundPlayer:AVAudioPlayer! = nil;
    var gameTimer:NSTimer! = nil;
    var CONTROLLER1_OFFSET:CGPoint = CGPointZero;
    var CONTROLLER2_OFFSET:CGPoint = CGPointZero;
    //var explosionSprite:UIImage! = nil
    var explosionSpriteArray:[UIImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Initiate
        print("self.view.frame: \(self.view.frame)")
        
        //Player 1
        let offsetY:CGFloat = 150
        let center1 = CGPointMake(self.view.frame.size.width * 0.5, self.view.frame.size.height - offsetY)
        let ship1 = Ship(frame: CGRectMake(0, 0, 150, 150), imageName: "xwing")
        ship1.center = center1
        ship1.tag = TAG_PLAYER1
        self.view.addSubview(ship1)
        self.shipArray.append(ship1)
        
        //Player 2
        let center2 = CGPointMake(self.view.frame.size.width * 0.5, offsetY)
        let ship2 = Ship(frame: CGRectMake(0, 0, 150, 150), imageName: "falcon")
        ship2.center = center2
        ship2.tag = TAG_PLAYER2
        self.view.addSubview(ship2)
        self.shipArray.append(ship2)
        
        //Rotate UIImageView (ship 2)
        ship2.transform = CGAffineTransformMakeRotation(180.0.degreesToRadians);
        
        
        //Sfx
        let laserFilePath = NSBundle.mainBundle().pathForResource("blaster", ofType: "wav")!
        let laserURL = NSURL(fileURLWithPath: laserFilePath)
        
        do {
            try self.laserSoundPlayer = AVAudioPlayer(contentsOfURL: laserURL)
            self.laserSoundPlayer.prepareToPlay()
        } catch {
            print("error open laser sound file: \(error)")
        }
        
        for (var i:Int = 0; i < 4; i++) {
            
            let image = UIImage(named: "exp\(i)")!
            self.explosionSpriteArray.append(image)
        }
        
        
        //Multipeer Connectivity
        
        //session
        self.myPeerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        self.session = MCSession(peer: self.myPeerID, securityIdentity: nil, encryptionPreference: .Required)
        self.session.delegate = self
        self.advertiser = MCAdvertiserAssistant(serviceType: kServiceType, discoveryInfo: nil, session: self.session)
        
        self.browser = MCBrowserViewController(serviceType: kServiceType, session: self.session)
        self.browser.delegate = self
        
        self.advertiser.start()
        
        //UI
        self.gameOverScreen.hidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - IBActions

    //TODO: Testing
    @IBAction func laserTapped(sender: AnyObject) {
        
        self.shootLaserByPeerIndex(TAG_PLAYER1 - 1)
    }
    
    @IBAction func restart(sender: AnyObject) {
    
        //Restart game
        
        self.gameOverScreen.hidden = true
        
        self.gameTimer = NSTimer.scheduledTimerWithTimeInterval(1/30.0, target: self, selector: "mainGameLoop", userInfo: nil, repeats: true)
        
        var i:Int = 0
        let offsetY:CGFloat = 150
        var center = CGPointZero
        
        for ship in self.shipArray {
        
            ship.health = kMaxHealth
            
            if i == 0 {
            
                center = CGPointMake(self.view.frame.size.width * 0.5, self.view.frame.size.height - offsetY)
            }
            else if i == 1 {
                
                center = CGPointMake(self.view.frame.size.width * 0.5, offsetY)
            }
            
            ship.center = center
            
            i++
        }
    }
    
    //MARK: - Functions
    
    func shootLaserByPeerIndex(peerIndex:Int) {
    
        let ship = self.shipArray[peerIndex]
        
        let laserView = LaserView(frame: CGRectMake(0, 0, 10, 70), peerIndex: peerIndex)
        laserView.backgroundColor = UIColor.whiteColor()
        laserView.center = CGPointMake(ship.center.x, ship.center.y - 20)
        laserView.tag = ship.tag
        self.laserArray.append(laserView)
        
        self.view.addSubview(laserView)
    }
    
    func explodeAtPoint(point:CGPoint) {
        
        let explosionFrame = CGRectMake(point.x - 0.5 * 150, (point.y - 0.5 * 115) + 10, 150, 115)
        let explosionImgView = UIImageView(frame: explosionFrame)
        explosionImgView.image = explosionSpriteArray[0]
        explosionImgView.animationImages = explosionSpriteArray
        explosionImgView.animationDuration = 1.0
        explosionImgView.animationRepeatCount = 1
        explosionImgView.startAnimating()
        self.view.addSubview(explosionImgView)
        
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(explosionImgView.animationDuration) * Int64(NSEC_PER_SEC))
        dispatch_after(popTime, dispatch_get_main_queue()) { () -> Void in
            
            explosionImgView.stopAnimating()
            explosionImgView.removeFromSuperview()
        }
    }
    
    //MARK: - MCAdvertiserAssistantDelegate
    
    func advertiserAssistantDidDismissInvitation(advertiserAssistant: MCAdvertiserAssistant) {
        
        print("advertiserAssistantDidDismissInvitation")
        print("connectedPeers: \(self.session.connectedPeers)")
    }
    
    //MARK: - MCBrowserViewControllerDelegate
    
    func browserViewControllerDidFinish(browserViewController: MCBrowserViewController) {
        
        self.browser.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController) {
        
        self.browser.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - MCSessionDelegate
    
    func session(session: MCSession, didReceiveCertificate certificate: [AnyObject]?, fromPeer peerID: MCPeerID, certificateHandler: (Bool) -> Void) {
        
        return certificateHandler(true)
    }
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        
        print("myPeerID: \(self.session.myPeerID)")
        print("connectd peerID: \(peerID)")
        
        switch state {
            
        case .Connecting:
            print("Connecting..")
            //print("peers count: \(session.connectedPeers.count)")
            
            /*
            if (session.connectedPeers.count > 0){
                
                let index = self.session.connectedPeers.indexOf(peerID)!
                print("index: \(index)")
            }
            */
            break
            
        case .Connected:
            print("Connected..")
            print("peers count: \(session.connectedPeers.count)")
            
            if (session.connectedPeers.count > 0){
                let index = self.session.connectedPeers.indexOf(peerID)!
                
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        print("connected dispatch main queue")
                        
                        if self.shipArray.count > index {
                            
                            let ship = self.shipArray[index]
                            ship.connected(peerID)//connect peer !
                            
                            if self.gameTimer == nil {
                                
                                print("start timer game loop !!!")
                                
                                self.gameTimer = NSTimer.scheduledTimerWithTimeInterval(1/30.0, target: self, selector: "mainGameLoop", userInfo: nil, repeats: true)
                            }
                        }
                    })

                print("index: \(index)")
            }
            break
            
        case .NotConnected:
            
            print("Not Connected..")
            print("peers count: \(session.connectedPeers.count)")
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                
                var index = 0
                for ship in self.shipArray {
                    
                    if ship.peerID != nil {
                        if ship.peerID == peerID {
                            
                            //disconnect
                            ship.disconnect()
                            break
                        }
                    }
                    
                    index++
                }
            })
            
            break
        }
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            //Do animation on main thread
            
            let peerIndex = self.session.connectedPeers.indexOf(peerID)
            
            let dataDict:NSDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! NSDictionary
            
            print("didReceiveData \(dataDict["action"]) from peer:\(peerID.displayName)")
            
            if peerIndex != nil && self.gameTimer != nil {

                let action = dataDict["action"] as! String
                
                //print("receive action \(action) from peer: \(peerID.displayName)")
                
                if action == "move" {
                    
                    print("receive move from peer: \(peerID.displayName)")
                
                    let touchDistance = dataDict["touchDistance"] as! Float
                    let touchAngle = dataDict["touchAngle"] as! Float

                    if peerIndex == 0 {
                        self.CONTROLLER1_OFFSET.x = CGFloat(touchDistance/10.0 * cosf(touchAngle))
                        self.CONTROLLER1_OFFSET.y = CGFloat(touchDistance/10.0 * sinf(touchAngle))
                        
                    } else if peerIndex == 1 {
                        self.CONTROLLER2_OFFSET.x = CGFloat(touchDistance/10.0 * cosf(touchAngle))
                        self.CONTROLLER2_OFFSET.y = CGFloat(touchDistance/10.0 * sinf(touchAngle))
                    }
                } else if action == "fire" {
                
                    //self.laserSoundPlayer.play()
                    self.shootLaserByPeerIndex(peerIndex!)
                }
                else if action == "release" {
                    
                    if peerIndex == 0 {
                        self.CONTROLLER1_OFFSET = CGPointZero
                    }
                    else if peerIndex == 1 {
                        self.CONTROLLER2_OFFSET = CGPointZero
                    }
                }
            }
        }
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        
        print("table didStartReceivingResourceWithName")
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        
        print("table didFinishReceivingResourceWithName")
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
        print("table didReceiveStream")
    }
    
    //MARK: - Game Loop
    
    func mainGameLoop() {
        
        //print("gameLoop")

        if self.shipArray.count >= self.session.connectedPeers.count {
            
            var idx:Int = 0;
            for peerID in self.session.connectedPeers {
                
                let ship = self.shipArray[idx];
                
                if ship.peerID != nil && ship.peerID == peerID {
                
                    var offsetX = self.CONTROLLER1_OFFSET.x
                    var offsetY = self.CONTROLLER1_OFFSET.y
                    
                    if idx == 1 {
                        offsetX = self.CONTROLLER2_OFFSET.x
                        offsetY = self.CONTROLLER2_OFFSET.y
                    }
                    
                    //Check boundaries
                    if CGRectContainsRect(self.view.frame, ship.frame) {
                    
                        ship.center = CGPointMake(
                            ship.center.x - CGFloat(offsetX),
                            ship.center.y - CGFloat(offsetY))
                        
                    } else {
                        
                        ship.center = CGPointMake(
                            ship.center.x + CGFloat(offsetX),
                            ship.center.y + CGFloat(offsetY))
                        
                        if idx == 0 {
                            self.CONTROLLER1_OFFSET.x = -offsetX * 0.5
                            self.CONTROLLER1_OFFSET.y = -offsetY * 0.5
                        } else if idx == 1 {
                            self.CONTROLLER2_OFFSET.x = -offsetX * 0.5
                            self.CONTROLLER2_OFFSET.y = -offsetY * 0.5
                        }
                    }
                    
                    //Check collision between ships
                    if CGRectIntersectsRect(self.shipArray[0].frame, self.shipArray[1].frame) {
                    
                        print("plane intersects !")
                        
                        ship.center = CGPointMake(
                            ship.center.x + CGFloat(offsetX),
                            ship.center.y + CGFloat(offsetY))
                        
                        if idx == 0 {
                            self.CONTROLLER1_OFFSET.x = -offsetX * 0.5
                            self.CONTROLLER1_OFFSET.y = -offsetY * 0.5
                        } else if idx == 1 {
                            self.CONTROLLER2_OFFSET.x = -offsetX * 0.5
                            self.CONTROLLER2_OFFSET.y = -offsetY * 0.5
                        }
                    }
                }
                
                idx++;
            }
        }
        
        var i:Int = 0
        for laserView in self.laserArray {

            laserView.center = CGPointMake(laserView.center.x, laserView.center.y - (laserView.direction * 10))
            
            if (!CGRectContainsRect(self.view.bounds, laserView.frame))
            {
                if i < self.laserArray.count {
                    //laser is out-of-bound, remove
                    laserView.removeFromSuperview()
                    self.laserArray.removeAtIndex(i)
                }
            }
            
            var shipIdx = 0
            for ship in shipArray {
            
                if CGRectIntersectsRect(ship.frame, laserView.frame) {
                    
                    if ship.tag != laserView.tag {
                        
                        //explosion
                        self.explodeAtPoint(laserView.center)
                        
                        //laser is out-of-bound, remove
                        laserView.removeFromSuperview()
                        self.laserArray.removeAtIndex(i)
                        ship.health -= HEALTH_DECREMENT
                        
                        if ship.health <= 0 {
                            self.gameTimer.invalidate()
                            self.gameTimer = nil
                            
                            self.gameOverScreen.hidden = false
                            
                            if shipIdx == 0 {
                            
                                let peerID = self.session.connectedPeers[1]
                                self.winningLbl.text = "\(peerID.displayName) Wins !"
                            }
                            else if shipIdx == 1 {
                            
                                let peerID = self.session.connectedPeers[0]
                                self.winningLbl.text = "\(peerID.displayName) Wins !"
                            }
                        }
                    }
                }
                
                shipIdx++
            }
            
            i++
        }
    }
}

