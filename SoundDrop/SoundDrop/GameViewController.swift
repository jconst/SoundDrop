//
//  GameViewController.swift
//  SoundDrop
//
//  Created by Joseph Constantakis on 3/15/15.
//  Copyright (c) 2015 jconst. All rights reserved.
//

import UIKit
import Darwin
import SpriteKit
import AVFoundation

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

class GameViewController: UIViewController, NSNetServiceBrowserDelegate
{
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    let imgReader: ImageReader
    
    let oscManager = OSCManager(serviceType: "")
    
    var externalPorts = [OSCOutPort]()
    var activeHosts = [String: Bool]()
    
    @IBOutlet var skView: SKView!
    @IBOutlet var camView: UIView!
    
    let capture = AVCaptureStillImageOutput()
    var videoConnection: AVCaptureConnection!
    
    var camLayer: AVCaptureVideoPreviewLayer!
    
    required init(coder aDecoder: NSCoder) {
        imgReader = ImageReader()
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
            // Configure the view.
            skView.showsFPS = true
            skView.showsNodeCount = true
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            
            skView.presentScene(scene)
            
            self.setUpSession()
            self.setupSnapshotTimer()
            
            self.setUpOSC()
        }
    }
    
    func receivedOSCMessage(msg: OSCMessage) {
        if msg.address() == "/urMus/text" {
            if let s = msg.value().stringValue() as NSString! {
                if self.activeHosts[s] != nil {
                    return
                }
                
                // add port for new slave device
                let out = OSCOutPort(address: s, andPort: 8888)
                let index = self.externalPorts.count
                self.externalPorts.append(out)
                self.activeHosts[s] = true
                
                // tell the device what its id is
                let msg = OSCMessage(address: "/urMus/text")
                msg.addString("DeviceIndex:" + String(index))
                out.sendThisMessage(msg)
            }
        } else {
            if let numbers = msg.valueArray() {
                if numbers.count >= 2 {
                    if let index = numbers.objectAtIndex(0) as? OSCValue {
                        if let x = numbers.objectAtIndex(1) as? OSCValue {
                            // index of device in externalPorts and x rotation value
//                            print(index, x.floatValue())
                            if let d = Int(index.floatValue()) as Int! {
                                if lineRotations.count > d {
                                    lineRotations[d] = lerp(lineRotations[d], CGFloat(-x.floatValue() * Float(M_PI_2)) + CGFloat(M_PI_2), 0.8)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func setUpOSC() {
        self.oscManager.setDelegate(self)
        let inPort = self.oscManager.createNewInputForPort(8888)
        inPort.setDelegate(self)
        
        NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "sendToPhones:", userInfo: nil, repeats: true)
    }
    
    func sendToPhones(time: NSTimer) {
        var uuid: CFUUIDRef = CFUUIDCreate(nil)
        var nonce: CFStringRef = CFUUIDCreateString(nil, uuid)
        let msg = OSCMessage(address: "/urMus/text")
        msg.addString(String(Int(arc4random_uniform(781)) + 220) + ", " + String(Int(arc4random_uniform(781)) + 220))
        
        for port in self.externalPorts {
            port.sendThisMessage(msg)
        }
    }
    
    func setUpSession() {
        captureSession.sessionPreset = AVCaptureSessionPresetLow
        
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if(device.position == AVCaptureDevicePosition.Back) {
                    self.captureDevice = device as? AVCaptureDevice
                    self.showSessionInBackground()
                }
            }
        }
    }
    
    func showSessionInBackground() {
        if self.captureDevice == nil {
            return
        }
        
        var err : NSError? = nil
        captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err))
        
        if err != nil {
            return
        }
        
        camLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        camLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMakeRotation(-CGFloat(M_PI)/2.0))
        
        camLayer.frame = self.view.bounds
        camLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        self.camView.layer.addSublayer(camLayer)
        captureSession.startRunning()
        
        self.capture.outputSettings = NSDictionary(objectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey)
        self.captureSession.addOutput(self.capture)
        
        self.findVideoConnection()
    }
    
    func findVideoConnection() -> Bool {
        for conn in self.capture.connections {
            if conn.inputPorts != nil {
                for port in conn.inputPorts! {
                    if port.mediaType == AVMediaTypeVideo {
                        if let s = conn as? AVCaptureConnection {
                            self.videoConnection = s
                            return true
                        }
                    }
                }
            }
        }
        
        return false
    }

    func setupSnapshotTimer() {
        NSTimer.scheduledTimerWithTimeInterval(snapshotInterval, target: self, selector:"takeSnapshot", userInfo:nil, repeats:true)
    }

    func takeSnapshot() {
        if self.videoConnection == nil && !self.findVideoConnection() {
            return
        }
        
        self.capture.captureStillImageAsynchronouslyFromConnection(self.videoConnection) { (cmb: CMSampleBuffer!, err) -> Void in
            
            if cmb == nil || err != nil {
                NSLog("Error capturing image.", err)
                
                return
            }
            
            let exifAttachments = CMGetAttachment(cmb, "imageCapturedSuccessfully", nil)
            if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(cmb) {
                if let img = UIImage(data: imageData) {
                    // break here to preview image
                    self.detectLines(img)
                }
            }
        }
    }
    
    func detectLines(img: UIImage) {
        let flashes = imgReader.flashesInImage(img)
            .map { val -> CGPoint in
                val.CGPointValue()
            }
        lineLocations = lineLocations
            .map { loc -> CGPoint in
                return self.findClosestFlash(flashes, maxJump: flashMaxJump, point: loc)
            }
    }
    
    func findClosestFlash(flashes: Array<CGPoint>, maxJump: CGFloat, point: CGPoint) -> CGPoint {
        if flashes.count == 0 {
            return point
        }
        // TODO: If this algorithm isn't satisfactory, try using some heuristic
        // combination of flash size as well as closeness to the point
        
        var closest = flashes[0]
        var smallestDist = distanceBetween(closest, point)
        for cur in flashes {
            let curDist = distanceBetween(cur, point)
            if curDist < smallestDist {
                smallestDist = curDist
                closest = cur
            }
        }
        if distanceBetween(closest, point) > maxJump {
            return point
        }
        return closest//lerp(point, closest, 0.5)
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
