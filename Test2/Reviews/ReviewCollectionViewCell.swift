//
//  ReviewCollectionViewCell.swift
//  Test2
//
//  Created by maciulek on 28/06/2022.
//

import UIKit

class ReviewCollectionViewCell: UICollectionViewCell {
    @IBOutlet var timestampLabel: UILabel!
    @IBOutlet var reviewTextLabel: UILabel!
    @IBOutlet var stars: [UIImageView]!
    @IBOutlet var roomNumberLabel: UILabel!

    var emptyStar = UIImage(named: "star")
    var fullStar = UIImage(named: "star.fill")

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        if #available(iOS 13.0, *) {
            emptyStar = UIImage(systemName: "star")
            fullStar = UIImage(systemName: "star.fill")
        }
    }

    func draw(timestamp: Date, rating: Int, review: String, roomNumber: Int?, translation: String?) {
        timestampLabel.text = timestamp.formatForDisplay()
        let s = NSMutableAttributedString(string: review)
        if let translation = translation {
            let t = NSMutableAttributedString(string: translation, attributes: [.foregroundColor: UIColor.systemRed])
            s.append(NSAttributedString(string: "\n"))
            s.append(t)
        }
        reviewTextLabel.attributedText = s
        for i in 0 ... stars.count - 1 {
            if i <= rating { stars[i].image = fullStar }
            else { stars[i].image = emptyStar }
        }
        if let roomNumber = roomNumber {
            roomNumberLabel.isHidden = false
            roomNumberLabel.text = String(roomNumber)
        } else {
            roomNumberLabel.isHidden = true
        }
    }

    static func createLayoutSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(50))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(50))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        //group.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 120, trailing: 0)

        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100.0))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: "review-header-kind", alignment: .top)
        section.boundarySupplementaryItems = [sectionHeader]
        
        return section
    }
}
