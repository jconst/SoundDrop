//
//  GameViewController.swift
//  SoundDrop
//
//  Created by Joseph Constantakis on 3/15/15.
//  Copyright (c) 2015 jconst. All rights reserved.
//

import UIKit
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

class GameViewController: UIViewController
{
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    let imgReader: ImageReader
    
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
        NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector:"takeSnapshot", userInfo:nil, repeats:true)
    }
    
    func detectLines(img: UIImage) {
        let line = imgReader.lineInImage(img)
        println("start: \(line.start) end: \(line.end)")
        lineLocations = [line]
    }
    
    func takeSnapshot() {
        if self.videoConnection == nil && !self.findVideoConnection() {
            return
        }
        
        self.capture.captureStillImageAsynchronouslyFromConnection(self.videoConnection, completionHandler: { (cmb: CMSampleBuffer!, err) -> Void in
            if cmb == nil || err != nil {
                NSLog("Error capturing image.")
                
                return
            }
            
            let exifAttachments = CMGetAttachment(cmb, "imageCapturedSuccessfully", nil)
            if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(cmb) {
                if let img = UIImage(data: imageData) {
                    // break here to preview image
                    self.detectLines(img)
                }
            }
        })
    }

    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
