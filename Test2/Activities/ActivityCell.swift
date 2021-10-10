//
//  ActivityCell.swift
//  Test2
//
//  Created by maciulek on 05/10/2021.
//

import UIKit

class ActivityCell: UITableViewCell {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var activityImageView: UIImageView!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainStackView: UIStackView!

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = UITableViewCell.SelectionStyle.none
        backgroundColor = .clear
        activityImageView.layer.cornerRadius = 15
        activityImageView.layer.masksToBounds = true
    }

    func draw(activity: Activity, expanded: Bool) {
        titleLabel.text = activity.title
        locationLabel.text = activity.location
        timeLabel.text = (activity.start.formatTimeShort()) + " - " + (activity.end.formatTimeShort())
        descriptionLabel.text = activity.text

        if expanded {
            imageWidthConstraint.constant = mainStackView.frame.width
            mainStackView.axis = .vertical
            mainStackView.alignment = .fill
            descriptionLabel.isHidden = false
        } else {
            imageWidthConstraint.constant = 80
            mainStackView.axis = .horizontal
            mainStackView.alignment = .top
            descriptionLabel.isHidden = true
        }
 
        activityImageView.isHidden = true
        if let url = URL(string: activity.imageFileURL) {
            activityImageView.kf.setImage(with: url) { result in
                switch result {
                case .success(_):
                    self.activityImageView.isHidden = false
                    //self.layoutIfNeeded()
                default: break
                }
                UIView.animate(withDuration: 0.5, delay: 0.0, options: [], animations: {self.layoutIfNeeded()}, completion: nil)
            }
        }
        else {
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {self.layoutIfNeeded()}, completion: nil)
            //layoutIfNeeded()
        }
    }
}