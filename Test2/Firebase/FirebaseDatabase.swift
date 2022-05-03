//
//  FirebaseDatabase.swift
//  Test2
//
//  Created by maciulek on 15/04/2022.
//

import Foundation
import Firebase
import FirebaseDatabase

final class FirebaseDatabase: DBProxy {    
    static let shared: FirebaseDatabase = FirebaseDatabase()

    var isConnected: Bool = false
    var serverTimeOffet:Double = 0.0

    var ROOT_DB_REF: DatabaseReference {
        return Firebase.shared.database.reference()
    }

    var BASE_DB_REF: DatabaseReference          {
        if let hotelId = hotel.id {
            return ROOT_DB_REF.child("hotels").child(hotelId)
        } else {
            return ROOT_DB_REF.child("hotels")
        }
    }

    //var CONFIG_DB_REF: DatabaseReference        { ROOT_DB_REF.child("config") }
    var DBINFO_DB_REF: DatabaseReference        { ROOT_DB_REF.child(".info") }
    var HOTEL_DB_REF: DatabaseReference         { BASE_DB_REF }
    var INFO_DB_REF: DatabaseReference          { BASE_DB_REF }
    //var GUESTS_DB_REF: DatabaseReference        { BASE_DB_REF.child("users") }
    var GUESTSNEW_DB_REF: DatabaseReference     { BASE_DB_REF.child("guests") }
    var NEWS_DB_REF: DatabaseReference          { BASE_DB_REF.child("news") }
    var ACTIVITIES_DB_REF: DatabaseReference    { BASE_DB_REF.child("activities") }
    var RESTAURANTS_DB_REF: DatabaseReference   { BASE_DB_REF.child("restaurants") }
    var FACILITIES_DB_REF: DatabaseReference    { BASE_DB_REF.child("facilities") }
    var MENUS_DB_REF: DatabaseReference         { BASE_DB_REF.child("menus2") }
    var ORDERS_DB_REF: DatabaseReference        { BASE_DB_REF.child("orders") }
    var OFFERGROUPS_DB_REF: DatabaseReference   { BASE_DB_REF.child("offerGroups") }
    var OFFERS_DB_REF: DatabaseReference        { BASE_DB_REF.child("offers") }
    var LIKES_DB_REF: DatabaseReference         { BASE_DB_REF.child("likes") }
    var LIKESGLOBAL_DB_REF: DatabaseReference   { LIKES_DB_REF.child("global") }
    var LIKESPERUSER_DB_REF: DatabaseReference  { LIKES_DB_REF.child("perUser") }
    var CHATROOMS_DB_REF: DatabaseReference    { BASE_DB_REF.child("chatRooms") }
    var CHATS_DB_REF: DatabaseReference         { BASE_DB_REF.child("chats") }
    var TRANSLATIONS_DB_REF: DatabaseReference  { BASE_DB_REF.child("translations") }
    var PHONES_DB_REF: DatabaseReference        { BASE_DB_REF.child("phones") }
    var LOGS_DB_REF: DatabaseReference          { BASE_DB_REF.child("logs") }

    var observed: Set<DatabaseQuery> = []

    func getDBRef<T>(type: T.Type, subNode: String? = nil) -> DatabaseReference? {
        switch type {
            case is HotelInDB.Type:
                return ROOT_DB_REF.child("hotels")
            case is HotelInfo.Type:
                return INFO_DB_REF
            case is NewsPost.Type:
                return NEWS_DB_REF
            case is DailyActivities.Type:
                if let child = subNode { return ACTIVITIES_DB_REF.child(child) }
                else { return ACTIVITIES_DB_REF }
            case is Activity.Type:
                if let child = subNode { return ACTIVITIES_DB_REF.child(child) }
                else { return ACTIVITIES_DB_REF }
            case is OrderInDB.Type:
                return ORDERS_DB_REF
            case is OfferGroup.Type:
                return OFFERGROUPS_DB_REF
            case is Offer.Type:
                return OFFERS_DB_REF
            case is Restaurant.Type:
                return RESTAURANTS_DB_REF
            case is Facility.Type:
                return FACILITIES_DB_REF
            case is Menu2.Type:
                return MENUS_DB_REF
            case is ChatRoomInDB.Type:
                return CHATROOMS_DB_REF
            case is ChatMessage.Type:
                if let child = subNode { return CHATS_DB_REF.child(child) }
                else { return CHATS_DB_REF }
            case is GuestInDB.Type:
                return GUESTSNEW_DB_REF
            case is LikesPerUserInDB.Type:
                if let child = subNode { return LIKESPERUSER_DB_REF.child(child) }
                else { return LIKESPERUSER_DB_REF }
            case is LikesInDB.Type:
                if let child = subNode { return LIKESGLOBAL_DB_REF.child(child) }
                else { return LIKESGLOBAL_DB_REF }
            case is Translations.Type:
                if let child = subNode { return TRANSLATIONS_DB_REF.child(child) }
                else { return TRANSLATIONS_DB_REF }
            case is LogInDB.Type:
                if let child = subNode { return LOGS_DB_REF.child(child) }
                else { return LOGS_DB_REF }
            default:
                return nil
        }
    }

