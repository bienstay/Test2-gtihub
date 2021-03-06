//
//  MessageKitChatViewController.swift
//  Test2
//
//  Created by maciulek on 13/07/2021.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import AVFoundation


public struct Sender: SenderType {
    public let senderId: String
    public let displayName: String
    public let isStaff: Bool
}

struct Message: MessageType {
    
    let senderId: String
    let senderName: String
    let isSenderStaff: Bool
    let text: String
    let messageId: String
    let timestamp: Date
    let translations: [String:String]?
    var read: Bool

    var sender: SenderType {
        return Sender(senderId: senderId, displayName: senderName, isStaff: isSenderStaff)
    }

    var sentDate: Date {
        return timestamp
    }
    
    var kind: MessageKind {
        let attr: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 18)
        ]
        let s = NSMutableAttributedString(string: text, attributes: attr)
        s.append(translatedText)
        return .attributedText(s)
    }

    var translatedText: NSAttributedString {
        let attr: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.red,
            .font: UIFont.systemFont(ofSize: 16)
        ]
        // if I am a user, show how my messages got translated on the client devices
        if phoneUser.isStaff, senderId == phoneUser.id, let translations = translations {
            let s = NSMutableAttributedString()
            for t in translations.values {
                if t != text {
                    let tText = NSAttributedString(string: "\n"+t, attributes: attr)
                    s.append(tText)
                }
            }
            return s
        }
        // always show what has been translated to my language
        else if let t = translations?[phoneUser.lang], t != text {
            return NSAttributedString(string: "\n"+t, attributes: attr)
        }

        return NSAttributedString()
    }
/*
    var kind: MessageKind {
        //let orgColor:UIColor = senderId == phoneUser.id ? .white : .black
        let orgColor:UIColor = .black
        let orgAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: orgColor, .font: UIFont.systemFont(ofSize: 18)]
        let orgText = NSMutableAttributedString(string: text, attributes: orgAttributes)
        // show what has been translated to my language
        if let t = translations?[phoneUser.lang], t != text {
            let tAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.red, .font: UIFont.systemFont(ofSize: 16)]
            let tText = NSAttributedString(string: "\n" + t, attributes: tAttributes)
            orgText.append(tText)
        } else if senderId == phoneUser.guest?.id, phoneUser.isStaff, let translations = translations {
        // show what the receiver(s) had seen if you are an admin
            for t in translations.values {
                if t != text {
                    let tAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.purple, .font: UIFont.systemFont(ofSize: 16)]
                    let tText = NSAttributedString(string: "\n" + t, attributes: tAttributes)
                    orgText.append(tText)
                }
            }
        }

        return .attributedText(orgText)
//        return .text(text)
    }
 */
}


class MessageKitChatViewController: MessagesViewController {
    var chatRoom: ChatRoom?
    var messages: [Message] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
        configure()

        NotificationCenter.default.addObserver(self, selector: #selector(onMessageAdded(_:)), name: .chatMessageAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onMessageDeleted(_:)), name: .chatMessageDeleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onMessageUpdated(_:)), name: .chatMessageUpdated, object: nil)
        reloadMessages()
        DispatchQueue.main.async {
            self.messagesCollectionView.reloadData()
            self.messagesCollectionView.scrollToLastItem(animated: true)
        }
        removeMessageAvatars()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if self.isFirstResponder != true {
            self.becomeFirstResponder()     // this is necessary for the input view to show up
        }
    }

    @objc func onMessageAdded(_ notification: Notification) {
        let start = appendMessages()
        let sections: IndexSet = IndexSet(integersIn: start...messages.count - 1)
        messagesCollectionView.insertSections(sections)
        messagesCollectionView.reloadSections(sections)
        messagesCollectionView.scrollToLastItem(animated: true)
        if let m = notification.object as? ChatMessage, m.senderID != phoneUser.id {
            let systemSoundID: SystemSoundID = 1105
            AudioServicesPlaySystemSound(systemSoundID)
        }
    }

