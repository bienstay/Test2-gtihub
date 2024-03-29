//
//  RoomViewController.swift
//  Bibzzy
//
//  Created by maciulek on 26/04/2021.
//

import UIKit
import DeveloperToolsSupport

class RoomViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var orderSummaryConstraint: NSLayoutConstraint!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var orderShortSummaryView: OrderShortSummaryView!

    override func viewDidLoad() {
        super.viewDidLoad()
        initView(tableView: tableView)

        tableView.dataSource = self
        tableView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupListNavigationBar(largeTitle: false, title: phoneUser.displayName + "  " + (phoneUser.role?.rawValue ?? ""))
        //tabBarController?.tabBar.isHidden = false
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RoomHeaderCell2", for: indexPath) as! RoomHeaderCell2
        cell.tapClosure = { [weak self] category in
            self?.maintenancePressed(category: category)
        }
        cell.display(indexPath.row)
        return cell
    }

    func maintenancePressed(category: OrderCategory) {
        switch (category) {
        case .Buggy:
            let vc = pushViewController(storyBoard: "OrderSummary", id: "BuggyOrder") as! BuggyOrderViewController
            //vc.category = category
        case .Cleaning, .Maintenance, .Luggage:
            let vc = pushViewController(storyBoard: "OrderSummary", id: "MaintenanceOrder") as! ServiceOrderViewController
            vc.order.category = category
        case .RoomItems:
            _ = pushViewController(storyBoard: "Room", id: "RoomItemsController")
        case .RoomService:
            let vc = pushViewController(storyBoard: "Menu", id: "MenuViewController") as! MenuViewController
            vc.restaurant = hotel.roomService
            vc.order = Order6(category: .RoomService)
        default:
            break;
        }
    }

}


class RoomHeaderCell2: UITableViewCell {
    @IBOutlet private weak var headerTitleLabel1: UILabel!
    @IBOutlet private weak var headerLabel1: UILabel!
    @IBOutlet private weak var headerImage1: UIImageView!
    @IBOutlet private weak var headerTitleLabel2: UILabel!
    @IBOutlet private weak var headerLabel2: UILabel!
    @IBOutlet private weak var headerImage2: UIImageView!
    var tapClosure: ((_ category: OrderCategory) -> ())? = nil
    var row: Int = 0

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        selectionStyle = .none

        let tap1 = UITapGestureRecognizer(target: self, action: #selector(didTap1))
        headerImage1.addGestureRecognizer(tap1)
        headerImage1.isUserInteractionEnabled = true

        let tap2 = UITapGestureRecognizer(target: self, action: #selector(didTap2))
        headerImage2.addGestureRecognizer(tap2)
        headerImage2.isUserInteractionEnabled = true
    }

    @objc func didTap1() {
        switch row {
        case 0: tapClosure?(.RoomItems)
        case 1: tapClosure?(.Maintenance)
        case 2: tapClosure?(.Luggage)
        default: break
        }
    }

    @objc func didTap2() {
        switch row {
        case 0: tapClosure?(.RoomService)
        case 1: tapClosure?(.Cleaning)
        case 2: tapClosure?(.Buggy)
        default: break
        }
    }

    func display(_ row:Int) {
        self.row = row
        headerLabel1.isHidden = true
        headerLabel2.isHidden = true
        headerLabel1.text = ""
        headerLabel2.text = ""
        switch (row) {
        case 0:
            headerTitleLabel1.text = .roomItems
            headerImage1.image = UIImage(named: "Room Items")
            headerTitleLabel2.text = .roomService
            headerImage2.image = UIImage(named: OrderCategory.RoomService.rawValue)
        case 1:
            headerTitleLabel1.text = .maintenance
            headerImage1.image = UIImage(named: "Maintenance")
            headerTitleLabel2.text = .cleaning
            headerImage2.image = UIImage(named: "Cleaning")
        case 2:
            headerTitleLabel1.text = .luggageService
            headerImage1.image = UIImage(named: "Luggage")
            headerTitleLabel2.text = .buggy
            headerImage2.image = UIImage(named: "Buggy")
        default: break
        }
    }
}