    func getQuery<T>(type: T.Type, subNode: String? = nil, parameter:QueryParameter? = nil) -> DatabaseQuery? {
        let dbRef = getDBRef(type: type.self, subNode: subNode)
        let errStr = "Invalid parameter in getQuery for \(T.Type.self): \(String(describing: parameter))"
        switch type {
            case is HotelInfo.Type:
                return dbRef?.queryOrderedByKey().queryEqual(toValue: "info")
            case is GuestInfo.Type:
                guard case .GuestInfo(let guestId) = parameter else { Log.log(errStr); return nil }
                return dbRef?.queryOrderedByKey().queryEqual(toValue: guestId)
            case is GuestInDB.Type:
                guard case .GuestInDb(let guestId) = parameter else { Log.log(errStr); return nil }
                return dbRef?.queryOrderedByKey().queryEqual(toValue: guestId)
            case is OrderInDB.Type:
                guard case .OrderInDB(let roomNumber) = parameter else { Log.log(errStr); return nil }
                if roomNumber > 0 {
                    return dbRef?.queryOrdered(byChild: "roomNumber").queryEqual(toValue: roomNumber)
                } else {
                    return dbRef?.queryOrderedByKey()
                }
            case is ChatRoomInDB.Type:
                guard case .AssignedTo(let id) = parameter else {
                    return dbRef
                }
                return dbRef?.queryOrdered(byChild: "assignedTo").queryEqual(toValue: id)
            default:
                return dbRef
        }
    }

