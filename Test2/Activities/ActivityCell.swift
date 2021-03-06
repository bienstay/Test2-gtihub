//
//  ActivityCell.swift
//  Test2
//
//  Created by maciulek on 05/10/2021.
//

import UIKit

class ActivityCell: UITableViewCell {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var activityImageView: UIImageView!
    @IBOutlet var activityTextLabel: UILabel!
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
        titleLabel.text = activity._title
        subtitleLabel.text = activity._subtitle
        timeLabel.text = (activity.start.formatTimeShort()) + " - " + (activity.end.formatTimeShort())
        activityTextLabel.text = activity._text

        if expanded {
            //imageWidthConstraint.constant = mainStackView.frame.width
            mainStackView.axis = .vertical
            mainStackView.alignment = .fill
            activityTextLabel.isHidden = activityTextLabel.text?.isEmpty ?? true
        } else {
            //imageWidthConstraint.constant = 100
            mainStackView.axis = .horizontal
            mainStackView.alignment = .center
            activityTextLabel.isHidden = true
        }
/*
        let todo = expanded ?
        { [self] in
            imageWidthConstraint.constant = mainStackView.frame.width
            mainStackView.axis = .vertical
            mainStackView.alignment = .fill
            descriptionLabel.isHidden = descriptionLabel.text?.isEmpty ?? true
        } :
        { [self] in
            imageWidthConstraint.constant = 100
            mainStackView.axis = .horizontal
            mainStackView.alignment = .center
            descriptionLabel.isHidden = true
        }
*/

        mainStackView.clipsToBounds = true
        if let url = URL(string: activity.imageFileURL) {
            activityImageView.kf.setImage(with: url) { result in
                switch result {
                case .success(_):
                    self.activityImageView.isHidden = false
                case .failure(let kingfisherError):
                    self.activityImageView.isHidden = true
                    Log.log(level: .ERROR, kingfisherError.localizedDescription)
                }
                UIView.animate(withDuration: 0.5, delay: 0.0, options: [], animations: {self.layoutIfNeeded()}, completion: {_ in self.setNeedsLayout()})
            }
        }
        else {
            activityImageView.isHidden = true
            UIView.animate(withDuration: 0.5, delay: 0.0, options: [], animations: {self.layoutIfNeeded()}, completion: {_ in self.setNeedsLayout()})
        }
        layoutSubviews()
    }
}
