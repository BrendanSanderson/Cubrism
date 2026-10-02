import UIKit
import SpriteKit

/// Art resolution is independent of logical SpriteKit sizes and collision geometry.
/// All named images pass through this catalog; legacy names remain stable save-data keys.
enum GameArt {
    static let ink = UIColor(red: 0.09, green: 0.12, blue: 0.13, alpha: 1)
    static let ivory = UIColor(red: 0.95, green: 0.91, blue: 0.80, alpha: 1)
    static let gold = UIColor(red: 0.68, green: 0.51, blue: 0.25, alpha: 1)
    static let emerald = UIColor(red: 0.18, green: 0.55, blue: 0.32, alpha: 1)
    static let ice = UIColor(red: 0.49, green: 0.81, blue: 0.88, alpha: 1)
    static let tiers: [UIColor] = [.systemGreen, .systemBlue, .systemPurple, gold]
    private static var images = [String: UIImage]()
    private static var textures = [String: SKTexture]()
    static let enemies = ["meleeEnemy", "rangeEnemy", "rangeTrackingEnemy", "rangeTrippleEnemy", "rangeRingEnemy", "dashEnemy", "bomberEnemy", "sludgeEnemy", "suicideEnemy"]
    static let items = ["Pulsar", "Special Pulsar", "Shield", "Armor Core", "Power Core", "Attachment"]
    static let bosses = ["generatorBoss", "dragonBoss", "golemBoss", "bossEnergy"]

    struct Arena {
        let title: String
        let assetName: String
        // Measured floor opening in the source image, in top-left normalized coordinates.
        let opening: CGRect
    }
    static let arenas = [
        Arena(title: "Reactor Arcade", assetName: "StyleReactorArena", opening: CGRect(x: 0.058, y: 0.107, width: 0.884, height: 0.77)),
        Arena(title: "Cargo Hold", assetName: "StyleCargoArena", opening: CGRect(x: 0.086, y: 0.14, width: 0.828, height: 0.706)),
        Arena(title: "Bio Lab", assetName: "StyleBioArena", opening: CGRect(x: 0.06, y: 0.115, width: 0.88, height: 0.745)),
        Arena(title: "Fungal Hollow", assetName: "StyleFungalArena", opening: CGRect(x: 0.068, y: 0.125, width: 0.864, height: 0.725)),
        Arena(title: "Coral Vault", assetName: "StyleCoralArena", opening: CGRect(x: 0.078, y: 0.157, width: 0.844, height: 0.68)),
        Arena(title: "Clockwork Ruins", assetName: "StyleClockworkArena", opening: CGRect(x: 0.075, y: 0.138, width: 0.852, height: 0.705)),
        Arena(title: "Storm Citadel", assetName: "StyleStormArena", opening: CGRect(x: 0.084, y: 0.145, width: 0.832, height: 0.69)),
        Arena(title: "Orbital Scrapyard", assetName: "StyleOrbitalArena", opening: CGRect(x: 0.072, y: 0.14, width: 0.856, height: 0.72)),
        Arena(title: "Alien Hive", assetName: "StyleHiveArena", opening: CGRect(x: 0.08, y: 0.14, width: 0.845, height: 0.733)),
        Arena(title: "Molten Forge", assetName: "StyleForgeArena", opening: CGRect(x: 0.068, y: 0.12, width: 0.864, height: 0.758))
    ]

    static func arena(forGlobalLevel level: Int) -> Arena {
        arenas[(max(1, min(50, level)) - 1) / 5]
    }

    /// Common equipment uses the white family icon. Saved cosmetic variants are
    /// independent of rarity and retain their original 0...3 identifiers.
    static func imageName(for item: Item) -> String {
        guard let equipment = item as? Equipment, equipment.tier > 1 else { return item.type }
        return equipment.type + String(equipment.variant)
    }