    func addRecord<T: Encodable>(key:String? = nil, subNode: String? = nil, record: T, completionHandler: @ escaping (T?) -> Void) -> String? {

        var errString:String? = nil
        if let jsonData = try? JSONEncoder().encode(record) {
            let dictionary = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]

            let dbRefForType = getDBRef(type: T.self, subNode: subNode)
            var dbRef = dbRefForType?.childByAutoId()
            if let key = key { dbRef = dbRefForType?.child(key) }

            if let dbRef = dbRef {
                dbRef.setValue(dictionary) { error, dbRef in
                    if let err = error {
                        Log.log(level: .ERROR, "error uploading key \(String(describing: key)) for record \(T.self) - \(err.localizedDescription)",
                                logInDb: T.Type.self != LogInDB.self)
                        completionHandler(nil)
                    } else {
                        if T.Type.self != LogInDB.Type.self {
                            Log.log(level: .INFO, "Record with key \(String(describing: key)) added to \(dbRef.url)")
                        }
                        completionHandler(record)
                    }
                }
            } else {
                errString = "dbRef nil for type \(T.self) and key \(String(describing: key))"
            }
        }
        else {
            errString = "JSONEncoder failed"
        }
        if let errStr = errString { Log.log(level: .ERROR, errStr) }
        return errString
    }

    func removeRecord<T: Encodable>(key:String, subNode: String? = nil, record: T, completionHandler: @ escaping (T?) -> Void) -> String? {
        let dbRefForType = getDBRef(type: T.self, subNode: subNode)
        let dbRef = dbRefForType?.child(key)

        var errString:String? = nil
        if let dbRef = dbRef {
            dbRef.removeValue() { error, dbRef in
                if let err = error {
                    Log.log("error removing key \(String(describing: key))")
                    Log.log(level: .ERROR, "\(err.localizedDescription)")
                    completionHandler(nil)
                } else {
                    Log.log(level: .INFO, "Record with key \(String(describing: key)) removed")
                    completionHandler(record)
                }
            }
        } else {
            errString = "dbRef nil for type \(T.self) and key \(String(describing: key))"
        }
        return errString
    }

    func subscribeForUpdates<T: Codable>(subNode: String? = nil, start timestamp: Int? = nil, limit: UInt? = nil, parameter: QueryParameter? = nil, completionHandler: @ escaping ([(String, T)], String?) -> Void) -> NSObject? {

        guard let query = getQuery(type: T.self, subNode: subNode, parameter: parameter) else { return nil }
        Log.log(level: .DEBUG, "observing " + query.description)
        observed.insert(query)
        query.observe(.value, with: { (snapshot) in
            var objects: [(String, T)] = []
            Log.log(level: .DEBUG, "adding \(snapshot.children.allObjects.count) new objects of type \(T.self)")
            for item in snapshot.children.allObjects as! [DataSnapshot] {
                let decoder = JSONDecoder()
                if JSONSerialization.isValidJSONObject(item.value!) {
                    let data = try? JSONSerialization.data(withJSONObject: item.value!)
                    do {
                        let object = try decoder.decode(T.self, from: data!)
                        objects.append((item.key, object))
                    } catch {
                        Log.log(level: .ERROR, "Failed to decode JSON for type \(T.self)")
                        Log.log(level: .ERROR, item.debugDescription)
                        Log.log(level: .ERROR, data.debugDescription)
                        Log.log(level: .ERROR, "\(error)")
                    }
                }
            }
            Log.log(level: .DEBUG, "\(objects.count) new objects of type \(T.self) added")

            completionHandler(objects, subNode)
        })
        return query
    }
    
    func unsubscribe<T>(t: T.Type, subNode: String) {
        guard let query = getQuery(type: T.self, subNode: subNode, parameter: nil) else { return }
        query.removeAllObservers()
    }

    func unsubscribe(handle: NSObject?) {
        if let ref = handle as? DatabaseReference {
            ref.removeAllObservers()
        }
    }

    func removeAllObservers() {
        for query in observed {
            query.removeAllObservers()
        }
        observed.removeAll()
    }

    func subscribeForNew<T: Codable>(subNode: String? = nil, parameter: QueryParameter? = nil, completionHandler: @ escaping (String, T) -> Void) {
        //guard let ref = getDBRef(type: T.self, subNode: subNode) else { return nil }
        guard let query = getQuery(type: T.self, subNode: subNode, parameter: parameter) else { return }
        Log.log(level: .DEBUG, "observing for new " + query.description)
        query.observe(.childAdded, with: { (snapshot) in
            //Log.log(level: .DEBUG, "\(snapshot.value) of type \(T.self) added")
            guard JSONSerialization.isValidJSONObject(snapshot.value!) else {
                Log.log("Invalid JSON: \(snapshot.value!) in query: \(query)")
                return
            }
            let data = try? JSONSerialization.data(withJSONObject: snapshot.value!)
            do {
                let object = try JSONDecoder().decode(T.self, from: data!)
                completionHandler(snapshot.key, object)
            } catch {
                Log.log("Failed to decode JSON: " + data.debugDescription)
                Log.log(level: .ERROR, "\(error)")
            }
        })
    }

    func subscribeForDeleted<T: Codable>(subNode: String? = nil, parameter: QueryParameter? = nil, completionHandler: @ escaping (String, T) -> Void) {
        guard let query = getQuery(type: T.self, subNode: subNode, parameter: parameter) else { return }
        Log.log(level: .DEBUG, "observing for deleted " + query.description)
        query.observe(.childRemoved, with: { (snapshot) in
            //Log.log(level: .DEBUG, "\(snapshot.value) of type \(T.self) added")
            let decoder = JSONDecoder()
            let data = try? JSONSerialization.data(withJSONObject: snapshot.value!)
            do {
                let object = try decoder.decode(T.self, from: data!)
                completionHandler(snapshot.key, object)
            } catch {
                Log.log("Failed to decode JSON: " + data.debugDescription)
                Log.log(level: .ERROR, "\(error)")
            }
        })
    }

    func subscribeForModified<T: Codable>(subNode: String? = nil, parameter: QueryParameter? = nil, completionHandler: @ escaping (String, T) -> Void) {
        guard let query = getQuery(type: T.self, subNode: subNode, parameter: parameter) else { return }
        Log.log(level: .DEBUG, "observing for deleted " + query.description)
        query.observe(.childChanged, with: { (snapshot) in
            //Log.log(level: .DEBUG, "\(snapshot.value) of type \(T.self) added")
            let decoder = JSONDecoder()
            let data = try? JSONSerialization.data(withJSONObject: snapshot.value!)
            do {
                let object = try decoder.decode(T.self, from: data!)
                completionHandler(snapshot.key, object)
            } catch {
                Log.log("Failed to decode JSON: " + data.debugDescription)
                Log.log(level: .ERROR, "\(error)")
            }
        })
    }


    func decodeSnapshot<T: Codable>(snapshot: DataSnapshot) -> [(String, T)] {
        var objects: [(String, T)] = []
        Log.log(level: .DEBUG, "decoding \(snapshot.children.allObjects.count) new objects of type \(T.self)")
        for item in snapshot.children.allObjects as! [DataSnapshot] {
            let decoder = JSONDecoder()
            let data = try? JSONSerialization.data(withJSONObject: item.value!)
            do {
                let object = try decoder.decode(T.self, from: data!)
                objects.append((item.key, object))
            } catch {
                Log.log("Failed to decode JSON")
                Log.log(item.debugDescription)
                Log.log(data.debugDescription)
                Log.log(level: .ERROR, "\(error)")
            }
        }
        return objects
    }
}