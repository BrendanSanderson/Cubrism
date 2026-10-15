import UIKit

/// A game-sized checkpoint surface. The account owns all rewards and transitions;
/// this view only presents a committed floor and forwards player choices.
@MainActor
final class DelveCheckpointView: UIView, UITableViewDataSource, UITableViewDelegate {
    let floorID: UUID
    var onContinue: (() -> Void)?
    var onExtract: (() -> Void)?
    var onInspect: ((DelveLoot) -> Void)?
    var onLoadout: (() -> Void)?

    private let canvas = UIView(frame: CGRect(origin: .zero, size: GameScene.arenaSize))
    private let score = UILabel(), gain = UILabel(), level = UILabel(), xpValue = UILabel(), xpGain = UILabel()
    private let xpBanner = CheckpointPanel([0x063c4d])
    private let xpFill = CheckpointPanel([0x13635e, 0x1c806b])
    private let healthTrack = UIView(), healthFill = CheckpointPanel([0x963e36, 0xb34d3f])
    private let healthLabel = UILabel(), burst = CheckpointBurstView()
    private let loot = UITableView(frame: .zero, style: .plain)
    private let extract = UIButton(type: .custom), descend = UIButton(type: .custom)
    private let loadout = UIButton(type: .system)
    private let account: DelveProgression
    private let groups: [(depth: Int?, items: [DelveLoot])]
    private let earnedXP: Double
    private var displayLink: CADisplayLink?
    private var startTime = 0.0
    private var didReveal = false

