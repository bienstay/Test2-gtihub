//
//  RestaurantTableViewController.swift
//  FoodPin
//
//  Created by maciulek on 28/03/2021.
//

import UIKit
import Kingfisher
//import MapKit


class RestaurantTableViewController: UITableViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet var emptyRestaurantView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        initView(tableView: tableView)

        //tableView.cellLayoutMarginsFollowReadableWidth = true

        //navigationController?.navigationBar.prefersLargeTitles = true

        // setup empty table
        tableView.backgroundView = emptyRestaurantView
        tableView.backgroundView?.isHidden = hotel.restaurants.count == 0 ? false : true

        NotificationCenter.default.addObserver(self, selector: #selector(onRestaurantsUpdated(_:)), name: .restaurantsUpdated, object: nil)

        let nib = UINib(nibName: "RestaurantSectionHeaderView", bundle: nil)
        tableView.register(nib, forHeaderFooterViewReuseIdentifier: "HeaderTableView")
    }

    // this is for test only and for future development
    @objc func didTap(_ sender: AnyObject) {
        let group = sender.view!.tag / 100
        let item = sender.view!.tag % 100
        let storyboard = UIStoryboard(name: "Restaurants", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DestinationDining") as! DestinationDiningViewController
        vc.ddItem = hotel.destinationDining.groups[group].items[item]
        self.navigationController?.pushViewController(vc, animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.backButtonTitle = ""
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.hidesBarsOnSwipe = true
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.tintColor = .black
    }

    @objc func onRestaurantsUpdated(_ notification: Notification) {
        DispatchQueue.main.async { self.tableView.reloadData() }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRestaurantDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let destinationController = segue.destination as! RestaurantDetailViewController
                destinationController.restaurant = hotel.restaurants[indexPath.row]
            }
        }
    }

    // unwind from NewRestaurant
    @IBAction func unwindToHome(segue: UIStoryboardSegue) {
        if (segue.identifier == "save") {
            if let newRC = segue.source as? NewRestaurantController {
                print("adding a new restaurant...")
                hotel.restaurants.append(newRC.restaurant)  // TODO add to Firebase
            }
            //updateRestaurantListView()
        }
        dismiss(animated: true, completion: nil)
    }


    // section 0 is for restaurants, section 1 is for destination dining
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2    // restaurants and destination dining
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section : Int) -> Int {
        switch section {
        case 0: return hotel.restaurants.count
        //default: return 1   // 1 row with destination dining collection view in section 1
        default: return hotel.destinationDining.groups.count
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 { return UITableView.automaticDimension }
        else { return 340 } // TODO figure out how to do auto resizing
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let restaurant = hotel.restaurants[indexPath.row]
            var cellName = "bigcell"
            if UIDevice.current.userInterfaceIdiom == .pad { cellName = "smallcell"}
            let cell = tableView.dequeueReusableCell(withIdentifier: cellName, for: indexPath) as! RestaurantTableViewCell
            cell.nameLabel?.text = restaurant.name
            //cell.thumbnailImageView?.image = UIImage(data: restaurant.image)
            cell.thumbnailImageView?.kf.setImage(with: URL(string: restaurant.image))
            cell.locationLabel.text = restaurant.location
            cell.typeLabel.text = restaurant.cuisines[0]
            //cell.accessoryType = restaurant.isFavorite ? .checkmark : .none
            return cell
        default:
            // collection view inside the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "DestinationDiningCell", for: indexPath) as! RestaurantDestinationDiningCell
            cell.groupTitleLabel.text = hotel.destinationDining.groups[indexPath.row].title
            cell.groupSubLabel.text = hotel.destinationDining.groups[indexPath.row].description
            cell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //return colorsModel[collectionView.tag].count
        return hotel.destinationDining.groups[collectionView.tag].items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RestaurantDestinationDiningCell", for: indexPath) as! RestaurantDestinationDiningCollectionViewCell
        cell.backgroundColor = .BBbackgroundColor
        let dd = hotel.destinationDining.groups[collectionView.tag].items[indexPath.row]
        cell.titleLabel.text = dd.title
        //cell.timeLocationLabel.text = dd.timeLocation
        //cell.descriptionLabel.text = dd.description
        cell.picture.image = UIImage(named: dd.image)

        // for test only - add tap for the collection view cells and pass the tag number
        let tapAction = UITapGestureRecognizer(target: self, action: #selector(didTap))
        cell.tag = indexPath.row + collectionView.tag * 100
        cell.isUserInteractionEnabled = true
        cell.addGestureRecognizer(tapAction)

        return cell
    }

}

// MARK: - Section header
extension RestaurantTableViewController {

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 { return UIView() }
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HeaderTableView") as! RestaurantSectionHeaderView
        view.sectionHeaderLabel.text = hotel.destinationDining.headline.0
        view.descriptionLabel.text = hotel.destinationDining.headline.1
        view.subLabel.text = hotel.destinationDining.headline.2
        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 { return 1 }
        return 240
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
}

class RestaurantSectionHeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var sectionHeaderLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var subLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        let bgView = UIView(frame: self.bounds)
        bgView.backgroundColor = UIColor(white: 0.5, alpha: 0.0)
        self.backgroundView = bgView
        sectionHeaderLabel.textColor = .orange
        descriptionLabel.textColor = .gray
    }
}
