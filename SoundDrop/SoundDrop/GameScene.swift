//
//  GameScene.swift
//  SoundDrop
//
//  Created by Joseph Constantakis on 3/15/15.
//  Copyright (c) 2015 jconst. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var lineBumpers = Array<SKSpriteNode>()
    var lineCopies = Array<SKSpriteNode>()
    var draggedNode: SKSpriteNode?
    
    var lock: SKSpriteNode?
    var bass: SKSpriteNode?
    var cross: SKSpriteNode?
    var bassLine: SKSpriteNode?

    let ballCategory: UInt32 = 0
    let bumperCategory: UInt32 = 1
    var dropDelay = 0.8
    
    let samplePlayer = SamplePlayer()
    
    override func didMoveToView(view: SKView) {
        // Set gravity
        self.physicsWorld.gravity = CGVectorMake(0, -3)
        self.physicsWorld.contactDelegate = self
        createBallDropper()
        createLock()
        createCross()
        createBass()
        
        let tapRec = UITapGestureRecognizer(target: self, action: "didTap:")
        view.addGestureRecognizer(tapRec)
    }
    
    func createLock() {
        lock = SKSpriteNode(imageNamed: "lock")
        lock!.name = "lock"
        lock!.position = CGPointMake(35, 35)
        lock!.xScale = 0.15
        lock!.yScale = 0.15
        
        self.addChild(lock!)
    }

    func createCross() {
        cross = SKSpriteNode(imageNamed: "cross")
        cross!.name = "cross"
        cross!.position = CGPointMake(35, 90)
        cross!.xScale = 0.13
        cross!.yScale = 0.13
        
        self.addChild(cross!)
    }
    
    func createBass() {
        bass = SKSpriteNode(imageNamed: "bass")
        bass!.name = "bass"
        bass!.position = CGPointMake(35, 135)
        bass!.xScale = 0.15
        bass!.yScale = 0.15
        
        self.addChild(bass!)
    }
    
    func createBallDropper() {
        let dropper = SKSpriteNode(imageNamed: "dropper")
        dropper.name = "dropper"
        self.dropBall(dropper)
        
        dropper.xScale = 0.3
        dropper.yScale = 0.3
        
        dropper.position = CGPointMake(0.5*self.frame.size.width, self.frame.size.height*0.9)
        self.addChild(dropper)
    }
    
    func dropBall(dropper: SKSpriteNode) {
        let ball = SKSpriteNode(imageNamed: "ball")
        ball.xScale = 0.3
        ball.yScale = 0.3
        ball.name = "ball"
        ball.position = dropper.position
        self.addChild(ball)
        
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.frame.size.width/2)
        ball.physicsBody!.friction = 0
        ball.physicsBody!.restitution = 1
        ball.physicsBody!.linearDamping = 0
        ball.physicsBody!.allowsRotation = false
        ball.physicsBody!.categoryBitMask = ballCategory
        ball.physicsBody!.contactTestBitMask = bumperCategory
        
        let wait = SKAction.waitForDuration(dropDelay)
        let drop = SKAction.runBlock {
            self.dropBall(dropper)
        }
        dropper.runAction(SKAction.sequence([wait, drop]))
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        let node = self.nodeAtPoint(touches.anyObject()!.locationInNode(self))
        if node != self {
            if let sprite = node as? SKSpriteNode {
                draggedNode = sprite
                if lock == draggedNode {
                    lock = lock!.copy() as? SKSpriteNode
                    self.addChild(lock!)
                } else if bass == draggedNode {
                    bass = bass!.copy() as? SKSpriteNode
                    self.addChild(bass!)
                } else if cross == draggedNode {
                    cross = cross!.copy() as? SKSpriteNode
                    self.addChild(cross!)
                }
            }
        }
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        if touches.count == 1 {
            if let node = self.draggedNode {
                if let touch = touches.anyObject() as? UITouch {
                    let x = touch.locationInNode(self).x - touch.previousLocationInNode(self).x
                    let y = touch.locationInNode(self).y - touch.previousLocationInNode(self).y
                    if let index = find(lineBumpers, node) {
                        let prev = scaleNormPointToScreen(lineLocations[index])
                        lineLocations[index] = normalizeScreenPoint(CGPoint(x: prev.x + x, y: prev.y + y))
                    } else {
                        let move = SKAction.moveByX(x, y: y, duration: 0.01)
                        draggedNode!.runAction(move)
                    }
                }
            }
        } else if touches.count == 2 {
            if let touch = touches.anyObject() as? UITouch {
                let height = 1.0 - (touch.locationInNode(self).y / self.size.height)
                dropDelay = Double(height)
            }
        }
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        if let name = draggedNode?.name? {
            if contains(["lock", "bass", "cross"], name) {
                draggedNode!.removeFromParent()
                for (i, line) in enumerate(lineBumpers) {
                    if draggedNode!.intersectsNode(line) {
                        if name == "lock" {
                            let cp = line.copy() as SKSpriteNode
                            lineCopies.append(cp)
                            self.addChild(cp)
                        } else if name == "bass" {
                            bassLine = line
                        } else if name == "cross" {
                            if bassLine == line {
                                bassLine = nil
                            }
                            if i >= oscSender.activeHosts.count {
                                line.removeFromParent()
                                lineBumpers.removeAtIndex(i)
                                lineRotations.removeAtIndex(i)
                                lineLocations.removeAtIndex(i)
                                break
                            }
                        }
                    }
                }
                for (i, line) in reverse(Array(enumerate(lineCopies))) {
                    if draggedNode!.intersectsNode(line) {
                        if name == "bass" {
                            bassLine = line
                        } else if name == "cross" {
                            line.removeFromParent()
                            lineCopies.removeAtIndex(i)
                            break
                        }
                    }
                }
            }
        }
        draggedNode = nil
    }
    
    func didTap(rec: UITapGestureRecognizer) {
        if rec.numberOfTouches() == 1 {
            var location = rec.locationInView(self.view!)
            location.y = self.view!.frame.size.height - location.y
            lineLocations.append(normalizeScreenPoint(location))
            let randomFloat = Float(arc4random()) / Float(UINT32_MAX)
            let rotation = Double(randomFloat) * 2.0 * M_PI
            lineRotations.append(CGFloat(rotation))
            lineBumpers.append(createLineBumper(location, rotation: CGFloat(rotation)))
        }
    }
    
    func createLineBumper(location: CGPoint, rotation: CGFloat) -> SKSpriteNode {
        let bumper = SKSpriteNode(color: UIColor.whiteColor(), size: CGSizeMake(110, 15))
        
        bumper.position = location
        updateLineBumper(bumper, location: location, rotation: rotation)
        
        bumper.physicsBody = SKPhysicsBody(rectangleOfSize:bumper.frame.size)
        bumper.physicsBody!.restitution = 0.5
        bumper.physicsBody!.friction = 0
        bumper.physicsBody!.affectedByGravity = false
        bumper.physicsBody!.allowsRotation = false
        bumper.physicsBody!.categoryBitMask = bumperCategory
        bumper.physicsBody!.collisionBitMask = ballCategory
        
        self.addChild(bumper)
        return bumper
    }
    
    func updateLineBumper(bumper: SKSpriteNode, location: CGPoint, rotation: CGFloat) {
        let move = SKAction.moveTo(location, duration: snapshotInterval/2)
        bumper.runAction(move)
        let lastRotation = bumper.zRotation
        let rotate = SKAction.rotateByAngle(CGFloat(rotation - lastRotation), duration: 0)
        bumper.runAction(rotate)
    }
   
    override func update(currentTime: CFTimeInterval) {
        for (i, loc) in enumerate(lineLocations) {
            if lineBumpers.count <= i {
                break
            }
            let bumper = lineBumpers[i]
            let rot = (lineRotations.count > i ? lineRotations[i] : CGFloat(0))
            updateLineBumper(bumper, location: scaleNormPointToScreen(loc), rotation: rot)
        }
    }
    
    func normalizeScreenPoint(pt: CGPoint) -> CGPoint {
        let p = CGPoint(x: pt.x / self.size.width,
                        y: pt.y / self.size.height);
        return p
    }

    func scaleNormPointToScreen(pt: CGPoint) -> CGPoint {
        let p = CGPoint(x: pt.x * self.size.width,
                        y: pt.y * self.size.height);
        return p
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        for (i, line) in enumerate(lineBumpers) {
            if line.physicsBody! == contact.bodyA ||
               line.physicsBody! == contact.bodyB {
                if line == bassLine {
                    samplePlayer.playKick()
                } else {
                    oscSender.playBounce(Double(contact.collisionImpulse), device: i)
                    soundManager.playBounceWithMidiNote(Int32(noteForSpeed(Double(contact.collisionImpulse))))
                }
            }
        }
        
        for line in lineCopies {
            if line.physicsBody! == contact.bodyA ||
               line.physicsBody! == contact.bodyB {
                if line == bassLine {
                    samplePlayer.playKick()
                } else {
                    soundManager.playBounceWithMidiNote(Int32(noteForSpeed(Double(contact.collisionImpulse))))
                }
            }
        }
    }
    
    func reset() {
        for line in lineBumpers + lineCopies {
            line.removeFromParent()
        }
        lineBumpers = []
        lineCopies = []
    }
}
