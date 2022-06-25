//
//  InfoViewController.swift
//  Test2
//
//  Created by maciulek on 21/05/2022.
//

import UIKit
import Kingfisher


class InfoViewController: UIViewController, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newInfoBarButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        initView(tableView: tableView)
        if #available(iOS 13.0, *) {
            tableView.backgroundColor = .systemGroupedBackground
        } else {
            // Fallback on earlier versions
        }
        tableView.dataSource = self
        tableView.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(onInformationUpdated(_:)), name: .informationUpdated, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupListNavigationBar()
        //tabBarController?.tabBar.isHidden = true
        title = .info
        newInfoBarButton.isEnabled = phoneUser.isAllowed(to: .editContent)
        newInfoBarButton.title = phoneUser.isAllowed(to: .editContent) ? "New" : ""
    }

    override func viewWillDisappear(_ animated: Bool) {
        title = ""
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hotel.infoItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCell", for: indexPath) as! InfoCell
        cell.draw(info: hotel.infoItems[indexPath.row])
        return cell
    }

    @objc func onInformationUpdated(_ notification: Notification) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    @IBAction func newInfoPressed(_ sender: Any) {
        _ = pushViewController(storyBoard: "Info", id: "NewInfo")
    }
}

extension InfoViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = pushOrPresent(storyBoard: "Info", id: "InfoDetail") as! InfoDetailViewController
        vc.infoItem = hotel.infoItems[indexPath.row]
    }
}

extension InfoViewController {
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if !phoneUser.isAllowed(to: .editContent) { return nil }
        let action1 = UIContextualAction(style: .normal, title: "Edit") { action, view, completionHandler in
            let vc = self.createViewController(storyBoard: "Info", id: "NewInfo") as! NewInfoViewController
            vc.infoToEdit = hotel.infoItems[indexPath.row]
            self.navigationController?.pushViewController(vc, animated: true)
            completionHandler(true)
        }
        action1.backgroundColor = .orange
        return UISwipeActionsConfiguration(actions: [action1])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if !phoneUser.isAllowed(to: .editContent) { return nil }
        let action1 = UIContextualAction(style: .destructive, title: "Delete") { action, view, completionHandler in
            self.deleteInfo(info: hotel.infoItems[indexPath.row])
            completionHandler(true)
        }
        action1.backgroundColor = .red
        let configuration = UISwipeActionsConfiguration(actions: [action1])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    func deleteInfo(info: InfoItem) {
        guard let id = info.id else { return }
        let errStr = dbProxy.removeRecord(key: id, record: info) { record in
            if record == nil {
                self.showInfoDialogBox(title: "Error", message: "Info delete failed")
            } else {
                self.showInfoDialogBox(title: "Info", message: "Info deleted")
            }
        }
        if errStr != nil { Log.log(errStr!) }
    }
}
















/*
class InfoCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var infoImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = UITableViewCell.SelectionStyle.none
        backgroundColor = .clear
        infoImageView.layer.cornerRadius = 15
        infoImageView.layer.masksToBounds = true
    }

    func draw(info: InfoItem) {
        titleLabel.text = info._title
        subtitleLabel.text = info._subtitle
        infoImageView.image = nil
        //infoImageView.image = UIImage(named: info.images[0].url) // TODO remove
        if let url = URL(string: info.images[0].url) {
            infoImageView.isHidden = false
            infoImageView.kf.setImage(with: url)
        }
        else { infoImageView.isHidden = true }
    }
}
*/

class InfoCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var containerView: UIView!
    @IBOutlet var imageContainerView: UIView!
    @IBOutlet var iconImageView: UIImageView!
    var orgFrame: CGRect? = nil

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = UITableViewCell.SelectionStyle.none

        layer.cornerRadius = 8
        layer.masksToBounds = true
        imageContainerView.layer.cornerRadius = 8
        imageContainerView.layer.masksToBounds = true
    }

    func draw(info: InfoItem) {
        titleLabel.text = info.title
        //imageContainerView.backgroundColor = [.systemPink, .systemBlue, .systemGreen, .systemOrange].randomElement()
        /*if #available(iOS 13.0, *) {
            iconImageView.image = UIImage(systemName: "airplane")
        } else {
            // Fallback on earlier versions
        }*/
        iconImageView.image = nil
        iconImageView.isHidden = true
        if let url = URL(string: info.images[0].url) {
            iconImageView.kf.setImage(with: url)
            iconImageView.isHidden = false
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if orgFrame == nil {
            orgFrame = layer.frame.inset(by: UIEdgeInsets(top: 1, left: 16, bottom: 1, right: 16));
        }

        //let newFrame = self.layer.frame.inset(by: UIEdgeInsets(top: 1, left: 16, bottom: 1, right: 16));
        layer.frame = orgFrame ?? .zero
        super.layoutSubviews()
    }

}
