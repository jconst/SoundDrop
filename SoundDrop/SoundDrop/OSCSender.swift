//
//  OSCSender.swift
//  SoundDrop
//
//  Created by Joseph Constantakis on 4/7/15.
//  Copyright (c) 2015 jconst. All rights reserved.
//

class OSCSender: NSObject {
    
    let oscManager = OSCManager(serviceType: "")
    
    var externalPorts = [OSCOutPort]()
    var activeHosts = [String: Bool]()
    
    func setUpOSC() {
        self.oscManager.setDelegate(self)
        let inPort = self.oscManager.createNewInputForPort(8888)
        inPort.setDelegate(self)
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
                            if let d = Int(index.floatValue()) as Int! {
                                if lineRotations.count > d {
                                    let newRot = CGFloat(x.floatValue() * Float(M_PI_2)) + CGFloat(M_PI_2)
                                    lineRotations[d] = lerp(lineRotations[d], newRot, 0.7)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    
    func playBounce(contactSpeed: Double, device: Int) {
    
        let freq = freqForSpeed(contactSpeed)
        let msg = OSCMessage(address: "/urMus/text")
        msg.addString(String(format: "%.2f", freq))
        
        if self.externalPorts.count > device {
            self.externalPorts[device].sendThisMessage(msg)
        }
    }
}
