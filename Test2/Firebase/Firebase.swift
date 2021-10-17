//
//  Firebase.swift
//  Test2
//
//  Created by maciulek on 16/10/2021.
//


import Foundation
import Firebase
import FirebaseDatabase
import FirebaseStorage

final class FireB {
    static let shared: FireB = FireB()
    private init() { }

    func initialize() {
        Database.database().isPersistenceEnabled = true
    }

    enum PhotoLocation {
        case NEWS
        case ACTIVITIES
        case RESTAURANTS
    }

    // MARK: - Firebase Database References
    var BASE_DB_REF: DatabaseReference { Database.database().reference().child("hotels").child(hotel.id) }
    var INFO_DB_REF: DatabaseReference          { BASE_DB_REF }
    var GUESTS_DB_REF: DatabaseReference        { BASE_DB_REF.child("users") }
    var NEWS_DB_REF: DatabaseReference          { BASE_DB_REF.child("news") }
    var ACTIVITIES_DB_REF: DatabaseReference    { BASE_DB_REF.child("activities") }
    var RESTAURANTS_DB_REF: DatabaseReference   { BASE_DB_REF.child("restaurants") }
    var MENUS_DB_REF: DatabaseReference         { BASE_DB_REF.child("menus") }
    var ORDERS_DB_REF: DatabaseReference        { BASE_DB_REF.child("orders") }
    var LIKES_DB_REF: DatabaseReference         { BASE_DB_REF.child("likes") }
    var LIKESGLOBAL_DB_REF: DatabaseReference   { LIKES_DB_REF.child("global") }
    var LIKESPERUSER_DB_REF: DatabaseReference  { LIKES_DB_REF.child("perUser") }
    var CHAT_MESSAGES_DB_REF: DatabaseReference { BASE_DB_REF.child("chats").child("messages") }

    // MARK: - Firebase Storage Reference
    let BASE_PHOTOS_REF: StorageReference = Storage.storage().reference().child( "photos")
    let NEWS_PHOTOS_REF: StorageReference = Storage.storage().reference().child( "photos/news")
    let ACTIVITIES_PHOTOS_REF: StorageReference = Storage.storage().reference().child( "photos/activities")
    let RESTAURANTS_PHOTOS_REF: StorageReference = Storage.storage().reference().child( "photos/restaurants")

    var observed: Set<DatabaseQuery> = []

    func getDBRef<T>(type: T.Type, subNode: String? = nil) -> DatabaseReference? {
        switch type {
            case is HotelIInfo.Type:
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
            case is Restaurant.Type:
                return RESTAURANTS_DB_REF
            case is Menu.Type:
                return MENUS_DB_REF
            case is ChatMessage.Type:
                return CHAT_MESSAGES_DB_REF
            case is GuestInfo.Type:
                return GUESTS_DB_REF
            case is LikesPerUserInDB.Type:
                if let child = subNode { return LIKESPERUSER_DB_REF.child(child) }
                else { return LIKESPERUSER_DB_REF }
            case is LikesInDB.Type:
                if let child = subNode { return LIKESGLOBAL_DB_REF.child(child) }
                else { return LIKESGLOBAL_DB_REF }
            default:
                return nil
        }
    }

    enum QueryParameter {
        case OrderInDB(roomNumber: Int)
        case ChatRoom(id: String)
        case ChatUser(id: String)
        case GuestInfo(id: String)
        case DailyActivities2(id: String)
    }

    func getQuery<T>(type: T.Type, subNode: String? = nil, parameter:QueryParameter? = nil) -> DatabaseQuery? {
        let dbRef = getDBRef(type: type.self, subNode: subNode)
        let errStr = "Invalid parameter in getQuery for \(T.Type.self): \(String(describing: parameter))"
        switch type {
            case is HotelIInfo.Type:
                return dbRef?.queryOrderedByKey().queryEqual(toValue: "info")
            case is GuestInfo.Type:
                guard case .GuestInfo(let guestId) = parameter else { Log.log(errStr); return nil }
                return dbRef?.queryOrderedByKey().queryEqual(toValue: guestId)
            case is OrderInDB.Type:
                guard case .OrderInDB(let roomNumber) = parameter else { Log.log(errStr); return nil }
                if roomNumber > 0 {
                    return dbRef?.queryOrdered(byChild: "roomNumber").queryEqual(toValue: roomNumber)
                } else {
                    return dbRef?.queryOrderedByKey()
                    //return dbRef?.queryOrdered(byChild: "roomNumber")
                }
            case is ChatMessage.Type:
                guard case .ChatRoom(let chatRoomId) = parameter else { Log.log(errStr); return nil }
                return dbRef?.child(chatRoomId)
            default:
                return dbRef
        }
    }

