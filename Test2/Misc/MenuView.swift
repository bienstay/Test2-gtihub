//
//  MenuView.swift
//  Test2
//
//  Created by maciulek on 05/05/2022.
//

import UIKit

class MenuView: UIView {
    typealias MenuCallback = () -> Void
    var leftConstraint: NSLayoutConstraint!
    var tableView: UITableView!
    var header: UILabel!
    var items: [(String, MenuCallback)] = []
    var isOn: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        createSubViews(headerText: "")
    }

    required init? (coder: NSCoder) {
        super.init(coder: coder)
        createSubViews(headerText: "")
    }

    init(parentView: UIView, headerText: String) {
        super.init(frame: CGRect.zero)
        parentView.addSubview(self)

        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 300).isActive = true
        topAnchor.constraint(equalTo: superview!.topAnchor, constant: 90).isActive = true
        bottomAnchor.constraint(equalTo: superview!.bottomAnchor, constant: -200).isActive = true
        leftConstraint = leftAnchor.constraint(equalTo: superview!.leftAnchor, constant: 0)
        leftConstraint.constant = -300
        leftConstraint.isActive = true
        backgroundColor = .BBbackgroundColor

        layer.masksToBounds = false
        layer.cornerRadius = 40
        layer.shadowOffset = CGSize(width: 10, height: 10)
        layer.shadowOpacity = 0.5
        layer.shadowColor = UIColor.black.cgColor
        createSubViews(headerText: headerText)
    }

    func present(show: Bool) {
        leftConstraint.constant = show ? 0 : -300
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.curveEaseIn]) {
            self.superview!.layoutIfNeeded()
        }
        isOn = show
    }
    
    func toggle() {
        present(show: !isOn)
    }

    func addItem(label: String, callback: @escaping MenuCallback) {
        items.append((label, callback))
        tableView.reloadData()
    }

    // Creating subview
    private func createSubViews(headerText: String) {
        tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "menuCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .BBbackgroundColor

        header = UILabel()
        header.text = headerText
        header.font = .preferredFont(forTextStyle: .largeTitle)
        header.textAlignment = .center

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.addArrangedSubview(header)
        stackView.addArrangedSubview(tableView)

        addSubview(stackView)
        
        NSLayoutConstraint.activate([
        stackView.topAnchor.constraint(equalTo:topAnchor, constant: 30),
        stackView.leftAnchor.constraint(equalTo:leftAnchor, constant: 10),
        stackView.rightAnchor.constraint(equalTo:rightAnchor, constant: -10),
        stackView.bottomAnchor.constraint(equalTo:bottomAnchor, constant: -10)
        ])
        
        layoutSubviews()
    }
}

extension MenuView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuCell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row].0
        cell.backgroundColor = .BBbackgroundColor
        return cell
    }
}

extension MenuView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        items[indexPath.row].1()
        present(show: false)
    }
}
