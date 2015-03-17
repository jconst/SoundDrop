//
//  GameScene.swift
//  SoundDrop
//
//  Created by Joseph Constantakis on 3/15/15.
//  Copyright (c) 2015 jconst. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    override func didMoveToView(view: SKView) {
        // Set gravity
        self.physicsWorld.gravity = CGVectorMake(0, -2.5)
        createBallDropper()
    }
    
    func createBallDropper() {
        let dropper = SKSpriteNode(imageNamed: "dropper")
        dropper.name = "dropper"
        let wait = SKAction.waitForDuration(0.7)
        let drop = SKAction.runBlock {
            self.dropBall(dropper)
        }
        let sequence = SKAction.sequence([drop, wait])
        dropper.runAction(SKAction.repeatActionForever(sequence))
        
        dropper.xScale = 0.2
        dropper.yScale = 0.2
        
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
            createLineBumper(location, rotation: rotation)
        }
    }
    
    func createLineBumper(location: CGPoint, rotation: Double) {
        let bumper = SKSpriteNode(color: UIColor.whiteColor(), size: CGSizeMake(100, 10))
        
        bumper.position = location
        let rotate = SKAction.rotateByAngle(CGFloat(rotation), duration: 0)
        bumper.runAction(rotate)
        
        bumper.physicsBody = SKPhysicsBody(rectangleOfSize:bumper.frame.size)
        bumper.physicsBody!.restitution = 0.5
        bumper.physicsBody!.friction = 0
        // make physicsBody static
        bumper.physicsBody!.dynamic = false
        bumper.physicsBody!.allowsRotation = true
        
        self.addChild(bumper)
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
