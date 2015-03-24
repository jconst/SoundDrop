//
//  GameScene.swift
//  SoundDrop
//
//  Created by Joseph Constantakis on 3/15/15.
//  Copyright (c) 2015 jconst. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    var lineBumpers = Array<SKSpriteNode>()
    
    override func didMoveToView(view: SKView) {
        // Set gravity
        self.physicsWorld.gravity = CGVectorMake(0, -3)
        createBallDropper()
    }
    
    func createBallDropper() {
        let dropper = SKSpriteNode(imageNamed: "dropper")
        dropper.name = "dropper"
        let wait = SKAction.waitForDuration(0.5)
        let drop = SKAction.runBlock {
            self.dropBall(dropper)
        }
        let sequence = SKAction.sequence([drop, wait])
        dropper.runAction(SKAction.repeatActionForever(sequence))
        
        dropper.xScale = 0.3
        dropper.yScale = 0.3
        
        dropper.position = CGPointMake(0.5*self.frame.size.width, self.frame.size.height*0.75)
        self.addChild(dropper)
    }
    
    func dropBall(dropper: SKSpriteNode) {
        let ball = SKSpriteNode(imageNamed: "ball")
        ball.xScale = 0.3
        ball.yScale = 0.3
        ball.name = "ball"
        ball.position = CGPointMake(0.5*self.frame.size.width, self.frame.size.height*0.75)
        self.addChild(ball)
        
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.frame.size.width/2)
        ball.physicsBody!.friction = 0
        ball.physicsBody!.restitution = 1
        ball.physicsBody!.linearDamping = 0
        ball.physicsBody!.allowsRotation = false
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            // Temperarily set rotation as random number
            let randomFloat = Float(arc4random()) / Float(UINT32_MAX)
            let rotation = Double(randomFloat) * 2.0 * M_PI
            lineBumpers.append(createLineBumper(location, rotation: CGFloat(rotation), width: 100))
        }
    }
    
    func createLineBumper(location: CGPoint, rotation: CGFloat, width: CGFloat) -> SKSpriteNode {
        let bumper = SKSpriteNode(color: UIColor.whiteColor(), size: CGSizeMake(100, 10))
        
        updateLineBumper(bumper, location: location, rotation: rotation, width: width)
        
        bumper.physicsBody = SKPhysicsBody(rectangleOfSize:bumper.frame.size)
        bumper.physicsBody!.restitution = 0.5
        bumper.physicsBody!.friction = 0
        // make physicsBody static
        bumper.physicsBody!.dynamic = false
        bumper.physicsBody!.allowsRotation = true
        
        self.addChild(bumper)
        return bumper
    }
    
    func updateLineBumper(bumper: SKSpriteNode, location: CGPoint, rotation: CGFloat, width: CGFloat) {
//        bumper.xScale = width / 100.0
        bumper.position = CGPoint(x: location.x + 400, y: UIScreen.mainScreen().bounds.size.height - location.y)
        let lastRotation = bumper.zRotation
//        println(lastRotation)
        let rotate = SKAction.rotateByAngle(CGFloat(rotation - lastRotation), duration: 0)
        bumper.runAction(rotate)
    }
   
    override func update(currentTime: CFTimeInterval) {

        for (i, line) in enumerate(lineLocations) {
            if lineBumpers.count <= i {
                break
            }
            let bumper = lineBumpers[i]
            let loc = centerOfLine(line)
            let rot = angleOfLine(line)
            let width = lengthOfLine(line)
            updateLineBumper(bumper, location: loc, rotation: rot, width: width)
        }
    }
}