    init(account: DelveProgression) {
        let run = account.activeRun!
        precondition(run.floor.phase == .checkpoint)
        self.account = account
        floorID = run.floor.id
        let current = Set(run.floor.rewardIDs)
        let grouped = Dictionary(grouping: run.loot) { item in
            item.floorDepth ?? (current.contains(item.id) ? run.depth : nil)
        }
        groups = grouped.keys.sorted { ($0 ?? 0) > ($1 ?? 0) }.map { ($0, grouped[$0]!) }
        earnedXP = ((try? account.rules.balance.xpAllocations(for: run.floor.plan)) ?? [:]).values.reduce(0, +)
            * (1 + ((try? DelveRules.continuationBonus(depth: run.depth)) ?? 0))
        super.init(frame: .zero)
        accessibilityIdentifier = "delve.checkpoint"
        backgroundColor = GameArt.ink
        addSubview(canvas)
        canvas.clipsToBounds = true
        let frame = UIImageView(image: Self.reactorFrame)
        frame.frame = canvas.bounds
        canvas.addSubview(frame)

        xpBanner.frame = CGRect(x: 30, y: 25, width: 690, height: 32)
        xpBanner.layer.cornerRadius = 5; xpBanner.clipsToBounds = true
        canvas.addSubview(xpBanner); xpBanner.addSubview(xpFill)
        style(level, size: 12); style(xpValue, size: 11); style(xpGain, size: 13, color: 0x95efb9)
        [level, xpValue, xpGain].forEach { xpBanner.addSubview($0) }
        xpGain.text = "+\(DelvePresentation.number(earnedXP.rounded())) XP"
        xpGain.accessibilityIdentifier = "delve.xpGain"; xpGain.isAccessibilityElement = false
        xpFill.accessibilityIdentifier = "delve.xpFill"
        level.accessibilityIdentifier = "delve.characterLevel"; xpValue.accessibilityIdentifier = "delve.xpValue"
        xpBanner.isAccessibilityElement = true
        xpBanner.accessibilityIdentifier = "delve.xp"

        let title = UILabel(frame: CGRect(x: 40, y: 65, width: 357, height: 28))
        style(title, size: 20); title.font = UIFont(name: Constants.fontB, size: 20)
        title.textAlignment = .center; title.text = "Floor \(run.depth) Clear"
        canvas.addSubview(title)
        burst.frame = CGRect(x: 74, y: 96, width: 280, height: 160)
        burst.isUserInteractionEnabled = false; canvas.addSubview(burst)
        let caption = UILabel(frame: CGRect(x: 110, y: 126, width: 210, height: 16))
        style(caption, size: 11, color: 0xffe4ae); caption.text = "D E L V E"; caption.textAlignment = .center
        canvas.addSubview(caption)
        style(score, size: 72); score.font = UIFont(name: Constants.fontB, size: 72)
        score.textAlignment = .center; score.adjustsFontSizeToFitWidth = true; score.minimumScaleFactor = 0.35
        score.frame = CGRect(x: 70, y: 141, width: 290, height: 90)
        score.accessibilityIdentifier = "delve.rating"
        style(gain, size: 24, color: 0xb4ffe0); gain.font = UIFont(name: Constants.fontB, size: 24)
        gain.adjustsFontSizeToFitWidth = true; gain.minimumScaleFactor = 0.4
        gain.frame = CGRect(x: 315, y: 158, width: 78, height: 50)
        gain.text = "+\(DelvePresentation.number(account.rating - run.floor.entryRating))"
        canvas.addSubview(score); canvas.addSubview(gain)
        loadout.frame = CGRect(x: 351, y: 59, width: 44, height: 44)
        loadout.setImage(UIImage(systemName: "slider.horizontal.3"), for: .normal)
        loadout.tintColor = GameArt.ivory; loadout.accessibilityLabel = "Change loadout"
        loadout.accessibilityIdentifier = "delve.loadout"
        loadout.addAction(UIAction { [weak self] _ in self?.onLoadout?() }, for: .touchUpInside)
        canvas.addSubview(loadout)

        loot.frame = CGRect(x: 419, y: 65, width: 301, height: 193)
        loot.backgroundColor = .clear; loot.separatorStyle = .none
        loot.rowHeight = 56; loot.sectionHeaderHeight = 20; loot.sectionHeaderTopPadding = 0
        loot.contentInset.bottom = 5; loot.indicatorStyle = .white
        loot.register(CheckpointLootCell.self, forCellReuseIdentifier: "loot")
        loot.dataSource = self; loot.delegate = self
        loot.accessibilityIdentifier = "delve.runLoot"
        canvas.addSubview(loot)

        let footer = CheckpointPanel([0x096076, 0x064353])
        footer.frame = CGRect(x: 30, y: 266, width: 690, height: 82)
        footer.layer.cornerRadius = 7; canvas.addSubview(footer)
        let heart = UIImageView(image: UIImage(systemName: "heart"))
        heart.tintColor = CheckpointPanel.color(0xffbd91); heart.frame = CGRect(x: 6, y: 6, width: 16, height: 16)
        footer.addSubview(heart)
        healthTrack.frame = CGRect(x: 28, y: 6, width: 150, height: 16)
        healthTrack.backgroundColor = CheckpointPanel.color(0x07313c)
        healthTrack.layer.cornerRadius = 3; healthTrack.clipsToBounds = true
        healthTrack.addSubview(healthFill); healthTrack.addSubview(healthLabel)
        healthTrack.isAccessibilityElement = true; healthTrack.accessibilityIdentifier = "delve.health"
        healthLabel.frame = healthTrack.bounds; style(healthLabel, size: 11); healthLabel.textAlignment = .center
        footer.addSubview(healthTrack)
        let shield = UILabel(frame: CGRect(x: 285, y: 6, width: 150, height: 16))
        style(shield, size: 11, color: 0xc1dfdf); shield.text = "Shields refill"; shield.textAlignment = .center
        footer.addSubview(shield)
        let risk = UILabel(frame: CGRect(x: 475, y: 6, width: 209, height: 16))
        style(risk, size: 11, color: 0xffd2b6); risk.text = "Death loses \(run.loot.count) items"; risk.textAlignment = .right
        footer.addSubview(risk)
        let bonus = (try? DelveRules.continuationBonus(depth: run.depth + 1)) ?? 0
        configure(extract, title: "EXTRACT", subtitle: "Bank \(run.loot.count) items", colors: [0x16899d, 0x07566d], x: 6)
        configure(descend, title: "CONTINUE · \(run.depth + 1)", subtitle: "Rarity ↑ · +\(Int((bonus * 100).rounded()))% XP/Delve", colors: [0xffbf62, 0xe87112], x: 349.5)
        extract.accessibilityIdentifier = "delve.extract"; descend.accessibilityIdentifier = "delve.continue"
        extract.addAction(UIAction { [weak self] _ in self?.finishReveal(); self?.onExtract?() }, for: .touchUpInside)
        descend.addAction(UIAction { [weak self] _ in self?.finishReveal(); self?.onContinue?() }, for: .touchUpInside)
        footer.addSubview(extract); footer.addSubview(descend)
        update(account: account, enabled: true)
        showProgress(1)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    deinit { displayLink?.invalidate() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let scale = min(bounds.width / 750, bounds.height / 375)
        canvas.transform = CGAffineTransform(scaleX: scale, y: scale)
        canvas.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }

    func update(account: DelveProgression, enabled: Bool) {
        extract.isEnabled = enabled; descend.isEnabled = enabled; loadout.isEnabled = enabled
        loot.isUserInteractionEnabled = enabled
        [extract, descend, loadout].forEach { $0.alpha = enabled ? 1 : 0.55 }
        guard let resources = account.activeRun?.resources else { return }
        healthFill.frame = CGRect(x: 0, y: 0, width: 150 * resources.health / resources.maxHealth, height: 16)
        healthLabel.text = "\(DelvePresentation.number(resources.health)) / \(DelvePresentation.number(resources.maxHealth)) HP"
        healthTrack.accessibilityLabel = "Remaining health"
        healthTrack.accessibilityValue = healthLabel.text
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { finishReveal(); return }
        guard !didReveal else { return }
        didReveal = true
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        showProgress(0); startTime = CACurrentMediaTime()
        let link = CADisplayLink(target: CheckpointAnimationTarget(self), selector: #selector(CheckpointAnimationTarget.frame))
        displayLink = link; link.add(to: .main, forMode: .common)
    }

    fileprivate func animateFrame() {
        let progress = min(1, (CACurrentMediaTime() - startTime) / 1.6)
        showProgress(1 - pow(1 - progress, 2.2))
        if progress >= 1 {
            finishReveal()
            burst.layer.add(Self.impactAnimation, forKey: "clear")
            for cell in loot.visibleCells where groups[loot.indexPath(for: cell)!.section].depth == account.activeRun?.depth {
                cell.layer.add(Self.impactAnimation, forKey: "reward")
            }
        }
    }

    private func finishReveal() {
        displayLink?.invalidate(); displayLink = nil
        showProgress(1)
    }

    private func showProgress(_ progress: Double) {
        guard let run = account.activeRun else { return }
        score.text = DelvePresentation.number((run.floor.entryRating + (account.rating - run.floor.entryRating) * progress).rounded())
        let scoreWidth = min(220, ceil((score.text! as NSString).size(withAttributes: [.font: score.font!]).width) + 4)
        score.frame = CGRect(x: 214 - scoreWidth / 2, y: 141, width: scoreWidth, height: 90)
        gain.frame = CGRect(x: score.frame.maxX + 12, y: 158, width: min(78, 397 - score.frame.maxX - 12), height: 50)
        var xp = try! DelveExperience(levelUpCosts: account.experience.levelUpCosts)
        try! xp.award(max(0, account.experience.lifetime - earnedXP * (1 - progress)))
        level.text = "LV. \(xp.level)"
        let capped = xp.level == xp.cap
        let fraction = capped ? 1 : xp.progress / xp.levelUpCosts[xp.level - 1]
        let filled = 690 * fraction
        xpFill.frame = CGRect(x: 0, y: 0, width: filled, height: 32)
        let remaining = 690 - filled
        let levelOnRight = filled < 70
        level.frame = CGRect(x: levelOnRight ? 610 : 10, y: 0, width: levelOnRight ? 70 : min(70, filled - 20), height: 32)
        let end = filled >= 276 ? filled - 10 : (levelOnRight ? 600 : 680)
        xpValue.frame = CGRect(x: end - 180, y: 0, width: 180, height: 32); xpValue.textAlignment = .right
        xpValue.text = capped ? "MAX · Lifetime \(DelvePresentation.number(xp.lifetime)) XP"
            : "\(DelvePresentation.number(xp.progress)) / \(DelvePresentation.number(xp.levelUpCosts[xp.level - 1])) XP"
        if remaining >= 52 {
            if xpGain.superview !== xpBanner { xpBanner.addSubview(xpGain) }
            xpGain.frame = CGRect(x: filled + 10, y: 0, width: min(95, remaining - 20), height: 32)
            xpGain.textAlignment = .left
        } else {
            // A nearly full bar cannot contain readable gain text. Keep the
            // bar accurate and show the gain below the title instead.
            if xpGain.superview !== canvas { canvas.addSubview(xpGain) }
            xpGain.frame = CGRect(x: 134, y: 101, width: 160, height: 16)
            xpGain.textAlignment = .center
        }
        xpGain.adjustsFontSizeToFitWidth = true; xpGain.minimumScaleFactor = 0.6
        xpBanner.accessibilityLabel = "Character level \(xp.level)"
        xpBanner.accessibilityValue = "\(xpValue.text ?? ""). Gained \(DelvePresentation.number(earnedXP)) XP"
    }

    func numberOfSections(in tableView: UITableView) -> Int { groups.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { groups[section].items.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "loot", for: indexPath) as! CheckpointLootCell
        cell.configure(groups[indexPath.section].items[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let group = groups[section]
        let header = UILabel()
        style(header, size: 11, color: 0xcee6df); header.backgroundColor = CheckpointPanel.color(0x11586c)
        let current = group.depth == account.activeRun?.depth
        header.text = "  \(group.depth.map { "FLOOR \($0)" } ?? "EARLIER FLOORS") · \(group.items.count) \(current ? "NEW" : "ITEMS")"
        return header
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        onInspect?(groups[indexPath.section].items[indexPath.row])
    }

    private func style(_ label: UILabel, size: CGFloat, color: UInt32 = 0xfff4da) {
        label.font = .systemFont(ofSize: size, weight: .semibold)
        label.textColor = CheckpointPanel.color(color)
    }

    private func configure(_ button: UIButton, title: String, subtitle: String, colors: [UInt32], x: CGFloat) {
        button.frame = CGRect(x: x, y: 27, width: 334.5, height: 48)
        let panel = CheckpointPanel(colors); panel.frame = button.bounds
        panel.isUserInteractionEnabled = false; panel.layer.cornerRadius = 8; panel.layer.borderWidth = 2
        panel.layer.borderColor = CheckpointPanel.color(0x081b22).cgColor
        panel.layer.shadowColor = CheckpointPanel.color(0x06161d).cgColor
        panel.layer.shadowOpacity = 1; panel.layer.shadowOffset = CGSize(width: 0, height: 4); panel.layer.shadowRadius = 0
        button.addSubview(panel)
        let heading = UILabel(frame: CGRect(x: 4, y: 8, width: 326.5, height: 16))
        let caption = UILabel(frame: CGRect(x: 4, y: 26, width: 326.5, height: 13))
        let color: UInt32 = title.hasPrefix("CONTINUE") ? 0x281f17 : 0xf3e8cc
        style(heading, size: 13, color: color); style(caption, size: 11, color: color)
        heading.text = title; caption.text = subtitle
        heading.textAlignment = .center; caption.textAlignment = .center
        button.addSubview(heading); button.addSubview(caption)
        button.accessibilityLabel = "\(title). \(subtitle)"
    }

    private static var impactAnimation: CAAnimation {
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [0.94, 1.08, 1]; animation.keyTimes = [0, 0.4, 1]; animation.duration = 0.55
        return animation
    }

    private static let reactorFrame: UIImage = {
        guard let cg = UIImage(named: "StyleReactorArena")?.cgImage else { return UIImage() }
        // Use the same nine-slice proportions as the approved preview. Drawing a
        // resizable UIImage into another image does not preserve its cap insets.
        let inset = (CGFloat(cg.width) * 109 / 1100).rounded()
        let sourceX: [CGFloat] = [0, inset, CGFloat(cg.width) - inset, CGFloat(cg.width)]
        let sourceY: [CGFloat] = [0, inset, CGFloat(cg.height) - inset, CGFloat(cg.height)]
        let targetX: [CGFloat] = [0, 18, 732, 750], targetY: [CGFloat] = [0, 18, 357, 375]
        return GameArt.render(GameScene.arenaSize) { _ in
            for row in 0..<3 { for column in 0..<3 {
                let source = CGRect(x: sourceX[column], y: sourceY[row],
                    width: sourceX[column + 1] - sourceX[column], height: sourceY[row + 1] - sourceY[row])
                let target = CGRect(x: targetX[column], y: targetY[row],
                    width: targetX[column + 1] - targetX[column], height: targetY[row + 1] - targetY[row])
                if let crop = cg.cropping(to: source) { UIImage(cgImage: crop).draw(in: target) }
            }}
        }
    }()
}

@MainActor
private final class CheckpointAnimationTarget: NSObject {
    weak var view: DelveCheckpointView?
    init(_ view: DelveCheckpointView) { self.view = view }
    @objc func frame() { view?.animateFrame() }
}

@MainActor
private final class CheckpointPanel: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }
    init(_ colors: [UInt32]) {
        super.init(frame: .zero)
        (layer as! CAGradientLayer).colors = (colors.count == 1 ? colors + colors : colors).map { Self.color($0).cgColor }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    static func color(_ hex: UInt32) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
                blue: CGFloat(hex & 255) / 255, alpha: 1)
    }
}

@MainActor
private final class CheckpointLootCell: UITableViewCell {
    private let panel = CheckpointPanel([0x267d91, 0x0b455b])
    private let art = UIImageView(), name = UILabel(), rarity = UILabel()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear; selectionStyle = .none
        panel.layer.cornerRadius = 8; panel.layer.borderWidth = 2
        panel.layer.borderColor = CheckpointPanel.color(0x073647).cgColor
        contentView.addSubview(panel)
        art.contentMode = .scaleAspectFit; panel.addSubview(art)
        name.font = .systemFont(ofSize: 13, weight: .semibold); name.textColor = GameArt.ivory
        name.adjustsFontSizeToFitWidth = true; name.minimumScaleFactor = 0.7
        rarity.font = .systemFont(ofSize: 11, weight: .bold)
        panel.addSubview(name); panel.addSubview(rarity)
        isAccessibilityElement = true; accessibilityTraits = .button
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() {
        super.layoutSubviews()
        panel.frame = contentView.bounds.insetBy(dx: 0, dy: 2)
        art.frame = CGRect(x: 8, y: 3, width: 64, height: 46)
        name.frame = CGRect(x: 80, y: 10, width: max(0, panel.bounds.width - 90), height: 16)
        rarity.frame = CGRect(x: 80, y: 28, width: max(0, panel.bounds.width - 90), height: 13)
    }
    func configure(_ item: DelveLoot) {
        art.image = DelvePresentation.image(item); name.text = DelvePresentation.kind(item)
        rarity.text = DelvePresentation.rarity(item.rarity).uppercased()
        rarity.textColor = DelvePresentation.color(item.rarity)
        panel.layer.borderColor = DelvePresentation.color(item.rarity).withAlphaComponent(0.8).cgColor
        let colors: [UInt32] = item.rarity == .epic ? [0x58446b, 0x27324e] : item.rarity == .rare ? [0x166c8c, 0x103e60] : [0x267d91, 0x0b455b]
        (panel.layer as! CAGradientLayer).colors = colors.map { CheckpointPanel.color($0).cgColor }
        accessibilityIdentifier = "delve.loot.\(item.id.uuidString)"
        accessibilityLabel = DelvePresentation.name(item)
        accessibilityValue = item.floorDepth.map { "Floor \($0), unbanked" } ?? "Unbanked"
    }
}

@MainActor
private final class CheckpointBurstView: UIView {
    override init(frame: CGRect) { super.init(frame: frame); backgroundColor = .clear; isOpaque = false }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let gold = CheckpointPanel.color(0xffd278)
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [gold.withAlphaComponent(0.05).cgColor, gold.withAlphaComponent(0.52).cgColor, gold.withAlphaComponent(0).cgColor] as CFArray,
            locations: [0, 0.48, 1])!
        context.saveGState(); context.translateBy(x: center.x, y: center.y); context.scaleBy(x: 1.45, y: 1)
        context.drawRadialGradient(gradient, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: 88, options: [])
        context.restoreGState()
        for index in 0..<24 {
            let angle = CGFloat(index) * .pi / 12
            let path = UIBezierPath()
            path.move(to: CGPoint(x: center.x + cos(angle) * 58, y: center.y + sin(angle) * 48))
            path.addLine(to: CGPoint(x: center.x + cos(angle - 0.04) * 132, y: center.y + sin(angle - 0.04) * 80))
            path.addLine(to: CGPoint(x: center.x + cos(angle + 0.04) * 132, y: center.y + sin(angle + 0.04) * 80))
            path.close(); gold.withAlphaComponent(index.isMultiple(of: 2) ? 0.22 : 0.1).setFill(); path.fill()
        }
        for radius: CGFloat in [60, 65, 72] {
            let circle = UIBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            if radius == 72 { circle.setLineDash([4, 3], count: 2, phase: 0) }
            gold.withAlphaComponent(0.65).setStroke(); circle.lineWidth = radius == 65 ? 1 : 2; circle.stroke()
        }
    }
}