    @objc func onMessageDeleted(_ notification: Notification) {
        reloadMessages()
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)
    }

    @objc func onMessageUpdated(_ notification: Notification) {
        if let m = notification.object as? ChatMessage, let i = messages.firstIndex(where: {m.id == $0.messageId} ) {
            let newM = Message(senderId: m.senderID, senderName: m.senderName, isSenderStaff: m.isSenderStaff, text: m.content, messageId: m.id!, timestamp: m.created, translations: m.translations, read: m.read ?? false)
            messages[i] = newM
            messagesCollectionView.reloadSections([i])
        }
    }

    func appendMessages() -> Int {
        guard let chatRoom = chatRoom else { return 0 }
        guard messages.count <= chatRoom.messages.count else {  // sth is not right, reload
            reloadMessages()
            return 0
        }
        let start = messages.count
        for i in start...chatRoom.messages.count-1 {
            let m = chatRoom.messages[i]
            messages.append(Message(senderId: m.senderID, senderName: m.senderName, isSenderStaff: m.isSenderStaff, text: m.content, messageId: m.id!, timestamp: m.created, translations: m.translations, read: m.read ?? false))
        }
        return start
    }

    func reloadMessages() {
        guard let chatRoom = chatRoom else { return }
        messages = []
        for m in chatRoom.messages {
            messages.append(Message(senderId: m.senderID, senderName: m.senderName, isSenderStaff: m.isSenderStaff, text: m.content, messageId: m.id!, timestamp: m.created, translations: m.translations, read: m.read ?? false))
        }
        messages.sort(by: {$0.sentDate < $1.sentDate})
    }

    func markAsRead(m: Message) {
        guard let chatRoom = chatRoom else { return }
        // do not mark as read if one staff member reads msg from another staff
        let sameSource:Bool = (m.isSenderStaff == phoneUser.isStaff)
        let sameSender = (m.sender.senderId == phoneUser.id)
        if !m.read && !sameSender && !sameSource {
            dbProxy.markChatAsRead(chatRoom: chatRoom.id, chatID: m.messageId)
        }
    }

    func isFromCurrentUser(message: MessageType) -> Bool {
        if let sender = message.sender as? Sender {
            let b = message.sender.senderId == phoneUser.id || phoneUser.isStaff && sender.isStaff
            return b
        }
        return message.sender.senderId == phoneUser.id
    }

    func configure() {
        messageInputBar.contentView.backgroundColor = .darkGray
        messageInputBar.inputTextView.textColor = .white
        messageInputBar.inputTextView.layer.cornerRadius = 16.0
        messageInputBar.inputTextView.layer.masksToBounds = true
        
        messageInputBar.sendButton.setTitleColor(.white, for: .normal)
        messageInputBar.sendButton.setTitleColor(.white.withAlphaComponent(0.3), for: .highlighted)
    }
}



extension MessageKitChatViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        Sender(senderId: phoneUser.id, displayName: phoneUser.displayName, isStaff: phoneUser.isStaff)
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        let m = messages[indexPath.section]
        //if phoneUser.role != .hotline { markAsRead(m: m) }  // hotline operator can reassign, so keep message unread
        if !phoneUser.isAllowed(to: .manageChats) { markAsRead(m: m) }  // hotline operator can reassign, so keep message unread
        return m
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }

    func messageTopLabelAttributedText(for message: MessageType,at indexPath: IndexPath) -> NSAttributedString? {
        let s = NSAttributedString(string: message.sender.displayName, attributes: [.font: UIFont.preferredFont(forTextStyle: .caption1)])
        return s
    }

    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let s = NSAttributedString(string: message.sentDate.formatForDisplay(), attributes: [.font: UIFont.preferredFont(forTextStyle: .caption2), .foregroundColor: UIColor.lightGray])
        return s
    }

}

extension MessageKitChatViewController: MessagesLayoutDelegate {

    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {

        return 15
    }

    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 15
    }
/*
    func footerViewSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: 0, height: 8)
    }
*/
}

extension MessageKitChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard let chatRoom = chatRoom else { return }
        // hotline operator can assign so mark as read only when he writes sth (means that he replies)
        if phoneUser.isAllowed(to: .manageChats) {
            for m in messages { markAsRead(m: m) }
        }

        let newChatMessage = ChatMessage(created: Date(), content: text, senderID: phoneUser.id, senderName: phoneUser.displayName, isSenderStaff: phoneUser.isStaff, chatRoomID: chatRoom.id)
        //_ = dbProxy.addRecord(key: nil, subNode: chatRoomId, record: newChatMessage) { _ in }
        dbProxy.writeChat(chatRoomID: chatRoom.id, message: newChatMessage)
        inputBar.inputTextView.text = ""
    }
}







extension MessageKitChatViewController: MessagesDisplayDelegate {
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView ) -> UIColor {
      //return isFromCurrentSender(message: message) ? .primary : .incomingMessage
        return isFromCurrentUser(message: message) ? .pastelGreenLight : .offWhiteLight
    }

    func shouldDisplayHeader(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> Bool {
      return false
    }

    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {

        avatarView.backgroundColor = .blue
        avatarView.isHidden = true
    }

    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
            let corner: MessageStyle.TailCorner =
        isFromCurrentUser(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
}

extension MessageKitChatViewController {
    private func removeMessageAvatars() {
      guard
        let layout = messagesCollectionView.collectionViewLayout
          as? MessagesCollectionViewFlowLayout
      else {
        return
      }
      layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
      layout.textMessageSizeCalculator.incomingAvatarSize = .zero
      layout.setMessageIncomingAvatarSize(.zero)
      layout.setMessageOutgoingAvatarSize(.zero)
      let incomingLabelAlignment = LabelAlignment(
        textAlignment: .left,
        textInsets: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0))
      layout.setMessageIncomingMessageTopLabelAlignment(incomingLabelAlignment)
      let outgoingLabelAlignment = LabelAlignment(
        textAlignment: .right,
        textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15))
      layout.setMessageOutgoingMessageTopLabelAlignment(outgoingLabelAlignment)
    }
}
