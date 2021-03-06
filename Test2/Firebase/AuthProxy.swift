//
//  AuthProxy.swift
//  Test2
//
//  Created by maciulek on 14/04/2022.
//

import Foundation

enum Role: String, CaseIterable {
    case superadmin     // can do everything and modify hotels
    case admin          // can do everything
    case editor         // can only edit the content
    case hotline        // can manage all orders
    case housekeeping   // only cleaning orders
    case maintenance    // only maintenance orders
    case driver         // only buggy orders
    case roomservice    // only room service
}

protocol AuthenticationData {
    var uid: String { get }
    var name: String { get }
    var email: String { get }
    var role: Role? { get set }
}

protocol AuthProxy {
    var defaultPassword: String { get }
    func login(username: String, password: String, completionHandler: @ escaping (AuthenticationData?, Error?) -> Void)
    //func addUser(hotelId: String, username: String, password: String, role:Role?, completionHandler: @escaping (AuthenticationData?, Error?) -> Void)
    func logout() -> Error?

    func addUserWithRole(hotelId: String, username: String, password: String, role:Role?, completionHandler: @ escaping (AuthenticationData?, Error?) -> Void)
    func setUserRole(uid: String, role: Role, completionHandler: @escaping (Error?) -> Void)
    func deleteUser(uid: String, completionHandler: @ escaping (Error?) -> Void)
    func updateUser(uid: String, newPassword: String, completionHandler: @ escaping (Error?) -> Void)
    func getUser(uid: String, completionHandler: @ escaping (AuthenticationData?, Error?) -> Void)
    func getUsers(hotelName: String, completionHandler: @ escaping ([AuthenticationData]) -> Void)
}
