
import SpriteKit
import GameplayKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


class RoomScene: GameScene {
    var doors = [DoorEntity]()      
    var maze = [[RoomScene]]()
    var entites = [DynamicEntity]()
    var startPosition = CGPoint()
    var killedEnemies = 0
    var enemies = 2
    var playerEntity = PlayerEntity()
    var completed = false
    var startTime: TimeInterval!
    var viewController: FloorViewController!
    var enemyPoints = 4
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        killedEnemies = 0
        addEntities()
        addDoors()
        world = viewController.world
        super.didMove(to: view)
        Player.damagePlayer(0)
    }
    
    
        override func willMove(from view: SKView) {
        self.removeAllChildren()
        for i in 0 ..< entites.count
        {
            entites[i].alive = false
        }
        super.willMove(from: view)
    }
    
    
//    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//    }

    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
//        if (startTime == nil)
//        {
//            startTime = currentTime
//        }
//        else if (startTime + 0.5 <= currentTime)
//        {
        if (started == true)
        {
            super.update(currentTime)
            for i in 0 ..< entites.count
            {
                entites[i].act(currentTime)
            }
            Player.act()
        }
    }
    
    func addEntities()
    {
        addPlayer()
        if (self.name == "room" && completed == false)
        {
            //entites.append(EnemyEntity(scene: self, eType: "RangeRing", lev: 1, elite: false))
            addEnemies()
        }
        else if (self.name == "bossRoom" && completed == false)
        {
            addBoss()
        }
    }
    
    
    func addPlayer()
    {
        
        Player.entity = PlayerEntity(scene: self, position: startPosition)
        Player.currentScene = self
    }
    func addDoors()
    {
        for i in 0..<(doors.count) {
            let tempPointer = doors[i].pointer
            doors[i] = DoorEntity(scene: self, direction: doors[i].direction, type: doors[i].type)
            doors[i].pointer = tempPointer
            self.addChild(doors[i].node)
        }
        if (completed == true && self.name == "bossRoom")
        {
            addTeleporter(CGPoint(x: self.size.width/2, y: self.size.height/2))
        }
    }
    
    
    
    func addEnemies()
    {
//        var mobs: NSArray?
//        if let path = NSBundle.mainBundle().pathForResource("rooms", ofType: "plist"), dict = NSArray(contentsOfFile: path){
//            let room = dict[Int(arc4random_uniform(UInt32(dict.count)))] as? NSDictionary
//            mobs = room?.valueForKey("mobs") as? NSArray
//            for i in 0 ..< mobs!.count
//            {
//                entites.append(EnemyEntity(scene: self, eType: (mobs![i].valueForKey("type") as? String)!, lev: (mobs![i].valueForKey("level") as? Int)!, elite: (mobs![i].valueForKey("elite") as? Bool)!))
//            }
//            enemies = mobs!.count
//            
//        }

        if let path = Bundle.main.path(forResource: "Enemies", ofType: "plist"), let enemiesArray = NSArray(contentsOfFile: path){
                var remainPoints = enemyPoints
                var totalEnemies = 0
                while remainPoints >= 1
                {
                    let en = enemiesArray[Int(arc4random_uniform(UInt32(enemiesArray.count)))] as? NSDictionary
                    if (en!.value(forKey: "points") as? Int) <= remainPoints && (en!.value(forKey: "minLevel") as? Int) <= viewController.level
                    {
                        var num = 0
                        for i in 0 ..< entites.count
                        {
                            if (entites[i] as? EnemyEntity)!.type == (en!.value(forKey: "name") as? String)
                            {
                                num += 1
                            }
                        }
                        if num < (en!.value(forKey: "max") as? Int)
                        {
                            entites.append(EnemyEntity(scene: self, eType: (en!.value(forKey: "name") as? String)!, lev: (en!.value(forKey: "level") as? Int)!, elite: (en!.value(forKey: "elite") as? Bool)!))
                            remainPoints -= (en!.value(forKey: "points") as? Int)!
                            totalEnemies += 1
                        }
                    }
                }
                enemies = totalEnemies
                
            }
        
    }
    func addBoss()
    {
        if let path = Bundle.main.path(forResource: "bosses", ofType: "plist"), let dict = NSArray(contentsOfFile: path){
            let boss = dict[Int(arc4random_uniform(UInt32(dict.count)))] as? NSDictionary
            //let boss = dict[2] as? NSDictionary
            entites.append(BossEntity(scene: self, properties: boss!))
        }
        enemies = 1
    }
    
    
    
    
    func addDoor(_ direction: Int)
    {
        let door = DoorEntity(scene: self, direction: direction, type: "regular")
        door.node.zPosition = 10
        self.addChild(door.node)
    }
    override func killEnemy(_ exp: Double) {
        killedEnemies += 1
        Player.currentViewController.levelExp += Int(exp)
        if (killedEnemies == enemies)
        {
            let roomExp = 10 * Constants.expMultiplier(viewController.level)
            Player.currentViewController.levelExp += Int(roomExp)
            unlockDoors()
        }
    }
    func addTeleporter(_ point: CGPoint)
    {
        //  let teleporterSprite = SKSpriteNode(color: UIColor.whiteColor(), size: CGSize(width: 64, height: 32))
        let teleporterSprite = SKSpriteNode(imageNamed: "horizontalDoor")
        let teleporterNode = SKNode();
        teleporterNode.addChild(teleporterSprite)
        teleporterSprite.position = point
        self.addChild(teleporterNode)
        teleporterSprite.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        teleporterSprite.physicsBody?.allowsRotation = false
        teleporterSprite.physicsBody?.affectedByGravity = false;
        teleporterSprite.physicsBody?.isDynamic = false
        teleporterSprite.physicsBody?.friction = 0;
        teleporterSprite.physicsBody?.usesPreciseCollisionDetection = true
        teleporterSprite.physicsBody?.contactTestBitMask = Constants.playerCategory
        teleporterSprite.physicsBody?.categoryBitMask = Constants.teleporterCategory

    }
    func unlockDoors()
    {
        completed = true
        for i in 0..<(doors.count)
        {
            if doors[i].type == "challenge"
            {
                if (doors[i].direction == 0 || doors[i].direction == 2)
                {
                    doors[i].type = "completed"
                    doors[i].sprite.texture = SKTexture(imageNamed: "horizontalDoorUnlock")}
                else
                {
                    doors[i].type = "completed"
                    doors[i].sprite.texture = SKTexture(imageNamed: "verticalDoorUnlock")
                }
                doors[i].sprite.physicsBody?.categoryBitMask = Constants.doorCategory
            }
            else if doors[i].type == "bossChallenge"
            {
                if (doors[i].direction == 0 || doors[i].direction == 2)
                {
                    doors[i].type = "bossCompleted"
                    doors[i].sprite.texture = SKTexture(imageNamed: "horizontalDoorBossUnlock")}
                else
                {
                    doors[i].type = "bossCompleted"
                    doors[i].sprite.texture = SKTexture(imageNamed: "verticalDoorBossUnlock")
                }
                doors[i].sprite.physicsBody?.categoryBitMask = Constants.doorCategory
            }

        }
    }
}
    
