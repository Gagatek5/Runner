//
//  GameScene.swift
//  FlappyBird
//
//  Created by Nate Murray on 6/2/14.
//  Copyright (c) 2014 Fullstack.io. All rights reserved.
//

import SpriteKit
import Each

class GameScene: SKScene, SKPhysicsContactDelegate{
    
    var timer = Each(1).milliseconds
    var countdown = 999999999
     var x = 0
    
    
    let verticalPipeGap = 150.0
    
    var bird:SKSpriteNode!
    var skyColor:SKColor!
    var pipeTextureUp:SKTexture!
    var pipeTextureDown:SKTexture!
    var movePipesAndRemove:SKAction!
    var moving:SKNode!
    var pipes:SKNode!
    var gameOver = Bool()
    var scoreLabelNode:SKLabelNode!
    var gameOverLabel:SKLabelNode!
    var score = NSInteger()
    var touchCounter = 0
    
    let birdCategory: UInt32 = 1 << 0
    let worldCategory: UInt32 = 1 << 1
    let pipeCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    let randomInterval = RandomNumberGenerator()
    
    override func didMove(to view: SKView) {
        
        gameOver = false
        
        // setup physics
        self.physicsWorld.gravity = CGVector( dx: 0.0, dy: -5.0 )
        self.physicsWorld.contactDelegate = self
        
        // setup background color
        skyColor = SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0)
        self.backgroundColor = skyColor
        
        moving = SKNode()
        // MOVING SPEED AT START !!!
        self.moving.speed = 1
        self.addChild(moving)
        pipes = SKNode()
        moving.addChild(pipes)
        
        // ground
        let groundTexture = SKTexture(imageNamed: "land")
        groundTexture.filteringMode = .nearest // shorter form for SKTextureFilteringMode.Nearest
        
        let moveGroundSprite = SKAction.moveBy(x: -groundTexture.size().width * 2.0, y: 0, duration: TimeInterval(0.02 * groundTexture.size().width * 2.0))
        let resetGroundSprite = SKAction.moveBy(x: groundTexture.size().width * 2.0, y: 0, duration: 0.0)
        let moveGroundSpritesForever = SKAction.repeatForever(SKAction.sequence([moveGroundSprite,resetGroundSprite]))
        
        for i in 0 ..< 2 + Int(self.frame.size.width / ( groundTexture.size().width * 2 )) {
            let i = CGFloat(i)
            let sprite = SKSpriteNode(texture: groundTexture)
            sprite.setScale(2.0)
            sprite.position = CGPoint(x: i * sprite.size.width, y: sprite.size.height / 2.0)
            sprite.run(moveGroundSpritesForever)
            moving.addChild(sprite)
        }
        
        // skyline
        let skyTexture = SKTexture(imageNamed: "sky")
        skyTexture.filteringMode = .nearest
        
        let moveSkySprite = SKAction.moveBy(x: -skyTexture.size().width * 2.0, y: 0, duration: TimeInterval(0.1 * skyTexture.size().width * 2.0))
        let resetSkySprite = SKAction.moveBy(x: skyTexture.size().width * 2.0, y: 0, duration: 0.0)
        let moveSkySpritesForever = SKAction.repeatForever(SKAction.sequence([moveSkySprite,resetSkySprite]))
        
        for i in 0 ..< 3 + Int(self.frame.size.width / ( skyTexture.size().width * 2 )) {
            let i = CGFloat(i)
            let sprite = SKSpriteNode(texture: skyTexture)
            sprite.setScale(2.0)
            sprite.zPosition = -20
            sprite.position = CGPoint(x: i * sprite.size.width, y: sprite.size.height / 2.0 + groundTexture.size().height * 2.0)
            sprite.run(moveSkySpritesForever)
            moving.addChild(sprite)
        }
        
        // create the pipes textures
        pipeTextureUp = SKTexture(imageNamed: "PipeUp")
        pipeTextureUp.filteringMode = .nearest
        pipeTextureDown = SKTexture(imageNamed: "PipeDown")
        pipeTextureDown.filteringMode = .nearest
        
        // create the pipes movement actions
        let distanceToMove = CGFloat(self.frame.size.width + 4.0 * pipeTextureUp.size().width)
        let movePipes = SKAction.moveBy(x: -distanceToMove, y:0.0, duration:TimeInterval(0.01 * distanceToMove))
        let removePipes = SKAction.removeFromParent()
        movePipesAndRemove = SKAction.sequence([movePipes, removePipes])
        
