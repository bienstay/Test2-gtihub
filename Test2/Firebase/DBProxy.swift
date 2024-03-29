//
//  DBProxy.swift
//  Test2
//
//  Created by maciulek on 17/03/2022.
//

import Foundation
import UIKit

enum QueryParameter {
    case OrderByRoom(roomNumber: Int)
    case OrderByCategory(type: OrderCategory)
    case OrderByAssignment(id: String)
    case ChatRoom(id: String)
    case AssignedTo(id: String)
    case ChatUser(id: String)
    case GuestInfo(id: String)
    case GuestInDb(id: String)
    case Review(id: String)
}

enum QueryOperation {
    case NEW
    case DELETE
    case UPDATE
}

protocol DBProxy {
    func addRecord<T: Encodable>(key:String?, subNode: String?, record: T, completionHandler: @ escaping (String?, T?) -> Void) -> String?
    func removeRecord<T: Encodable>(key:String, subNode: String?, record: T, completionHandler: @ escaping (T?) -> Void) -> String?
    func removeRecord(path:String, key:String, completionHandler: @ escaping (Error?) -> Void)
    @discardableResult
    func subscribe<T: Codable>(for operation: QueryOperation, subNode: String?, parameter: QueryParameter?, completionHandler: @ escaping (String, T) -> Void)  -> Any?
    @discardableResult
    func subscribeForUpdates<T: Codable>(subNode: String?, start timestamp: Int?, limit: UInt?, parameter: QueryParameter?, completionHandler: @ escaping ([String:T]) -> Void) -> Any?
    @discardableResult
    func subscribeForUpdates(path: String, completionHandler: @ escaping ([String:Any]) -> Void) -> Any?
    func unsubscribe<T: Codable>(t: T.Type, subNode: String?, parameter: QueryParameter?)
    func unsubscribe(from handle: Any?)
    func removeAllObservers()

    func observeOrderChanges()
    func getHotels(completionHandler: @ escaping ([String:String]) -> Void)
    //func getGuests(hotelID: String, index: Int, completionHandler: @ escaping (Int, [(String, GuestInfo)]) -> Void)
    func updateOrderStatus(order: Order6)
    //func updateOrderStatus(orderId: String, newStatus: OrderStatus, confirmedBy: String?, deliveredBy: String?, canceledBy: String?)
    func updateLike(group: String, userID: String, itemKey: String, add: Bool)
    func updateReview(group: String, id: String, review: Review)

    func translate(textToTranslate: String, targetLanguage: String, completionHandler: @ escaping (String?) -> Void)
    func translateChat(chatRoom: String, chatID: String, textToTranslate: String, targetLanguage: String, completionHandler: @ escaping (String?) -> Void)
    func markChatAsRead(chatRoom: String, chatID: String)
    //func addHotelToConfig(hotelId: String, hotelName: String)
    func updatePhoneData(phoneUserId: String, phoneID: String, phoneLang: String)
    func writeReview(group: String, id: String, rating: Int, review: String, completionHandler: @ escaping () -> Void)
    func addHotel(hotelId: String, hotelName: String, completionHandler: @ escaping (Error?) -> Void)
    func writeMenuList(restaurantId: String, menuList: [String], completionHandler: @ escaping () -> Void)
    //func updateGuest(hotelId: String, guestId: String, guestData: GuestInDB, completionHandler: @ escaping () -> Void)
    func log(level: Log.LogLevel, s: String)

    func assignChat(chatRoom: String, to user: String)
    func writeChat(chatRoomID: String, message m: ChatMessage)
    func changePassword(oldPassword: String, newPassword: String, completionHandler: @ escaping (Error?) -> Void)
    
    func getRoomList(hotelId: String, completionHandler: @ escaping ([Int]) -> Void)
    func getHotelList(completionHandler: @ escaping ([String:String]) -> Void)

    var isConnected: Bool { get }
}

// extensions are needed as a workaround to no default parameters in protocols
extension DBProxy {
    func addRecord<T: Encodable>(key:String?, record: T, completionHandler: @ escaping (String?, T?) -> Void) -> String? {
        return addRecord(key:key, subNode: nil, record: record, completionHandler: completionHandler)
    }
    func addRecord<T: Encodable>(record: T, completionHandler: @ escaping (String?, T?) -> Void) -> String? {
        return addRecord(key:nil, subNode: nil, record: record, completionHandler: completionHandler)
    }
    func removeRecord<T: Encodable>(key:String, record: T, completionHandler: @ escaping (T?) -> Void) -> String? {
        return removeRecord(key:key, subNode: nil, record: record, completionHandler: completionHandler)
    }
    @discardableResult
    func subscribeForUpdates<T: Codable>(subNode: String?, parameter: QueryParameter?, completionHandler: @ escaping ([String:T]) -> Void) -> Any? {
        return subscribeForUpdates(subNode: subNode, start: nil, limit: nil, parameter: parameter, completionHandler: completionHandler)
    }
    @discardableResult
    func subscribeForUpdates<T: Codable>(parameter: QueryParameter?, completionHandler: @ escaping ([String:T]) -> Void) -> Any? {
        return subscribeForUpdates(subNode: nil, parameter: parameter, completionHandler: completionHandler)
    }
    @discardableResult
    func subscribeForUpdates<T: Codable>(completionHandler: @ escaping ([String:T]) -> Void) -> Any? {
        return subscribeForUpdates(subNode: nil, parameter: nil, completionHandler: completionHandler)
    }

    func unsubscribe<T: Codable>(t: T.Type) {
        unsubscribe(t: t, subNode: nil, parameter: nil)
    }
}
/*
extension DBProxy {
    func updateOrderStatus(orderId: String, newStatus: OrderStatus, confirmedBy: String?) {
        updateOrderStatus(orderId: orderId, newStatus: newStatus, confirmedBy: confirmedBy, deliveredBy: nil, canceledBy: nil)
    }
    func updateOrderStatus(orderId: String, newStatus: OrderStatus, deliveredBy: String?) {
        updateOrderStatus(orderId: orderId, newStatus: newStatus, confirmedBy: nil, deliveredBy: deliveredBy, canceledBy: nil)
    }
    func updateOrderStatus(orderId: String, newStatus: OrderStatus, canceledBy: String?) {
        updateOrderStatus(orderId: orderId, newStatus: newStatus, confirmedBy: nil, deliveredBy: nil, canceledBy: canceledBy)
    }
}
*/
/*
extension DBProxy {
    func uploadImage(image: UIImage, forLocation: PhotoLocation, completionHandler: @escaping (String) -> Void) {
        uploadImage(image: image, forLocation: forLocation, imageName: nil, completionHandler: completionHandler)
    }
}
*/
