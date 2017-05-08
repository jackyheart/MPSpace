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
    fileprivate var isAdvertising:Bool = false
    var shipArray:[Ship] = []
    var laserArray:[LaserView] = []
    var laserSoundPlayer:AVAudioPlayer! = nil;
    var gameTimer:Timer! = nil;
    var CONTROLLER1_OFFSET:CGPoint = CGPoint.zero;
    var CONTROLLER2_OFFSET:CGPoint = CGPoint.zero;
    //var explosionSprite:UIImage! = nil
    var explosionSpriteArray:[UIImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Initiate
        print("self.view.frame: \(self.view.frame)")
        
        //Player 1
        let offsetY:CGFloat = 150
        let center1 = CGPoint(x: self.view.frame.size.width * 0.5, y: self.view.frame.size.height - offsetY)
        let ship1 = Ship(frame: CGRect(x: 0, y: 0, width: 150, height: 150), imageName: "xwing")
        ship1.center = center1
        ship1.tag = TAG_PLAYER1
        self.view.addSubview(ship1)
        self.shipArray.append(ship1)
        
        //Player 2
        let center2 = CGPoint(x: self.view.frame.size.width * 0.5, y: offsetY)
        let ship2 = Ship(frame: CGRect(x: 0, y: 0, width: 150, height: 150), imageName: "falcon")
        ship2.center = center2
        ship2.tag = TAG_PLAYER2
        self.view.addSubview(ship2)
        self.shipArray.append(ship2)
        
        //Rotate UIImageView (ship 2)
        ship2.transform = CGAffineTransform(rotationAngle: 180.0.degreesToRadians);
        
        
        //Sfx
        let laserFilePath = Bundle.main.path(forResource: "blaster", ofType: "wav")!
        let laserURL = URL(fileURLWithPath: laserFilePath)
        
        do {
            try self.laserSoundPlayer = AVAudioPlayer(contentsOf: laserURL)
            self.laserSoundPlayer.prepareToPlay()
        } catch {
            print("error open laser sound file: \(error)")
        }
        
        for i in 0 ..< 4 {
            
            let image = UIImage(named: "exp\(i)")!
            self.explosionSpriteArray.append(image)
        }
        
        
        //Multipeer Connectivity
        
        //session
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: self.myPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.session.delegate = self
        self.advertiser = MCAdvertiserAssistant(serviceType: kServiceType, discoveryInfo: nil, session: self.session)
        
        self.browser = MCBrowserViewController(serviceType: kServiceType, session: self.session)
        self.browser.delegate = self
        
        self.advertiser.start()
        
        //UI
        self.gameOverScreen.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - IBActions

    //TODO: Testing
    @IBAction func laserTapped(_ sender: AnyObject) {
        
        self.shootLaserByPeerIndex(TAG_PLAYER1 - 1)
    }
    
    @IBAction func restart(_ sender: AnyObject) {
    
        //Restart game
        
        self.gameOverScreen.isHidden = true
        
        self.gameTimer = Timer.scheduledTimer(timeInterval: 1/30.0, target: self, selector: #selector(ViewController.mainGameLoop), userInfo: nil, repeats: true)
        
        var i:Int = 0
        let offsetY:CGFloat = 150
        var center = CGPoint.zero
        
        for ship in self.shipArray {
        
            ship.health = kMaxHealth
            
            if i == 0 {
            
                center = CGPoint(x: self.view.frame.size.width * 0.5, y: self.view.frame.size.height - offsetY)
            }
            else if i == 1 {
                
                center = CGPoint(x: self.view.frame.size.width * 0.5, y: offsetY)
            }
            
            ship.center = center
            
            i += 1
        }
    }
    
    //MARK: - Functions
    
    func shootLaserByPeerIndex(_ peerIndex:Int) {
    
        let ship = self.shipArray[peerIndex]
        
        let laserView = LaserView(frame: CGRect(x: 0, y: 0, width: 10, height: 70), playerIndex: 1)
        laserView.backgroundColor = UIColor.white
        laserView.center = CGPoint(x: ship.center.x, y: ship.center.y - 20)
        laserView.tag = ship.tag
        self.laserArray.append(laserView)
        
        self.view.addSubview(laserView)
    }
    
    func explodeAtPoint(_ point:CGPoint) {
        
        let explosionFrame = CGRect(x: point.x - 0.5 * 150, y: (point.y - 0.5 * 115) + 10, width: 150, height: 115)
        let explosionImgView = UIImageView(frame: explosionFrame)
        explosionImgView.image = explosionSpriteArray[0]
        explosionImgView.animationImages = explosionSpriteArray
        explosionImgView.animationDuration = 1.0
        explosionImgView.animationRepeatCount = 1
        explosionImgView.startAnimating()
        self.view.addSubview(explosionImgView)
        
        let popTime = DispatchTime.now() + Double(Int64(explosionImgView.animationDuration) * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: popTime) { () -> Void in
            
            explosionImgView.stopAnimating()
            explosionImgView.removeFromSuperview()
        }
    }
    
    //MARK: - MCAdvertiserAssistantDelegate
    
    func advertiserAssistantDidDismissInvitation(_ advertiserAssistant: MCAdvertiserAssistant) {
        
        print("advertiserAssistantDidDismissInvitation")
        print("connectedPeers: \(self.session.connectedPeers)")
    }
    
    //MARK: - MCBrowserViewControllerDelegate
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        
        self.browser.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        
        self.browser.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - MCSessionDelegate
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        
        return certificateHandler(true)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        print("myPeerID: \(self.session.myPeerID)")
        print("connectd peerID: \(peerID)")
        
        switch state {
            
        case .connecting:
            print("Connecting..")
            
            print("peers count: \(session.connectedPeers.count)")
            if (session.connectedPeers.count > 0){
                
                let index = self.session.connectedPeers.index(of: peerID)!
                print("index: \(index)")
            }
            break
            
        case .connected:
            print("Connected..")
            
            if (session.connectedPeers.count > 0){
                let index = self.session.connectedPeers.index(of: peerID)!
                
                    DispatchQueue.main.async(execute: { () -> Void in
                        
                        print("connected dispatch main queue")
                        
                        if self.shipArray.count > index {
                            
                            let ship = self.shipArray[index]
                            ship.connected(peerID)//connect peer !
                            
                            
                            if self.gameTimer == nil {
                                
                                print("start timer game loop !!!")
                                
                                self.gameTimer = Timer.scheduledTimer(timeInterval: 1/30.0, target: self, selector: #selector(ViewController.mainGameLoop), userInfo: nil, repeats: true)
                            }
                        }
                    })

                print("index: \(index)")
            }
            break
            
        case .notConnected:
            
            print("Not Connected..")
            print("peers count: \(session.connectedPeers.count)")
            
            DispatchQueue.main.async(execute: { () -> Void in
                
                
                var index = 0
                for ship in self.shipArray {
                    
                    if ship.peerID != nil {
                        if ship.peerID == peerID {
                            
                            //disconnect
                            ship.disconnect()
                            break
                        }
                    }
                    
                    index += 1
                }
            })
            
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        DispatchQueue.main.async { () -> Void in
            
            //Do animation on main thread
            
            let peerIndex = self.session.connectedPeers.index(of: peerID)
            
            let dataDict:NSDictionary = NSKeyedUnarchiver.unarchiveObject(with: data) as! NSDictionary
            
            let action = dataDict["type"] as! String
            
            if action == "move" {
            
                let touchDistance = dataDict["touchDistance"] as! Float
                let touchAngle = dataDict["touchAngle"] as! Float
                
                if peerIndex != nil {
                    
                    if peerIndex == 0 {
                    
                        self.CONTROLLER1_OFFSET.x = CGFloat(touchDistance/10.0 * cosf(touchAngle))
                        self.CONTROLLER1_OFFSET.y = CGFloat(touchDistance/10.0 * sinf(touchAngle))
                        
                    } else if peerIndex == 1 {
                    
                        self.CONTROLLER2_OFFSET.x = CGFloat(touchDistance/10.0 * cosf(touchAngle))
                        self.CONTROLLER2_OFFSET.y = CGFloat(touchDistance/10.0 * sinf(touchAngle))
                    }
                }
                
            } else if action == "button" {
            
                self.laserSoundPlayer.play()
                self.shootLaserByPeerIndex(peerIndex!)
            }
        }
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
        print("table didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        
        print("table didFinishReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
        print("table didReceiveStream")
    }
    
    //MARK: - Game Loop
    
    func mainGameLoop() {
        
        //print("gameLoop")

        if self.shipArray.count >= self.session.connectedPeers.count {
            
            var idx = 0;
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
                    if self.view.frame.contains(ship.frame) {
                    
                        ship.center = CGPoint(
                            x: ship.center.x - CGFloat(offsetX),
                            y: ship.center.y - CGFloat(offsetY))
                        
                    } else {
                    
                        ship.center = CGPoint(
                            x: ship.center.x + CGFloat(offsetX),
                            y: ship.center.y + CGFloat(offsetY))
                        
                        
                        if idx == 0 {
                            self.CONTROLLER1_OFFSET.x = -offsetX * 0.5
                            self.CONTROLLER1_OFFSET.y = -offsetY * 0.5
                        } else if idx == 1 {
                            self.CONTROLLER2_OFFSET.x = -offsetX * 0.5
                            self.CONTROLLER2_OFFSET.y = -offsetY * 0.5
                        }
                    }
                    
                    
                    //Check collision between ships
                    if self.shipArray[0].frame.intersects(self.shipArray[1].frame) {
                    
                        print("plane intersects !")
                        
                        ship.center = CGPoint(
                            x: ship.center.x + CGFloat(offsetX),
                            y: ship.center.y + CGFloat(offsetY))
                        
                        if idx == 0 {
                            self.CONTROLLER1_OFFSET.x = -offsetX * 0.5
                            self.CONTROLLER1_OFFSET.y = -offsetY * 0.5
                        } else if idx == 1 {
                            self.CONTROLLER2_OFFSET.x = -offsetX * 0.5
                            self.CONTROLLER2_OFFSET.y = -offsetY * 0.5
                        }
                    }
                    
                    break
                }
                
                idx += 1;
            }
        }
        
        var i:Int = 0
        for laserView in self.laserArray {

            laserView.center = CGPoint(x: laserView.center.x, y: laserView.center.y - (laserView.direction * 10))
            
            if (!self.view.bounds.contains(laserView.frame))
            {
                if i < self.laserArray.count {
                    //laser is out-of-bound, remove
                    laserView.removeFromSuperview()
                    self.laserArray.remove(at: i)
                }
            }
            
            var shipIdx = 0
            for ship in shipArray {
            
                if ship.frame.intersects(laserView.frame) {
                    
                    if ship.tag != laserView.tag {
                        
                        //explosion
                        self.explodeAtPoint(laserView.center)
                        
                        //laser is out-of-bound, remove
                        laserView.removeFromSuperview()
                        self.laserArray.remove(at: i)
                        ship.health -= HEALTH_DECREMENT
                        
                        if ship.health <= 0 {
                            self.gameTimer.invalidate()
                            self.gameTimer = nil
                            
                            self.gameOverScreen.isHidden = false
                            
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
                
                shipIdx += 1
            }
            
            i += 1
        }
    }
}