    static func texture(_ name: String) -> SKTexture {
        if let cached = textures[name] { return cached }
        let result = SKTexture(image: image(name) ?? UIImage())
        result.filteringMode = .linear
        textures[name] = result
        return result
    }
    static func sprite(_ name: String) -> SKSpriteNode {
        SKSpriteNode(texture: texture(name))
    }
    static func image(_ name: String) -> UIImage? {
        if let cached = images[name] { return cached }
        let original = UIImage(named: name)
        if let arena = arenas.first(where: { $0.assetName == name }), let source = original {
            // Use an integer Retina scale to keep the logical size exact after pixel rounding.
            let size = GameScene.arenaSize
            let result = render(size) { rect in
                let target = rect.insetBy(dx: rect.width * 0.05, dy: rect.height * 0.1)
                drawArena(source, opening: arena.opening, target: target)
            }
            images[name] = result
            return result
        }
        // Keep the original projectile silhouettes, especially the tracking bullet.
        if name.lowercased().contains("shot") || name.hasPrefix("bombLit") ||
            ["bossDragonFireball", "bossGolemRock", "enemySludge"].contains(name) {
            return original
        }
        let size = original?.size ?? CGSize(width: 32, height: 32)
        // Attack and movement frames must use the same art as the idle boss.
        if name.hasPrefix("dragonMouth"), let frame = Int(name.dropFirst("dragonMouth".count)),
           let dragon = cell("StyleBosses", 1, columns: 2, rows: 2) {
            let result = render(size) { rect in
                let gap = rect.height * CGFloat(max(0, min(4, frame))) * 0.012
                let context = UIGraphicsGetCurrentContext()!
                for upper in [true, false] {
                    context.saveGState()
                    UIRectClip(CGRect(x: 0, y: upper ? 0 : rect.midY, width: rect.width, height: rect.height / 2))
                    dragon.draw(in: rect.insetBy(dx: 0, dy: gap).offsetBy(dx: 0, dy: upper ? -gap : gap))
                    context.restoreGState()
                }
            }
            images[name] = result
            return result
        }
        if name.hasPrefix("golemJump"), let frame = Int(name.dropFirst("golemJump".count)),
           let golem = cell("StyleBosses", 2, columns: 2, rows: 2) {
            let result = render(size) { rect in
                let inset = rect.width * CGFloat(max(0, min(8, frame))) * 0.006
                golem.draw(in: rect.insetBy(dx: inset, dy: 0))
            }
            images[name] = result
            return result
        }
        var source: UIImage?
        if let index = enemies.firstIndex(of: name) { source = cell("StyleEnemies", index, columns: 3, rows: 3) }
        if let index = bosses.firstIndex(of: name) { source = cell("StyleBosses", index, columns: 2, rows: 2) }
        if name == "playerIcon" {
            let result = render(size) { rect in
                panel(rect, fill: UIColor(red:1,green:0.81,blue:0.02,alpha:1), radius:4)
                ivory.withAlphaComponent(0.5).setFill()
                UIRectFill(CGRect(x:4,y:3,width:rect.width-8,height:2))
            }
            images[name] = result; return result
        }
        if name == "playerCannon" { source = cell("StyleGun", 0, columns: 1, rows: 1) }
        let family = items.first { name == $0 || (name.hasPrefix($0) && Int(name.dropFirst($0.count)) != nil) }
        if let family = family {
            let suffix = String(name.dropFirst(family.count))
            let variant = Int(suffix)
            if suffix.isEmpty || (variant.map { (0...3).contains($0) } ?? false) {
                let sheet = "Style" + family.replacingOccurrences(of: " ", with: "")
                // Atlas order: white, green, blue, purple, orange, empty.
                source = cell(sheet, variant.map { $0 + 1 } ?? 0, columns: 3, rows: 2)
            }
        }
        if let source = source {
            // Keep the same point size but enough pixels for enlarged item details.
            let scale: CGFloat = family == nil ? 3 : max(3, 288 / max(size.width, size.height))
            let result = render(size, scale: scale) { rect in
                if family != nil {
                    // Preserve gun/shield proportions within the existing square slot.
                    // A small gutter keeps the silhouette clear of the rarity frame.
                    let bounds = rect.insetBy(dx: rect.width * 0.04, dy: rect.height * 0.04)
                    let scale = min(bounds.width / source.size.width, bounds.height / source.size.height)
                    let fitted = CGSize(width: source.size.width * scale, height: source.size.height * scale)
                    source.draw(in: CGRect(x: rect.midX - fitted.width / 2, y: rect.midY - fitted.height / 2,
                                           width: fitted.width, height: fitted.height))
                } else {
                    source.draw(in: rect)
                }
            }
            images[name] = result
            return result
        }
        if let result = interface(name, size: size) { images[name] = result; return result }
        return original
    }
    static func render(_ size: CGSize, scale: CGFloat = 3, draw: (CGRect) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in draw(CGRect(origin: .zero, size: size)) }
    }
    private static func drawArena(_ source: UIImage, opening: CGRect, target: CGRect) {
        let width = target.width / opening.width
        let height = target.height / opening.height
        source.draw(in: CGRect(x: target.minX - opening.minX * width,
                               y: target.minY - opening.minY * height,
                               width: width, height: height))
    }
    private static func cell(_ sheet: String, _ index: Int, columns: Int, rows: Int) -> UIImage? {
        let key = "\(sheet)-\(index)"
        if let cached = images[key] { return cached }
        guard let cg = UIImage(named: sheet)?.cgImage else { return nil }
        let w = cg.width / columns, h = cg.height / rows
        guard let crop = cg.cropping(to: CGRect(x: index % columns * w, y: index / columns * h, width: w, height: h)) else { return nil }
        // Strip transparent gutters once, while retaining art resolution for Retina displays.
        var bytes = [UInt8](repeating: 0, count: w * h * 4)
        guard let context = CGContext(data: &bytes, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.draw(crop, in: CGRect(x: 0, y: 0, width: w, height: h))
        var minX = w, minY = h, maxX = 0, maxY = 0
        for y in 0..<h { for x in 0..<w where bytes[(y * w + x) * 4 + 3] > 24 {
            minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
        }}
        guard minX <= maxX, minY <= maxY else { return nil }
        let rect = CGRect(x: minX, y: minY, width: maxX-minX+1, height: maxY-minY+1)
        // CGContext's data rows use the same raster order for the crop's alpha bounds.
        let result = UIImage(cgImage: crop.cropping(to: rect) ?? crop)
        images[key] = result
        return result
    }
    static func panel(_ rect: CGRect, fill: UIColor = ink, radius: CGFloat = 5) {
        let path = UIBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), cornerRadius: radius)
        fill.setFill(); path.fill(); gold.setStroke(); path.lineWidth = 1; path.stroke()
        let inner = UIBezierPath(roundedRect: rect.insetBy(dx: 3, dy: 3), cornerRadius: max(1, radius-2))
        ivory.withAlphaComponent(0.14).setStroke(); inner.lineWidth = 0.6; inner.stroke()
    }
    static func symbol(_ name: String, in rect: CGRect, color: UIColor = ivory) {
        let config = UIImage.SymbolConfiguration(pointSize: max(8, rect.height), weight: .semibold)
        guard let icon = UIImage(systemName: name, withConfiguration: config)?.withTintColor(color, renderingMode: .alwaysOriginal) else { return }
        let scale = min(rect.width/icon.size.width, rect.height/icon.size.height)
        let size = CGSize(width: icon.size.width*scale, height: icon.size.height*scale)
        icon.draw(in: CGRect(x: rect.midX-size.width/2, y: rect.midY-size.height/2, width: size.width, height: size.height))
    }
    static func styleJoystick(_ joystick: AnalogJoystick, aiming: Bool) {
        joystick.substrate.image = render(CGSize(width:100,height:100)) { rect in
            ink.withAlphaComponent(0.55).setFill(); UIBezierPath(ovalIn:rect.insetBy(dx:2,dy:2)).fill()
            gold.withAlphaComponent(0.6).setStroke(); let rim = UIBezierPath(ovalIn:rect.insetBy(dx:3,dy:3)); rim.lineWidth=1.5; rim.stroke()
        }
        joystick.stick.image = render(CGSize(width:60,height:60)) { rect in
            ink.withAlphaComponent(0.85).setFill(); UIBezierPath(ovalIn:rect.insetBy(dx:2,dy:2)).fill()
            symbol(aiming ? "scope" : "arrow.up.and.down.and.arrow.left.and.right", in:rect.insetBy(dx:15,dy:15), color:aiming ? ice : ivory)
        }
    }
    static func bar(size: CGSize, color: UIColor?, top: Bool? = nil) -> UIImage {
        render(size) { rect in
            let path = UIBezierPath(roundedRect: rect.insetBy(dx: 0.7, dy: 0.7), cornerRadius: rect.height/2)
            path.addClip()
            if let top = top {
                UIRectClip(CGRect(x: 0, y: top ? 0 : rect.height/2, width: rect.width, height: rect.height/2))
            }
            (color ?? ink).setFill(); path.fill()
            if color != nil {
                ivory.withAlphaComponent(0.14).setFill()
                UIRectFill(CGRect(x: 0, y: top == false ? rect.height/2 : 0, width: rect.width, height: rect.height * 0.12))
            } else { gold.setStroke(); path.lineWidth = 1.4; path.stroke() }
        }
    }
    private static func interface(_ name: String, size: CGSize) -> UIImage? {
        if name == "popUp" { return render(size) { panel($0, radius: 10) } }
        if ["background1", "backgroundInner1"].contains(name),
           let arena = UIImage(named: "StyleReactorArena") {
            return render(size) { rect in
                // The painted opening is slightly inset from the gameplay bounds.
                // Fit that opening to the existing 90% x 80% collision rectangle;
                // the outermost art is clipped, without changing the arena or sprites.
                let target = name == "background1"
                    ? rect.insetBy(dx: rect.width * 0.05, dy: rect.height * 0.1) : rect
                drawArena(arena, opening: arenas[0].opening, target: target)
            }
        }
        if name.hasPrefix("backgroundInner"), let floor = UIImage(named: "StyleFloor") {
            return render(size) { rect in
                floor.draw(in: rect)
                let world = Int(name.replacingOccurrences(of: "backgroundInner", with: "")) ?? 1
                let colors: [UIColor] = [.clear, UIColor(white: 0.12, alpha: 0.58), UIColor(red:0.15,green:0.52,blue:0.74,alpha:0.45), UIColor(red:0.28,green:0.10,blue:0.03,alpha:0.60), UIColor(red:0.15,green:0.30,blue:0.02,alpha:0.48)]
                colors[max(0,min(4,world-1))].setFill(); UIRectFillUsingBlendMode(rect, .sourceAtop)
            }
        }
        if name.hasPrefix("background") {
            return render(size) { rect in
                ink.setFill(); UIRectFill(rect)
                let step: CGFloat = max(16, rect.width/16)
                for y in stride(from: CGFloat(0), to: rect.height, by: step) {
                    for x in stride(from: CGFloat(0), to: rect.width, by: step) {
                        let brick = CGRect(x:x+1,y:y+1,width:step-2,height:step-2)
                        UIColor(white:0.17 + CGFloat(Int(x+y) % 3)*0.015,alpha:1).setFill()
                        UIBezierPath(roundedRect:brick,cornerRadius:2).fill()
                        UIColor(white:0.28,alpha:1).setFill()
                        UIRectFill(CGRect(x:brick.minX+2,y:brick.minY+1,width:brick.width-4,height:1))
                    }
                }
            }
        }
        if name == "golemBlock" {
            return render(size) { rect in panel(rect, fill: gold, radius: 2) }
        }
        if name == "experienceFill" { return bar(size:CGSize(width:188,height:15),color:gold) }
        if name.contains("Bar") {
            let topHalf: Bool? = name.hasPrefix("health") ? true : name.hasPrefix("shield") ? false : nil
            let color: UIColor? = name.hasSuffix("Bottom") ? nil : name.hasPrefix("health") ? emerald : name.hasPrefix("shield") ? ice : UIColor(red:0.73,green:0.24,blue:0.18,alpha:1)
            return bar(size: size, color: color, top: topHalf)
        }
        let symbols = ["pauseButton":"pause.fill", "backButton":"chevron.left", "closeButton":"xmark", "bank":"building.columns.fill", "merchant":"storefront.fill", "lockedCell":"lock.fill", "noEquipment":"square.dashed"]
        if let icon = symbols[name] { return render(size) { rect in panel(rect); symbol(icon, in: rect.insetBy(dx:rect.width*0.22,dy:rect.height*0.22)) } }
        if name.contains("Door") {
            return render(size) { rect in
                panel(rect, fill: UIColor(white:0.19,alpha:1), radius:2)
                let unlocked = name.contains("Unlock")
                let locked = name.contains("Lock") && !unlocked
                let icon = name.contains("Boss") ? "diamond.fill" : locked ? "lock.fill" : unlocked ? "lock.open.fill" : "arrow.up"
                symbol(icon, in: rect.insetBy(dx:rect.width*0.22,dy:rect.height*0.22), color: name.contains("Boss") ? .systemRed : gold)
            }
        }
        if name.hasPrefix("tier") {
            let tier = Int(name.dropFirst(4)) ?? 1
            return render(size) { rect in
                let path = UIBezierPath(roundedRect:rect.insetBy(dx:1,dy:1),cornerRadius:3)
                tiers[max(0,min(3,tier-1))].setStroke(); path.lineWidth=2; path.stroke()
            }
        }
        if name == "Cubrixel" { return render(size) { rect in panel(rect); symbol("cube.fill", in:rect.insetBy(dx:3,dy:3),color:gold) } }
        if name == "loadingScreen" { return render(size) { rect in
            panel(rect); let text = "CUBRISM" as NSString
            let font = UIFont(name: Constants.fontB, size:rect.width*0.13) ?? .boldSystemFont(ofSize:32)
            let attrs: [NSAttributedString.Key:Any] = [.font:font,.foregroundColor:gold]
            let s = text.size(withAttributes:attrs)
            text.draw(at:CGPoint(x:(rect.width-s.width)/2,y:(rect.height-s.height)/2),withAttributes:attrs)
        } }
        return nil
    }
}
