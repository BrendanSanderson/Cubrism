import UIKit

class CompletedViewController: UIViewController {
    var expGained = 10
    var level = 0
    var drops = [Item]()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.darkColor
        let scroll = UIScrollView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 18
        stack.alignment = .fill
        scroll.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)
        content.addSubview(scroll)
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: content.topAnchor),
            content.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            content.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(lessThanOrEqualToConstant: 720),
            content.widthAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.widthAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.centerXAnchor.constraint(equalTo: scroll.frameLayoutGuide.centerXAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -48)
        ])
        let preferredWidth = content.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor)
        preferredWidth.priority = .defaultHigh
        preferredWidth.isActive = true
        func addLabel(_ text: String, size: CGFloat = 20) {
            let label = UILabel()
            label.text = text
            label.textColor = Constants.lightColor
            label.font = UIFont(name: Constants.font, size: size)
            label.numberOfLines = 0
            label.textAlignment = .center
            stack.addArrangedSubview(label)
        }
        addLabel("Floor Complete!", size: 36)
        addLabel("Experience Gained: \(expGained)")
        addLabel("Total Experience: \(Player.totalExp)")
        addLabel("Level \(Player.level) · \(Player.expToLevel(Player.level) - Player.exp) XP to next level")
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progress = Float(Player.exp) / Float(Player.expToLevel(Player.level))
        progress.progressTintColor = Constants.lightColor
        progress.accessibilityLabel = "Experience progress"
        stack.addArrangedSubview(progress)
        addLabel("Loot", size: 24)
        for item in drops {
            let row = UIStackView()
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 16
            let icon = UIImageView(image: UIImage(named: item.type))
            icon.contentMode = .scaleAspectFit
            icon.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                icon.widthAnchor.constraint(equalToConstant: 48),
                icon.heightAnchor.constraint(equalToConstant: 48)
            ])
            let label = UILabel()
            if let equipment = item as? Equipment {
                label.text = "\(equipment.type!) · Level \(equipment.level) · Tier \(equipment.tier)"
            } else {
                label.text = "\(item.type!) × \(item.quantity)"
            }
            label.font = UIFont(name: Constants.font, size: 18)
            label.textColor = Constants.lightColor
            label.numberOfLines = 0
            row.addArrangedSubview(icon)
            row.addArrangedSubview(label)
            stack.addArrangedSubview(row)
        }
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.titleLabel?.font = UIFont(name: Constants.fontB, size: 24)
        button.setTitleColor(Constants.darkColor, for: .normal)
        button.backgroundColor = Constants.lightColor
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        button.addTarget(self, action: #selector(goToHome(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "completion.continue"
        scroll.accessibilityIdentifier = "completion.rewards"
        content.addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            button.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            button.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -12),
            scroll.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -12)
        ])
    }

    @objc func goToHome(_ sender: UIButton!) {
        dismiss(animated: false) {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "GoToHomeViewController"), object: self)
        }
    }

    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
}
