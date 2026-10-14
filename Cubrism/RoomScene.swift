
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
    var entites = [DynamicEntity]()
    var startPosition = CGPoint()
    var killedEnemies = 0
    var enemies = 2
    var playerEntity = PlayerEntity()
    var completed = false
    var startTime: TimeInterval!
    weak var viewController: FloorViewController!
    override var arenaGlobalLevel: Int { viewController?.globalLevel ?? 1 }
    override var usesRestorableCombat: Bool { viewController?.usesRestorableCombat ?? false }
    var enemyPoints = 4
    var plannedRoom: DelveRoomPlan?
    var pendingWorld: DelveWorldState?
    private(set) var restoreError: Error?
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        killedEnemies = 0
        entites.removeAll()
        if pendingWorld != nil { addPlayer() }
        else { addEntities() }
        addDoors()
        if completed { unlockDoors() }
        world = viewController.world
        super.didMove(to: view)
        if let saved = pendingWorld, let plan = viewController.floorPlan {
            pendingWorld = nil
            do {
                try DelveWorldBridge.restore(saved, plan: plan, room: self)
                addChild(PopUpNode(scene: self, text: "Paused", button1Text: "Play", button2Text: "Quit"))
            } catch {
                isPaused = true
                restoreError = error
            }
        } else { Player.damagePlayer(0) }
    }
    
    
    override func willMove(from view: SKView) {
        physicsWorld.contactDelegate = nil
        func cancelActions(in node: SKNode) {
            node.removeAllActions()
            for child in node.children { cancelActions(in: child) }
        }
        cancelActions(in: self)
        self.removeAllChildren()
        for entity in entites { entity.retire() }
        entites.removeAll()
        liveMotions.removeAll()
        liveFuses.removeAll()
        for door in doors { door.removeComponent(ofType: VisualComponent.self) }
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
        super.update(currentTime)
        if usesRestorableCombat && isPaused { return }
        if (started == true)
        {
            for i in 0 ..< entites.count
            {
                entites[i].act(usesRestorableCombat ? time : currentTime)
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
        if case .combat(let mobs) = plannedRoom?.encounter {
            for mob in mobs {
                let position = CGPoint(x: mob.position.x * Double(size.width), y: mob.position.y * Double(size.height))
                entites.append(EnemyEntity(scene: self, eType: mob.kind.gameType,
                                          lev: mob.kind.isElite ? 5 : 1, elite: mob.kind.isElite,
                                          position: position, spawnID: mob.id, stats: combatStats?.enemies[mob.kind]))
            }
            enemies = entites.count
            return
        }
        guard let path = Bundle.main.path(forResource: "Enemies", ofType: "plist"),
              let definitions = NSArray(contentsOfFile: path) as? [[String: Any]] else {
            return
        }
        var remaining = Double(enemyPoints)
        var counts = [String: Int]()
        while remaining > 0 {
            let eligible = definitions.filter { definition in
                guard let cost = definition["points"] as? NSNumber,
                      let minLevel = definition["minLevel"] as? Int,
                      let limit = definition["max"] as? Int,
                      let name = definition["name"] as? String else { return false }
                return cost.doubleValue > 0 && cost.doubleValue <= remaining
                    && minLevel <= viewController.globalLevel && counts[name, default: 0] < limit
            }
            guard let definition = eligible.randomElement(),
                  let name = definition["name"] as? String,
                  let level = definition["level"] as? Int,
                  let elite = definition["elite"] as? Bool,
                  let cost = definition["points"] as? NSNumber else { break }
            entites.append(EnemyEntity(scene: self, eType: name, lev: level, elite: elite))
            counts[name, default: 0] += 1
            remaining -= cost.doubleValue
        }
        enemies = entites.count
    }
    func addBoss()
    {
        if let path = Bundle.main.path(forResource: "bosses", ofType: "plist"), let dict = NSArray(contentsOfFile: path){
            let boss: NSDictionary?
            if case .boss(let kind) = plannedRoom?.encounter {
                boss = (dict as? [NSDictionary])?.first { $0["name"] as? String == kind.rawValue }
            } else {
                boss = dict[Int(arc4random_uniform(UInt32(dict.count)))] as? NSDictionary
            }
            //let boss = dict[2] as? NSDictionary
            let kind = (boss?["name"] as? String).flatMap(DelveBossKind.init(rawValue:))
            entites.append(BossEntity(scene: self, properties: boss!, stats: kind.flatMap { combatStats?.bosses[$0] },
                                      combatID: plannedRoom?.id))
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
        guard !completed else { return }
        killedEnemies += 1
        viewController.levelExp += Int(exp)
        if (killedEnemies == enemies)
        {
            let roomExp = 10 * Constants.expMultiplier(viewController.globalLevel)
            viewController.levelExp += Int(roomExp)
            unlockDoors()
        }
    }
    func addTeleporter(_ point: CGPoint)
    {
        //  let teleporterSprite = SKSpriteNode(color: UIColor.whiteColor(), size: CGSize(width: 64, height: 32))
        let teleporterSprite = GameArt.sprite("horizontalDoor")
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
                    doors[i].sprite.texture = GameArt.texture( "horizontalDoorUnlock")}
                else
                {
                    doors[i].type = "completed"
                    doors[i].sprite.texture = GameArt.texture( "verticalDoorUnlock")
                }
                doors[i].sprite.physicsBody?.categoryBitMask = Constants.doorCategory
            }
            else if doors[i].type == "bossChallenge"
            {
                if (doors[i].direction == 0 || doors[i].direction == 2)
                {
                    doors[i].type = "bossCompleted"
                    doors[i].sprite.texture = GameArt.texture( "horizontalDoorBossUnlock")}
                else
                {
                    doors[i].type = "bossCompleted"
                    doors[i].sprite.texture = GameArt.texture( "verticalDoorBossUnlock")
                }
                doors[i].sprite.physicsBody?.categoryBitMask = Constants.doorCategory
            }

        }
    }
}
    
