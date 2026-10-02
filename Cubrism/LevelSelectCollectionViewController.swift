import UIKit

class LevelSelectCollectionViewController: UICollectionViewController {
    let pageControl = UIPageControl()
    weak var homeView: HomeViewController?
    private let titleLabel = UILabel()
    private let previousButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let backButton = UIButton(type: .system)
    private var lastLayoutSize = CGSize.zero
    private let numberOfWorlds = 5

    override func loadView() { view = UIView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = GameArt.ink
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: LevelPageLayout())
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(LevelCell.self, forCellWithReuseIdentifier: "Cell")
        view.addSubview(collectionView)
        titleLabel.textAlignment = .center
        titleLabel.textColor = GameArt.ivory
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.adjustsFontSizeToFitWidth = true
        view.addSubview(titleLabel)
        for (button, title, action) in [(backButton, "Back", #selector(back(_:))),
                                       (previousButton, "‹ Previous", #selector(previousWorld)),
                                       (nextButton, "Next ›", #selector(nextWorld))] {
            button.setTitle(title, for: .normal)
            button.setTitleColor(GameArt.ivory, for: .normal)
            button.setTitleColor(.gray, for: .disabled)
            button.addTarget(self, action: action, for: .touchUpInside)
            view.addSubview(button)
        }
        pageControl.numberOfPages = numberOfWorlds
        pageControl.currentPageIndicatorTintColor = GameArt.gold
        pageControl.pageIndicatorTintColor = .gray
        pageControl.addTarget(self, action: #selector(pageControlChanged(_:)), for: .valueChanged)
        view.addSubview(pageControl)
        updateWorldTitle()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bounds = view.safeAreaLayoutGuide.layoutFrame
        backButton.frame = CGRect(x: bounds.minX + 12, y: bounds.minY, width: 64, height: 52)
        titleLabel.frame = CGRect(x: bounds.minX + 80, y: bounds.minY, width: max(0, bounds.width - 160), height: 52)
        collectionView.frame = CGRect(x: bounds.minX, y: bounds.minY + 56, width: bounds.width, height: max(1, bounds.height - 108))
        previousButton.frame = CGRect(x: bounds.minX + 12, y: bounds.maxY - 48, width: 100, height: 44)
        nextButton.frame = CGRect(x: bounds.maxX - 112, y: bounds.maxY - 48, width: 100, height: 44)
        pageControl.frame = CGRect(x: bounds.midX - 70, y: bounds.maxY - 48, width: 140, height: 44)
        if collectionView.bounds.size != lastLayoutSize {
            lastLayoutSize = collectionView.bounds.size
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.layoutIfNeeded()
            collectionView.contentOffset = CGPoint(x: lastLayoutSize.width * CGFloat(pageControl.currentPage), y: 0)
        }
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int { numberOfWorlds }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 10 }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! LevelCell
        let completed = UserDefaults.standard.integer(forKey: "LevelCompleted")
        cell.configure(level: indexPath.item + 1,
                       unlocked: isLevelUnlocked(at: indexPath, completedLevel: completed),
                       completed: levelNumber(for: indexPath) < completed)
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard isLevelUnlocked(at: indexPath, completedLevel: UserDefaults.standard.integer(forKey: "LevelCompleted")),
              let floor = homeView?.floorView,
              let path = Bundle.main.path(forResource: "levels", ofType: "plist"),
              let levels = NSArray(contentsOfFile: path),
              let level = levels[indexPath.item] as? [String: Any],
              let min = level["min"] as? Int, let max = level["max"] as? Int,
              let number = level["level"] as? Int else { return }
        Player.entity.stopControls()
        floor.min = UInt32(min)
        floor.max = UInt32(max)
        floor.level = number
        floor.world = indexPath.section + 1
        floor.needsNewRun = true
        dismiss(animated: false) {
            NotificationCenter.default.post(name: Notification.Name("GoToLevelFloorViewController"), object: nil)
        }
    }

    func levelNumber(for indexPath: IndexPath) -> Int { indexPath.section * 10 + indexPath.item }
    func isLevelUnlocked(at indexPath: IndexPath, completedLevel: Int) -> Bool { levelNumber(for: indexPath) <= completedLevel }
    private func clearControls() {
        #if targetEnvironment(macCatalyst)
        (homeView?.skView?.scene as? GameScene)?.resetKeyboardControls()
        #endif
        Player.entity.stopControls()
    }
    #if targetEnvironment(macCatalyst)
    override var canBecomeFirstResponder: Bool { true }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
        clearControls()
    }
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) { clearControls() }
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) { clearControls() }
    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) { clearControls() }
    #endif
    @objc func back(_ sender: AnyObject) {
        clearControls()
        dismiss(animated: false)
    }
    @objc private func previousWorld() { showWorld(pageControl.currentPage - 1) }
    @objc private func nextWorld() { showWorld(pageControl.currentPage + 1) }
    @objc func pageControlChanged(_ sender: UIPageControl) { showWorld(sender.currentPage) }
    private func showWorld(_ page: Int) {
        pageControl.currentPage = max(0, min(numberOfWorlds - 1, page))
        updateWorldTitle()
        collectionView.setContentOffset(CGPoint(x: collectionView.bounds.width * CGFloat(pageControl.currentPage), y: 0), animated: false)
    }
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard collectionView.bounds.width > 0 else { return }
        pageControl.currentPage = Int((scrollView.contentOffset.x / collectionView.bounds.width).rounded())
        updateWorldTitle()
    }
    private func updateWorldTitle() {
        titleLabel.text = "World \(pageControl.currentPage + 1) · Select a level"
        previousButton.isEnabled = pageControl.currentPage > 0
        nextButton.isEnabled = pageControl.currentPage < numberOfWorlds - 1
    }
}

/// Explicit page geometry avoids flow-layout rounding adding or dropping columns.
private class LevelPageLayout: UICollectionViewLayout {
    override var collectionViewContentSize: CGSize {
        guard let view = collectionView else { return .zero }
        return CGSize(width: view.bounds.width * CGFloat(view.numberOfSections), height: view.bounds.height)
    }
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool { newBounds.size != collectionView?.bounds.size }
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let view = collectionView else { return nil }
        let gap: CGFloat = 12
        let width = min(160, max(1, (view.bounds.width - 48 - gap * 4) / 5))
        let height = min(140, max(1, (view.bounds.height - 24 - gap) / 2))
        let x = (view.bounds.width - width * 5 - gap * 4) / 2
        let y = (view.bounds.height - height * 2 - gap) / 2
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        attributes.frame = CGRect(x: CGFloat(indexPath.section) * view.bounds.width + x + CGFloat(indexPath.item % 5) * (width + gap),
                                  y: y + CGFloat(indexPath.item / 5) * (height + gap), width: width, height: height)
        return attributes
    }
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let view = collectionView else { return [] }
        return (0..<view.numberOfSections).flatMap { section in
            (0..<view.numberOfItems(inSection: section)).compactMap { item in
                layoutAttributesForItem(at: IndexPath(item: item, section: section))
            }
        }.filter { $0.frame.intersects(rect) }
    }
}
