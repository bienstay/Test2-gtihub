//
//  ItemTableViewCell.swift
//  Test1
//
//  Created by maciulek on 27/04/2021.
//

import UIKit

class RoomItemCell: UITableViewCell {

    @IBOutlet private weak var itemLabel: UILabel!
    @IBOutlet private weak var quantityLabel: UILabel!
    @IBOutlet private weak var minusButton: UIButton!
    @IBOutlet private weak var plusButton: UIButton!
    @IBOutlet private weak var itemImage: UIImageView!

    var buttonTappedClosure : ((Bool) -> Void)? = nil
    @IBAction func minusPressed(_ sender: UIButton) {
        buttonTappedClosure?(false)
    }
    @IBAction func plusPressed(_ sender: UIButton) {
        buttonTappedClosure?(true)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        selectionStyle = .none
        quantityLabel.textColor = .orange
        minusButton.tintColor = .orange
        plusButton.tintColor = .orange
    }

    func display(roomItem: RoomItem, order: Order6, expanded: Bool) {
        //if let lang = Locale.current.languageCode, let itemList = String.roomItemsList[lang] {
        if let itemList = String.roomItemsList[phoneUser.lang] {
            itemLabel.text = itemList[roomItem.name]
        } else {
            itemLabel.text = roomItem.name
        }
        quantityLabel.text = "0"
        if let item = order.roomItems.first(where: { $0.item.name == roomItem.name } ) {
            quantityLabel.text = String(item.quantity)
        }
        if let hexColor = Int(roomItem.color, radix: 16) {
            itemImage.backgroundColor = UIColor(hexColor)
        } else {
            itemImage.backgroundColor = .gray
        }

        if let image = UIImage(named: roomItem.picture) { itemImage.image = image }
        else { itemImage.image = .none }

        itemImage.image = itemImage.image?.withRenderingMode(.alwaysTemplate)
        itemImage.tintColor = .white
        itemImage.layer.cornerRadius = 10

        minusButton.isHidden = !expanded
        plusButton.isHidden = !expanded
        quantityLabel.isHidden = !expanded
    }
}