        // spawn the pipes
        let spawn = SKAction.run(spawnPipes)
        let delay = SKAction.wait(forDuration: TimeInterval(2.0))
        let spawnThenDelay = SKAction.sequence([spawn, delay])
        let spawnThenDelayForever = SKAction.repeatForever(spawnThenDelay)
        self.run(spawnThenDelayForever)
        
        // setup our bird
        let birdTexture1 = SKTexture(imageNamed: "bird-01")
        birdTexture1.filteringMode = .nearest
        let birdTexture2 = SKTexture(imageNamed: "bird-02")
        birdTexture2.filteringMode = .nearest
        
        let anim = SKAction.animate(with: [birdTexture1, birdTexture2], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(anim)
        
        bird = SKSpriteNode(texture: birdTexture1)
        bird.setScale(2.0)
        bird.position = CGPoint(x: self.frame.size.width * 0.35, y:self.frame.size.height * 0.4)
        bird.run(flap)
        
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.allowsRotation = false
        
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        bird.physicsBody?.contactTestBitMask = worldCategory | pipeCategory
        
        self.addChild(bird)
        
        // create the ground
        let ground = SKNode()
        ground.position = CGPoint(x: 0, y: groundTexture.size().height)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: groundTexture.size().height * 2.0))
        ground.physicsBody?.isDynamic = false
       // ground.physicsBody?.categoryBitMask = worldCategory
        self.addChild(ground)
        
        // Initialize label and create a label which holds the score
        score = 0
        scoreLabelNode = SKLabelNode(fontNamed:"MarkerFelt-Wide")
        scoreLabelNode.position = CGPoint( x: self.frame.midX, y: 3 * self.frame.size.height / 4 )
        scoreLabelNode.zPosition = 100
        scoreLabelNode.text = String(score)
        self.addChild(scoreLabelNode)
        setTimer()
    }
    
    func spawnPipes() {
        if touchCounter != 3 {
            
            let pipePair = SKNode()
            pipePair.position = CGPoint( x: self.frame.size.width + pipeTextureUp.size().width * 2, y: 0 )
            pipePair.zPosition = -10
            
            let height = UInt32( self.frame.size.height / 4)
            let y = Double(height) // Double(arc4random_uniform(height) + height)
            
            let pipeDown = SKSpriteNode(texture: pipeTextureDown)
            pipeDown.setScale(2.0)
            pipeDown.position = CGPoint(x: 0.0, y: y + Double(pipeDown.size.height) + verticalPipeGap)
            
            
            //        pipeDown.physicsBody = SKPhysicsBody(rectangleOf: pipeDown.size)
            //        pipeDown.physicsBody?.isDynamic = false
            //        pipeDown.physicsBody?.categoryBitMask = pipeCategory
            //        pipeDown.physicsBody?.contactTestBitMask = birdCategory
            //        pipePair.addChild(pipeDown)
            
            let pipeUp = SKSpriteNode(texture: pipeTextureUp)
            pipeUp.setScale(2.0)
            pipeUp.position = CGPoint(x: 0.0, y: y)
            
            pipeUp.physicsBody = SKPhysicsBody(rectangleOf: pipeUp.size)
            pipeUp.physicsBody?.isDynamic = false
            //        pipeUp.physicsBody?.categoryBitMask = pipeCategory
            //        pipeUp.physicsBody?.contactTestBitMask = birdCategory
            pipePair.addChild(pipeUp)
            
            //        let contactNode = SKNode()
            //        contactNode.position = CGPoint( x: pipeDown.size.width + bird.size.width / 2, y: self.frame.midY )
            //        contactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize( width: pipeUp.size.width, height: self.frame.size.height ))
            //        contactNode.physicsBody?.isDynamic = false
            //        contactNode.physicsBody?.categoryBitMask = scoreCategory
            //        contactNode.physicsBody?.contactTestBitMask = birdCategory
            //        pipePair.addChild(contactNode)
            
            pipePair.run(movePipesAndRemove)
            pipes.addChild(pipePair)
        }
        
    }
    
    func resetScene () {
        
        countdown = 999999999
        
        // Move bird to original position and reset velocity
        bird.position = CGPoint(x: self.frame.size.width * 0.35, y:self.frame.size.height * 0.4)
        bird.physicsBody?.velocity = CGVector( dx: 0, dy: 0 )
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        bird.speed = 1.0
        bird.zRotation = 0.0
        
        // Remove all existing pipes
        pipes.removeAllChildren()
        
        // Reset _canRestart
        gameOver = false
        
        // Reset score
        score = 0
        scoreLabelNode.text = String(score)
        
        // Restart animation
        moving.speed = 1
        
        // Reset "gameover" label
        gameOverLabel.run(SKAction.removeFromParent())
        
        // Reset touch counter
        touchCounter = 0
        
        // Reset timer
        timer.restart()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if moving.speed > 0 && !gameOver {
            
            print(touchCounter)
            if  touchCounter < 2
            {
                for _ in touches { // do we need all touches?
                    bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                    bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 30))
                    touchCounter += 1
                }
            }
            
        } else if gameOverLabel.position.x < self.frame.midX + 1 {
            self.resetScene()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
        let value = bird.physicsBody!.velocity.dy * ( bird.physicsBody!.velocity.dy < 0 ? 0.003 : 0.001 )
        bird.zRotation = min( max(-1, value), 0.5 )
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if moving.speed > 0 && touchCounter != 3 {
            if ( contact.bodyA.categoryBitMask & scoreCategory ) == scoreCategory || ( contact.bodyB.categoryBitMask & scoreCategory ) == scoreCategory {
                // Bird has contact with score entity
                //score += 1
                //scoreLabelNode.text = String(score)
                touchCounter = 0
                // Add a little visual feedback for the score increment
//                scoreLabelNode.run(SKAction.sequence([SKAction.scale(to: 1.5, duration:TimeInterval(0.1)), SKAction.scale(to: 1.0, duration:TimeInterval(0.1))]))
//            } else {
//
//                moving.speed = 0
//
//                bird.physicsBody?.collisionBitMask = worldCategory
//                bird.run(  SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1), completion:{self.bird.speed = 0 })
//
//
//                // Flash background if contact is detected
//                self.removeAction(forKey: "flash")
//                self.run(SKAction.sequence([SKAction.repeat(SKAction.sequence([SKAction.run({
//                    self.backgroundColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0)
//                    }),SKAction.wait(forDuration: TimeInterval(0.05)), SKAction.run({
//                        self.backgroundColor = self.skyColor
//                        }), SKAction.wait(forDuration: TimeInterval(0.05))]), count:4), SKAction.run({
//                            self.canRestart = true
//                            })]), withKey: "flash")
            }
        }
    }
    
    // ===============================//
    func setTimer() {
        self.timer.perform { () -> NextStep in
        self.endGame()
        self.countdown -= 1
        if self.moving.speed <= 20
        {
            self.moving.speed += 0.001
            
            self.scoreLabelNode.text = String(self.score) + " " + String(describing: self.moving.speed)
            print(self.score)
        }
        
        self.x += 1
        print("x: " + String(self.x))
        if self.x == 100
        {
            self.x = 0
            self.score += Int(self.moving.speed)
            self.scoreLabelNode.text = String(self.score)
            print(self.score)
        } else if self.x == 50
        {
            self.score += 1
        }
        
        return .continue
        }
    }
    
    func endGame() {
        
        print("bird:" + String(describing: bird.position.x))
        if bird.position.x < 0
        {
            touchCounter = 3
            self.moving.speed = 1
            timer.stop()
            gameOverLabel = SKLabelNode(fontNamed:"MarkerFelt-Wide")
            gameOverLabel.fontColor = #colorLiteral(red: 0.521568656, green: 0.1098039225, blue: 0.05098039284, alpha: 1)
            gameOverLabel.fontSize = 96
            gameOverLabel.position = CGPoint( x: self.frame.width * 1.5, y: self.frame.midY )
            gameOverLabel.zPosition = 100
            gameOverLabel.text = String("GAME OVER!")
            self.addChild(gameOverLabel)
            gameOverLabel.run(SKAction.moveBy(x: -self.frame.width, y:0.0, duration:TimeInterval(0.001 * self.frame.width)))
            bird.run(SKAction.moveBy(x: -self.frame.width, y:0.0, duration:TimeInterval(0.001 * self.frame.width)))
            gameOver = true
            
        }
        
    }
}
