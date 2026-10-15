import UIKit

@MainActor
final class DelveViewController: UIViewController {
    let session: DelveGameSession
    private let stack = UIStackView()
    private let scroll = UIScrollView()
    private var floor: FloorViewController?
    private var working = false
    private var notice: String?
    private var checkpoint: DelveCheckpointView?

    init(session: DelveGameSession) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
        session.onCommit = { [weak self] action in self?.committed(action) }
        session.onError = { [weak self] _ in self?.showSaveError() }
        session.onPause = { [weak self] in self?.showPause() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = GameArt.ink
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        stack.axis = .vertical; stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -48)
        ])
        render()
    }

    func render(resetScroll: Bool = false) {
        guard isViewLoaded else { return }
        let account = session.progression
        if let run = account.activeRun, run.floor.phase == .checkpoint {
            scroll.isHidden = true
            if checkpoint?.floorID != run.floor.id {
                stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
                checkpoint?.removeFromSuperview()
                let checkpoint = DelveCheckpointView(account: account)
                checkpoint.translatesAutoresizingMaskIntoConstraints = false
                self.checkpoint = checkpoint
                checkpoint.onContinue = { [weak self] in self?.perform { try await self?.session.continueFloor() } }
                checkpoint.onExtract = { [weak self] in self?.perform { try await self?.session.extract() } }
                checkpoint.onInspect = { [weak self] in self?.inspect($0) }
                checkpoint.onLoadout = { [weak self] in self?.showLoadout() }
                view.addSubview(checkpoint)
                NSLayoutConstraint.activate([
                    checkpoint.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                    checkpoint.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                    checkpoint.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                    checkpoint.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
                ])
            }
            checkpoint?.update(account: account, enabled: !working && !session.busy && session.error == nil)
            return
        }
        checkpoint?.removeFromSuperview(); checkpoint = nil; scroll.isHidden = false
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let xp = account.experience
        label("CUBRISM  /  DELVE", size: 30, color: GameArt.gold)
        label("Delve level \(DelvePresentation.number(account.rating)) · Character \(xp.level)", size: 22)
        if xp.level < xp.cap {
            label("XP \(DelvePresentation.number(xp.progress)) / \(DelvePresentation.number(xp.levelUpCosts[xp.level - 1]))", size: 16)
            let bar = UIProgressView(progressViewStyle: .default)
            bar.progressTintColor = GameArt.emerald
            bar.progress = Float(xp.progress / xp.levelUpCosts[xp.level - 1])
            stack.addArrangedSubview(bar)
        } else { label("Maximum character level · Lifetime XP \(DelvePresentation.number(xp.lifetime))", size: 16) }
        if let notice = notice { label(notice, size: 18, color: GameArt.ice) }
        else if let settlement = account.lastSettlement, account.activeRun == nil {
            label(settlement.outcome == .extracted ? "Loot banked. Ready for another run." : "Run ended. XP kept; unbanked loot lost.", size: 18)
        }
        if let run = account.activeRun {
            label(run.floor.phase == .checkpoint ? "Floor \(run.depth) complete" : "Floor \(run.depth) suspended", size: 24)
            label("HP \(DelvePresentation.number(run.resources.health)) / \(DelvePresentation.number(run.resources.maxHealth)) · Shield \(DelvePresentation.number(run.resources.shield)) / \(DelvePresentation.number(run.resources.maxShield))", size: 17)
            label("\(run.loot.count) items at risk. Extract to bank them; dying or abandoning loses the whole run’s loot.", size: 17)
            button("Resume floor \(run.depth)", id: "delve.resume") { [weak self] in self?.openFloor() }
            button("Abandon run", id: "delve.abandon") { [weak self] in self?.confirmAbandon() }
            if !run.loot.isEmpty {
                label("Run loot", size: 22)
                for item in run.loot {
                    label(DelvePresentation.name(item), size: 17, color: DelvePresentation.color(item.rarity))
                    label(DelvePresentation.stats(item, balance: account.rules.balance), size: 14)
                }
            }
        } else {
            label("Clear combat rooms and the boss to reach a checkpoint. Go deeper for better loot, or extract to keep it.", size: 18)
            button("Enter dungeon", id: "delve.enter") { [weak self] in self?.perform { try await self?.session.enter() } }
        }
        let stats = session.stats
        label("Loadout · \(account.bankedItems.count) banked items", size: 22)
        label("Attack \(DelvePresentation.number(stats.attackPower)) · HP \(DelvePresentation.number(stats.maxHealth)) · Shield \(DelvePresentation.number(stats.maxShield)) · Armor \(DelvePresentation.number(stats.flatArmour))", size: 16)
        let canEquip = account.activeRun?.floor.phase != .combat
        if !canEquip { label("Equipment can be changed at a checkpoint.", size: 16) }
        for slot in DelveEquipmentSlot.allCases {
            let item = account.ownedItems.first { $0.id == account.equipped[slot] }
            label(DelvePresentation.name(slot), size: 18)
            label(item.map(DelvePresentation.name) ?? "Empty", size: 16, color: item.map { DelvePresentation.color($0.rarity) } ?? GameArt.ivory)
            if let item = item { label(DelvePresentation.stats(item, balance: account.rules.balance), size: 14) }
            if canEquip { button("Change \(DelvePresentation.name(slot))", id: "delve.equip.\(slot.rawValue)") { [weak self] in self?.chooseGear(slot) } }
        }
        if resetScroll {
            view.layoutIfNeeded()
            scroll.setContentOffset(CGPoint(x: 0, y: -scroll.adjustedContentInset.top), animated: false)
        }
    }

    private func label(_ text: String, size: CGFloat, color: UIColor = GameArt.ivory) {
        let label = UILabel(); label.text = text; label.numberOfLines = 0
        label.textColor = color; label.font = .systemFont(ofSize: size, weight: size >= 22 ? .bold : .regular)
        stack.addArrangedSubview(label)
    }

    private func button(_ title: String, id: String, action: @escaping () -> Void) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal); button.accessibilityIdentifier = id
        button.setTitleColor(GameArt.ink, for: .normal); button.backgroundColor = GameArt.gold
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        button.isEnabled = !working && !session.busy && session.error == nil
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        stack.addArrangedSubview(button)
    }

    private func perform(_ action: @escaping () async throws -> Void) {
        guard !working && !session.busy && session.error == nil else { return }
        working = true; render()
        Task {
            defer { working = false; render() }
            do { try await action() }
            catch { if session.error == nil { notice = "Could not complete this action: \(error.localizedDescription)" } }
        }
    }

    private func committed(_ action: DelveGameSession.Action) {
        switch action {
        case .enter, .continueFloor: notice = nil; openFloor()
        case .equip: render()
        case .clear: notice = "Checkpoint reached. Your loot is still at risk."; closeFloor()
        case .extract: notice = "All run loot banked."; closeFloor()
        case .death: notice = "You died. XP kept; all unbanked loot lost."; closeFloor()
        case .abandon: notice = "Run abandoned. XP kept; all unbanked loot lost."; closeFloor()
        }
    }

    private func openFloor() {
        guard viewIfLoaded?.window != nil else { render(); return }
        guard floor == nil, presentedViewController == nil, session.error == nil else { return }
        do {
            Player.delveSession = session
            let controller = try session.makeController()
            controller.modalPresentationStyle = .fullScreen
            floor = controller
            present(controller, animated: false) { [weak self] in self?.showPause() }
        } catch { notice = "Could not resume this floor: \(error.localizedDescription)"; render() }
    }

    private func closeFloor() {
        guard let controller = floor else { render(resetScroll: true); return }
        controller.skView.presentScene(nil)
        if Player.currentViewController === controller { Player.currentViewController = nil; Player.currentScene = nil }
        session.controller = nil; floor = nil
        dismiss(animated: false) { [weak self] in self?.render(resetScroll: true) }
    }

    func showPause() {
        guard let controller = floor, controller.presentedViewController == nil,
              session.error == nil, !session.busy else { return }
        session.suspend()
        let alert = UIAlertController(title: "Floor \(session.progression.activeRun?.depth ?? 1) paused",
            message: "Resume with your remaining health, or suspend this run and return later.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Resume", style: .default) { [weak self] _ in
            guard let self = self, self.session.error == nil, !self.session.busy else { return }
            self.session.resume()
        })
        alert.addAction(UIAlertAction(title: "Suspend run", style: .default) { [weak self] _ in
            self?.perform {
                try await self?.session.retrySave()
                self?.closeFloor()
            }
        })
        alert.addAction(UIAlertAction(title: "Abandon run", style: .destructive) { [weak self] _ in self?.confirmAbandon() })
        controller.present(alert, animated: false)
    }

    private func confirmAbandon() {
        let presenter = floor ?? self
        let alert = UIAlertController(title: "Abandon this run?", message: "All unbanked loot will be lost. XP is kept and your Delve level decreases.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Keep run", style: .cancel) { [weak self] _ in self?.showPause() })
        alert.addAction(UIAlertAction(title: "Abandon", style: .destructive) { [weak self] _ in self?.perform { try await self?.session.abandon() } })
        presenter.present(alert, animated: false)
    }

    private func showSaveError() {
        guard isViewLoaded else { return }
        let presenter: UIViewController = floor ?? self
        if presenter.presentedViewController != nil {
            presenter.dismiss(animated: false) { [weak self] in self?.showSaveError() }
            return
        }
        guard presenter.viewIfLoaded?.window != nil else { render(); return }
        let alert = UIAlertController(title: "Could not save", message: "Your run is paused. Retry saving to continue with the same floor and rewards.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retry save", style: .default) { [weak self] _ in
            guard let self = self else { return }
            Task {
                do { try await self.session.retrySave(); self.render(); self.showPause() }
                catch { /* The session presents the retry error. */ }
            }
        })
        presenter.present(alert, animated: false)
        render()
    }

    private func chooseGear(_ slot: DelveEquipmentSlot) {
        let picker = DelveGearViewController(session: session, slot: slot)
        picker.onEquipped = { [weak self] in self?.render() }
        present(UINavigationController(rootViewController: picker), animated: true)
    }

    private func showLoadout() {
        guard !working, !session.busy, session.error == nil, presentedViewController == nil else { return }
        let alert = UIAlertController(title: "Loadout", message: "Choose equipment to change. Unbanked gear is still lost on death.", preferredStyle: .alert)
        for slot in DelveEquipmentSlot.allCases {
            alert.addAction(UIAlertAction(title: DelvePresentation.name(slot), style: .default) { [weak self, weak alert] _ in
                alert?.dismiss(animated: false) { self?.chooseGear(slot) }
            })
        }
        alert.addAction(UIAlertAction(title: "Back to rewards", style: .cancel))
        present(alert, animated: true)
    }

    private func inspect(_ item: DelveLoot) {
        guard !working, !session.busy, session.error == nil, presentedViewController == nil else { return }
        let source = item.floorDepth.map { "Floor \($0) · " } ?? ""
        let alert = UIAlertController(title: DelvePresentation.name(item),
            message: "\(source)Unbanked · Lost on death\n\n\(DelvePresentation.stats(item, balance: session.progression.rules.balance))", preferredStyle: .alert)
        for slot in DelveEquipmentSlot.allCases where slot.accepts(item.kind)
            && !session.progression.equipped.contains(where: { $0.key != slot && $0.value == item.id }) {
            alert.addAction(UIAlertAction(title: "Equip: \(DelvePresentation.name(slot))", style: .default) { [weak self] _ in
                self?.perform { try await self?.session.equip(item.id, in: slot) }
            })
        }
        alert.addAction(UIAlertAction(title: "Back to rewards", style: .cancel))
        present(alert, animated: true)
    }
}

