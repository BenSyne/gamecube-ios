// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import UIKit

class SoftwareListCell: UICollectionViewCell {

  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()

    contentView.backgroundColor = .secondarySystemGroupedBackground
    contentView.layer.cornerRadius = 18
    contentView.layer.cornerCurve = .continuous
    contentView.layer.masksToBounds = true

    imageView.contentMode = .scaleAspectFill
    imageView.backgroundColor = .tertiarySystemFill
    imageView.accessibilityIgnoresInvertColors = true

    nameLabel.font = .preferredFont(forTextStyle: .subheadline)
    nameLabel.adjustsFontForContentSizeCategory = true
    nameLabel.textColor = .label
    nameLabel.textAlignment = .left

    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.10
    layer.shadowRadius = 12
    layer.shadowOffset = CGSize(width: 0, height: 5)
    layer.masksToBounds = false
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    imageView.image = nil
    nameLabel.text = nil
    transform = .identity
    alpha = 1
  }

  override var isHighlighted: Bool {
    didSet {
      UIView.animate(
        withDuration: 0.16,
        delay: 0,
        options: [.allowUserInteraction, .beginFromCurrentState]
      ) {
        self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
        self.alpha = self.isHighlighted ? 0.82 : 1
      }
    }
  }
}
