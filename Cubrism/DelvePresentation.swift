import UIKit

// Player-facing names and item summaries are shared by loadout and loot lists.
enum DelvePresentation {
    static func number(_ value: Double) -> String { value.formatted(.number.precision(.fractionLength(0...1))) }

    static func name(_ slot: DelveEquipmentSlot) -> String {
        switch slot {
        case .powerCore: return "Power Core"
        case .armorCore: return "Armor Core"
        case .pulsar: return "Pulsar"
        case .specialPulsar: return "Special Pulsar"
        case .shield: return "Shield"
        case .attachmentOne: return "Attachment 1"
        case .attachmentTwo: return "Attachment 2"
        }
    }

    static func name(_ item: DelveLoot) -> String {
        "\(rarity(item.rarity)) \(kind(item)) · Power \(number(item.power))"
    }

    static func kind(_ item: DelveLoot) -> String {
        switch item.kind {
        case .powerCore: return "Power Core"
        case .armorCore: return "Armor Core"
        case .pulsar: return "Pulsar"
        case .specialPulsar: return "Special Pulsar"
        case .shield: return "Shield"
        case .attachment: return "\(item.attachmentStat == "AttackPower" ? "Attack" : item.attachmentStat ?? "") Attachment"
        }
    }

    static func image(_ item: DelveLoot) -> UIImage? {
        let family = item.kind == .attachment ? "Attachment" : kind(item)
        return GameArt.image(family + (item.rarity == .common ? "" : "\(item.variant)"))
    }

    static func rarity(_ rarity: DelveRarity) -> String {
        ["Common", "Uncommon", "Rare", "Epic", "Legendary"][rarity.rawValue]
    }

    static func color(_ rarity: DelveRarity) -> UIColor {
        [GameArt.ivory, .systemGreen, .systemBlue, .systemPurple, .systemOrange][rarity.rawValue]
    }

    static func stats(_ item: DelveLoot, balance: DelveBalance) -> String {
        guard let value = try? balance.itemStats(item) else { return "" }
        let fields = [("Attack", value.attackPower), ("HP", value.health), ("Shield", value.shield),
                      ("Armor", value.defence * 0.025), ("Attack speed", value.attackSpeed), ("Shield regen", value.shieldRegen)]
        return fields.filter { $0.1 > 0 }.map {
            "\($0.0) +\($0.1.formatted(.number.precision(.fractionLength(0...3))))"
        }.joined(separator: " · ")
    }
}