@MainActor
private final class DelveGearViewController: UITableViewController {
    private let session: DelveGameSession
    private let slot: DelveEquipmentSlot
    private let items: [DelveLoot]
    var onEquipped: (() -> Void)?

    init(session: DelveGameSession, slot: DelveEquipmentSlot) {
        self.session = session; self.slot = slot
        let account = session.progression
        items = account.ownedItems.filter { item in
            slot.accepts(item.kind) && !account.equipped.contains { $0.key != slot && $0.value == item.id }
        }.sorted { $0.power > $1.power }
        super.init(style: .insetGrouped)
        title = DelvePresentation.name(slot)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = GameArt.ink
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground(); appearance.backgroundColor = GameArt.ink
        appearance.titleTextAttributes = [.foregroundColor: GameArt.ivory]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = GameArt.ivory
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
    }
    @objc private func done() { dismiss(animated: true) }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count + 1 }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.backgroundColor = GameArt.ink
        cell.detailTextLabel?.textColor = GameArt.ivory
        cell.textLabel?.numberOfLines = 0; cell.detailTextLabel?.numberOfLines = 0
        if indexPath.row == items.count { cell.textLabel?.text = "Unequip"; cell.textLabel?.textColor = GameArt.ivory; return cell }
        let item = items[indexPath.row], account = session.progression
        cell.textLabel?.text = DelvePresentation.name(item)
        cell.textLabel?.textColor = DelvePresentation.color(item.rarity)
        let risk = account.bankedItems.contains { $0.id == item.id } ? "Banked" : "Run loot · Lost on death"
        cell.detailTextLabel?.text = "\(risk)\n\(DelvePresentation.stats(item, balance: account.rules.balance))"
        cell.accessoryType = account.equipped[slot] == item.id ? .checkmark : .none
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !session.busy && session.error == nil else { return }
        tableView.isUserInteractionEnabled = false
        Task {
            do {
                try await session.equip(indexPath.row < items.count ? items[indexPath.row].id : nil, in: slot)
                onEquipped?(); dismiss(animated: true)
            } catch { tableView.isUserInteractionEnabled = true }
        }
    }
}
