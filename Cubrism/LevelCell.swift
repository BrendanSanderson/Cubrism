import UIKit

class LevelCell: UICollectionViewCell {
    private let numberLabel = UILabel()
    private let statusLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 1.5
        for label in [numberLabel, statusLabel] {
            label.textAlignment = .center
            contentView.addSubview(label)
        }
        numberLabel.font = .boldSystemFont(ofSize: 28)
        statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
        statusLabel.adjustsFontSizeToFitWidth = true
        isAccessibilityElement = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(level: Int, unlocked: Bool, completed: Bool) {
        numberLabel.text = String(level)
        statusLabel.text = unlocked ? (completed ? "✓ Cleared" : "Play") : "🔒 Locked"
        numberLabel.textColor = unlocked ? GameArt.ivory : .lightGray
        statusLabel.textColor = unlocked ? GameArt.gold : .lightGray
        contentView.backgroundColor = unlocked ? UIColor(white: 0.20, alpha: 1) : UIColor(white: 0.12, alpha: 1)
        contentView.layer.borderColor = (unlocked ? GameArt.gold : UIColor.darkGray).cgColor
        accessibilityLabel = "Level \(level), \(statusLabel.text!)"
        accessibilityTraits = unlocked ? .button : [.button, .notEnabled]
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        numberLabel.frame = CGRect(x: 4, y: 4, width: bounds.width - 8, height: max(24, bounds.height - 32))
        statusLabel.frame = CGRect(x: 4, y: bounds.height - 28, width: bounds.width - 8, height: 24)
    }
    override var isHighlighted: Bool {
        didSet { contentView.alpha = isHighlighted ? 0.65 : 1 }
    }
}
