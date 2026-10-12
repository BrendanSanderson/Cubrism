import UIKit

class CompletedViewController: UIViewController {
    var expGained = 10
    var floorLevel = 1
    var drops = [Item]()

    private let backdrop = UIImageView()
    private let shade = UIView()
    private let content = UIView()
    private let summary = UIView()
    private let seal = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
    private let titleLabel = UILabel()
    private let subtitle = UILabel()
    private let experienceTitle = UILabel()
    private let experience = UILabel()
    private let playerLevel = UILabel()
    private let nextLevel = UILabel()
    private let totalExperience = UILabel()
    private let progress = UIView()
    private let progressFill = UIView()
    private let lootTitle = UILabel()
    private let scroll = UIScrollView()
    private let rewards = UIStackView()
    private let emptyLoot = UILabel()
    private let footerNote = UILabel()
    private let button = UIButton(type: .system)
    private var iconConstraints = [NSLayoutConstraint]()

    override func viewDidLoad() {
        super.viewDidLoad()
        let arena = GameArt.arena(forGlobalLevel: floorLevel)
        backdrop.image = GameArt.image(arena.assetName)
        backdrop.contentMode = .scaleAspectFill
        backdrop.clipsToBounds = true
        shade.backgroundColor = GameArt.ink.withAlphaComponent(0.82)
        view.backgroundColor = GameArt.ink
        view.addSubview(backdrop)
        view.addSubview(shade)
        view.addSubview(content)
        content.accessibilityIdentifier = "completion.panel"
        stylePanel(content, color: GameArt.ink.withAlphaComponent(0.97), radius: 18)
        stylePanel(summary, color: UIColor(white: 1, alpha: 0.045), radius: 12)
        for child in [seal, titleLabel, subtitle, summary, lootTitle, scroll, emptyLoot, footerNote, button] {
            content.addSubview(child)
        }
        seal.tintColor = GameArt.ice
        seal.contentMode = .scaleAspectFit
        label(titleLabel, "Floor Complete!", size: 28, bold: true)
        label(subtitle, "Floor \(floorLevel) · \(arena.title)", size: 12, color: GameArt.ice)
        for child in [experienceTitle, experience, playerLevel, progress, nextLevel, totalExperience] {
            summary.addSubview(child)
        }
        label(experienceTitle, "EXPERIENCE EARNED", size: 10, bold: true, color: GameArt.ice)
        label(experience, "+\(expGained) XP", size: 38, bold: true)
        label(playerLevel, "Player level \(Player.level)", size: 14, bold: true)
        label(nextLevel, "\(max(0, Player.expToLevel(Player.level) - Player.exp)) XP to next level", size: 11)
        label(totalExperience, "\(Player.totalExp) total XP", size: 10, color: GameArt.ivory.withAlphaComponent(0.7))
        progress.backgroundColor = UIColor(white: 0, alpha: 0.4)
        progressFill.backgroundColor = GameArt.ice
        progressFill.layer.cornerRadius = 4
        progress.addSubview(progressFill)
        progress.layer.cornerRadius = 4
        progress.clipsToBounds = true
        progress.isAccessibilityElement = true
        progress.accessibilityLabel = "Experience progress"
        progress.accessibilityValue = "\(Player.exp) of \(Player.expToLevel(Player.level)) XP"
        label(lootTitle, "LOOT COLLECTED · \(drops.count)", size: 11, bold: true, color: GameArt.ice)
        scroll.accessibilityIdentifier = "completion.rewards"
        scroll.indicatorStyle = .white
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.addSubview(rewards)
        rewards.axis = .vertical
        rewards.spacing = 8
        rewards.distribution = .fillEqually
        for item in drops { addReward(item) }
        label(emptyLoot, "No items dropped this floor", size: 13)
        emptyLoot.isHidden = !drops.isEmpty
        label(footerNote, "Rewards added to your inventory", size: 11, color: GameArt.ivory.withAlphaComponent(0.7))
        button.setTitle("Continue  ›", for: .normal)
        button.titleLabel?.font = UIFont(name: Constants.fontB, size: 18)
        button.setTitleColor(GameArt.ink, for: .normal)
        button.backgroundColor = GameArt.gold
        button.layer.cornerRadius = 10
        button.accessibilityIdentifier = "completion.continue"
        button.addTarget(self, action: #selector(goToHome(_:)), for: .touchUpInside)
    }

    private func label(_ label: UILabel, _ text: String, size: CGFloat, bold: Bool = false, color: UIColor = GameArt.ivory) {
        label.text = text
        label.textColor = color
        label.font = UIFont(name: bold ? Constants.fontB : Constants.font, size: size)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
    }

    private func stylePanel(_ panel: UIView, color: UIColor, radius: CGFloat) {
        panel.backgroundColor = color
        panel.layer.cornerRadius = radius
        panel.layer.borderWidth = 1
        panel.layer.borderColor = GameArt.gold.withAlphaComponent(0.45).cgColor
    }

    private func addReward(_ item: Item) {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 8)
        stylePanel(row, color: UIColor(white: 1, alpha: 0.035), radius: 9)
        let icon = UIImageView(image: GameArt.image(GameArt.imageName(for: item)))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [icon.widthAnchor.constraint(equalToConstant: 48), icon.heightAnchor.constraint(equalToConstant: 48)]
        NSLayoutConstraint.activate(constraints)
        iconConstraints.append(contentsOf: constraints)
        let text = UIStackView()
        text.axis = .vertical
        text.spacing = 4
        let name = UILabel()
        let detail = UILabel()
        label(name, item.type, size: 14, bold: true)
        if let equipment = item as? Equipment {
            label(detail, "Level \(equipment.level) · Tier \(equipment.tier)", size: 11, color: GameArt.ice)
        } else {
            label(detail, "× \(item.quantity) collected", size: 11, color: GameArt.ice)
        }
        text.addArrangedSubview(name)
        text.addArrangedSubview(detail)
        row.addArrangedSubview(icon)
        row.addArrangedSubview(text)
        rewards.addArrangedSubview(row)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backdrop.frame = view.bounds
        shade.frame = view.bounds
        let safe = view.safeAreaLayoutGuide.layoutFrame
        let width = min(960, safe.width - 24)
        let height = min(540, safe.height - 16)
        content.frame = CGRect(x: safe.midX - width / 2, y: safe.midY - height / 2, width: width, height: height)
        let compact = height < 360
        let inset: CGFloat = compact ? 12 : 24
        let gap: CGFloat = compact ? 12 : 20
        let innerWidth = width - inset * 2
        seal.frame = CGRect(x: inset, y: inset + 3, width: 34, height: 34)
        titleLabel.frame = CGRect(x: inset + 46, y: inset, width: innerWidth - 46, height: compact ? 27 : 34)
        titleLabel.font = UIFont(name: Constants.fontB, size: compact ? 22 : 28)
        subtitle.frame = CGRect(x: titleLabel.frame.minX, y: titleLabel.frame.maxY + 2, width: titleLabel.frame.width, height: 16)
        let buttonWidth = min(200, innerWidth * 0.45)
        button.frame = CGRect(x: width - inset - buttonWidth, y: height - inset - 48, width: buttonWidth, height: 48)
        footerNote.frame = CGRect(x: inset, y: button.frame.midY - 10, width: button.frame.minX - inset - 12, height: 20)
        let bodyY = inset + (compact ? 44 : 58) + gap
        let bodyHeight = button.frame.minY - gap - bodyY
        summary.frame = CGRect(x: inset, y: bodyY, width: innerWidth * 0.37, height: bodyHeight)
        let textInset: CGFloat = compact ? 12 : 18
        let textWidth = summary.bounds.width - textInset * 2
        experienceTitle.frame = CGRect(x: textInset, y: textInset, width: textWidth, height: 15)
        experience.frame = CGRect(x: textInset, y: experienceTitle.frame.maxY + 3, width: textWidth, height: compact ? 34 : 48)
        experience.font = UIFont(name: Constants.fontB, size: compact ? 27 : 38)
        playerLevel.frame = CGRect(x: textInset, y: compact ? experience.frame.maxY + 8 : summary.bounds.midY, width: textWidth, height: 19)
        progress.frame = CGRect(x: textInset, y: playerLevel.frame.maxY + 6, width: textWidth, height: 8)
        let fraction = min(1, max(0, CGFloat(Player.exp) / CGFloat(max(1, Player.expToLevel(Player.level)))))
        progressFill.frame = CGRect(x: 0, y: 0, width: textWidth * fraction, height: 8)
        nextLevel.frame = CGRect(x: textInset, y: progress.frame.maxY + 6, width: textWidth, height: 16)
        totalExperience.frame = CGRect(x: textInset, y: nextLevel.frame.maxY + 4, width: textWidth, height: 16)
        totalExperience.isHidden = totalExperience.frame.maxY > bodyHeight - 8
        footerNote.text = totalExperience.isHidden ? "\(Player.totalExp) total XP · Rewards saved" : "Rewards added to your inventory"
        let lootX = summary.frame.maxX + gap
        let lootWidth = width - inset - lootX
        lootTitle.frame = CGRect(x: lootX, y: bodyY, width: lootWidth, height: 18)
        scroll.frame = CGRect(x: lootX, y: lootTitle.frame.maxY + 8, width: lootWidth, height: bodyHeight - 26)
        emptyLoot.frame = CGRect(x: lootX, y: scroll.frame.minY, width: lootWidth, height: 40)
        for constraint in iconConstraints { constraint.constant = compact ? 40 : 48 }
        let rowHeight: CGFloat = compact ? 50 : 68
        rewards.frame = CGRect(x: 0, y: 0, width: lootWidth, height: CGFloat(drops.count) * rowHeight + CGFloat(max(0, drops.count - 1)) * 8)
        rewards.layoutIfNeeded()
        scroll.contentSize = rewards.bounds.size
        scroll.contentOffset.y = min(scroll.contentOffset.y, max(0, scroll.contentSize.height - scroll.bounds.height))
    }

    @objc func goToHome(_ sender: UIButton!) {
        dismiss(animated: false) {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "GoToHomeViewController"), object: self)
        }
    }

    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
}
