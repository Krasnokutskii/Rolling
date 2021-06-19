//
//  GameScene.swift
//  project26
//
//  Created by Ярослав on 5/8/21.
//
import CoreMotion
import SpriteKit

enum CollisionTypes: UInt32{
    case player = 1
    case wall = 2
    case star = 4
    case vortex = 8
    case finish = 16
    case teleport = 32
    case teleport2 = 64
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
   
    var player: SKSpriteNode!
    var lastTouchPosition: CGPoint?
    var motionManager: CMMotionManager!
    
    var isGameOver = false
    
    var scoreLabel: SKLabelNode!
    var score = 0 {
        didSet{
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var levelLabel: SKLabelNode!
    var currentLevel = 1{
        didSet{
            levelLabel.text = "Level: \(currentLevel)"
        }
    }
    
    override func didMove(to view: SKView) {
       
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        
        loadLevel()
       // createPlayer()
       
       
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        if nodeA == player{
            playerCollided(with: nodeA)
        }else if nodeB == player{
            playerCollided(with: nodeA)
        }
        
    }
    
    func playerCollided(with node: SKNode){
        
        func teleportOut(){
            //let move = SKAction.move(to: node.position, duration: 0.25)
            let scaleIn = SKAction.scale(to: 0.0001, duration: 0.0001)
            let scaleOut = SKAction.scale(to: 1, duration: 0.25)
            
            let sequence = SKAction.sequence([scaleIn,scaleOut])
            createPlayer(position: CGPoint(x: 160 , y: 160))
            node.name = ""
            player.run(sequence){
                node.removeFromParent()
            }
        }
        
        func teleportIn(){
            let move = SKAction.move(to: node.position, duration: 0.25)
            let scale = SKAction.scale(to: 0.0001, duration: 0.25)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([move,scale,remove])
            node.name = ""
            player.run(sequence){
                node.removeFromParent()
                teleportOut()
                
                
            }
        }
        
       
        
        if node.name == "vortex"{
            player.physicsBody?.isDynamic = false
            isGameOver = true
            score  -= 1
            
            let move = SKAction.move(to: node.position, duration: 0.25)
            let scale = SKAction.scale(to: 0.0001, duration: 0.25)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([move,scale,remove])
            
            player.run(sequence){ [weak self] in
                self?.createPlayer()
                self?.isGameOver = false
            }
        }else if node.name == "star"{
            node.removeFromParent()
            score += 1
        }else if node.name == "finish"{
            nextLevel()
        }else if node.name == "teleport"{
            teleportIn()
        }else if node.name == "teleport2"{
            //teleport out?
        }
        
    }
    
    
    
    func createLevelLabel(){
        levelLabel = SKLabelNode(fontNamed: "Chalkduster")
        levelLabel.text = "Level 2"
        levelLabel.horizontalAlignmentMode = .center
        levelLabel.position = CGPoint(x: 950 , y: 16)
        levelLabel.zPosition = 2
        addChild(levelLabel)
    }
    func createScoreLabel(){
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: 16)
        scoreLabel.zPosition = 2
        addChild(scoreLabel)
    }
    
    func createPlayer(position: CGPoint = CGPoint(x: 96, y: 672)){
        player = SKSpriteNode(imageNamed: "player")
        player.position = position
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.allowsRotation = false // check out later
        player.physicsBody?.linearDamping = 0.5
        player.zPosition = 1
        
        player?.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player?.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
        player?.physicsBody?.contactTestBitMask = CollisionTypes.star.rawValue
        addChild(player)
    }
    
    func loadBackground(){
        let background = SKSpriteNode(imageNamed: "background")
         background.blendMode = .replace
         background.position = CGPoint(x: 512, y: 384)
         background.zPosition = -1
         addChild(background)
    }
    
    func loadLevel(){
        
        
        guard let levelUrl = Bundle.main.url(forResource: "level\(currentLevel)", withExtension: "txt") else {
            fatalError("Couldn't find level1.txt from the app bundle")
        }
        
        guard let levelStrig = try? String(contentsOf: levelUrl) else {
            fatalError("Couldn't load level.txt from app bundle")
        }
        createScoreLabel()
        createLevelLabel()
        loadBackground()
        
        let lines = levelStrig.components(separatedBy: "\n")
        
        for (row, line) in lines.reversed().enumerated(){
            for (column, letter) in line.enumerated(){
                let position = CGPoint(x: (64 * column) + 32, y: (64 * row) + 32)
                
                if letter == "x" {
                    loadWall(position: position)
                }else if letter == "v"{
                    loadVortex(position: position)
                }else if letter == "s"{
                   loadStar(position: position)
                }else if letter == "f"{
                    loadFinish(position: position)
                }else if letter == "t"{
                    loadTeleport(position: position)
                }else if letter == "z"{
                    loadTeleport2(position: position)
                }else if letter == " "{
                    
                }else{
                    fatalError("Unnown level letter \(letter)")
                }
            }
        }
        createPlayer()
    }
    
    func nextLevel(){
        removeAllChildren()
        currentLevel += 1 // can crash if level is not exist
        loadLevel()
    }
    
    func loadTeleport2(position: CGPoint){
        let node = SKSpriteNode(imageNamed: "teleport2")
        node.name = "teleport2"
        node.position = position
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width/2)
        node.physicsBody?.isDynamic = false
        
        node.physicsBody?.categoryBitMask = CollisionTypes.teleport2.rawValue
        node.physicsBody?.collisionBitMask = 0
        addChild(node)
    }
    
    
    func loadTeleport(position:CGPoint){
        let node = SKSpriteNode(imageNamed: "teleport")
        node.name = "teleport"
        node.position = position
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width/2)
        node.physicsBody?.isDynamic = false
        
        node.physicsBody?.categoryBitMask = CollisionTypes.teleport.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        addChild(node)
    }
    func loadFinish(position: CGPoint){
        let node = SKSpriteNode(imageNamed: "finish")
        node.name = "finish"
        node.position = position
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width/2)
        node.physicsBody?.isDynamic = false
        
        node.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        addChild(node)
    }
    
    func loadStar(position: CGPoint){
        let node = SKSpriteNode(imageNamed: "star")
        node.name = "star"
        node.position = position
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width/2)
        node.physicsBody?.isDynamic = false
        
        node.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        addChild(node)
    }
    
    func loadVortex(position: CGPoint){
        let node = SKSpriteNode(imageNamed: "vortex")
        node.name = "vortex"
        node.position = position
        node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1)))
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width/2)
        node.physicsBody?.isDynamic = false
        
        node.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        addChild(node)
    }
    
    func loadWall(position: CGPoint){
        let node = SKSpriteNode(imageNamed: "block")
        node.position = position
        
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
        node.physicsBody?.isDynamic = false
        addChild(node)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        guard isGameOver == false else { return }
        
        #if targetEnvironment(simulator)
        //simulator work
        if let currentTouch = lastTouchPosition {
            let diff = CGPoint(x: currentTouch.x - player.position.x, y: currentTouch.y - player.position.y)
            physicsWorld.gravity = CGVector(dx: diff.x/100, dy: diff.y/100)
        }
        #else
        // real device work
        if let accelerometerData = motionManager.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.y * -50, dy: accelerometerData.acceleration.x * 50)
        }
        #endif
        
        
    }
    
    
    
   
}