    func uploadImage(image: UIImage, forLocation: PhotoLocation, imageName: String? = nil, completionHandler: @escaping (String) -> Void) {
        // Generate a unique ID for the post and prepare the post database reference
        var photosStorageRef = BASE_PHOTOS_REF
        switch forLocation {
            case .NEWS:
                photosStorageRef = NEWS_PHOTOS_REF
            case .ACTIVITIES:
                photosStorageRef = ACTIVITIES_PHOTOS_REF
            case .RESTAURANTS:
                photosStorageRef = RESTAURANTS_PHOTOS_REF
        }

        // Use the unique key as the image name and prepare the storage reference
        //guard let imageKey = postDatabaseRef.key else { return }
        let imageKey = (imageName != nil ? imageName! : (Auth.auth().currentUser?.uid)! + "___" + Date().formatFull())
        Log.log(level: .INFO, "Uploading image with the key: " + imageKey)

        photosStorageRef = photosStorageRef.child("\(imageKey).jpg")

        // Resize the image
        let scaledImage = image.scaleTo(newWidth: 1280.0)
        guard let imageData = scaledImage.jpegData(compressionQuality: 0.5) else {
            Log.log("failed to convert to jpeg")
            return
        }

        // Create the file metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpg"
        metadata.cacheControl = "public,max-age=3600"

        // Prepare the upload task
        let uploadTask = photosStorageRef.putData(imageData, metadata: metadata) // Observe the upload status

        uploadTask.observe(.success) { (snapshot) in
            snapshot.reference.downloadURL(completion: { (url, error) in
                guard let url = url else { Log.log("Error getting downloadURL"); return }
                Log.log(level: .INFO, "\(url) uploaded")
                completionHandler(url.absoluteString)
            })
        }

        uploadTask.observe(.progress) { (snapshot) in
            let percentComplete: Double = Double(100.0) * Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
            Log.log(level: .INFO, "Uploading \(imageKey)... \(percentComplete)% complete")
        }

        uploadTask.observe(.failure) { (snapshot) in
            if let error = snapshot.error {
                Log.log(error.localizedDescription)
            }
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
                        Log.log(level: .ERROR, "error uploading key \(String(describing: key))")
                        Log.log(level: .ERROR, err.localizedDescription)
                        completionHandler(nil)
                    } else {
                        Log.log(level: .INFO, "Record with key \(String(describing: key)) added to \(dbRef.url.localized)")
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
                    Log.log(err.localizedDescription)
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


    func subscribeForUpdates<T: Codable>(subNode: String? = nil, start timestamp: Int? = nil, limit: UInt? = nil, parameter: QueryParameter? = nil, completionHandler: @ escaping ([(String, T)]) -> Void) {
        
        guard let query = getQuery(type: T.self, subNode: subNode, parameter: parameter) else { return }
        Log.log(level: .INFO, "observing " + query.description)
        print(query.ref.url)
        observed.insert(query)
        query.observe(.value, with: { (snapshot) in
            var objects: [(String, T)] = []
            Log.log(level: .INFO, "adding \(snapshot.children.allObjects.count) new objects of type \(T.self)")
            for item in snapshot.children.allObjects as! [DataSnapshot] {
                let decoder = JSONDecoder()
                if JSONSerialization.isValidJSONObject(item.value!) {
                    let data = try? JSONSerialization.data(withJSONObject: item.value!)
                    do {
                        let object = try decoder.decode(T.self, from: data!)
                        objects.append((item.key, object))
                    } catch {
                        Log.log("Failed to decode JSON")
                        Log.log(item.debugDescription)
                        Log.log(data.debugDescription)
                        Log.log(error.localizedDescription)
                    }
                }
            }
            Log.log(level: .INFO, "\(objects.count) new objects of type \(T.self) added")

            completionHandler(objects)
        })
    }

    func removeAllObservers() {
        for query in observed {
            query.removeAllObservers()
        }
        observed.removeAll()
    }
    
    func decodeSnapshot<T: Codable>(snapshot: DataSnapshot) -> [(String, T)] {
        var objects: [(String, T)] = []
        Log.log(level: .INFO, "decoding \(snapshot.children.allObjects.count) new objects of type \(T.self)")
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
                Log.log(error.localizedDescription)
            }
        }
        return objects
    }
}