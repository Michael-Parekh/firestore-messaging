//
//  MessagesManager.swift
//  Firestore Messaging
//
//  Created by Michael Parekh on 4/13/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

// The 'MessagesManager' reads and writes to the Firestore database in real-time.
class MessagesManager: ObservableObject {
    // Make 'messages' a 'Published' value so that 'ContentView' redraws whenever new messages are created.
    @Published private(set) var messages: [Message] = []
    @Published private(set) var lastMessageId = ""
    
    // Create an instance of our Firestore database.
    let db = Firestore.firestore()
    
    init() {
        // On initialization of the class, get the messages from the database. 
        getMessages()
    }
    
    // Read messages from Firestore in real-time using the 'addSnapshotListener'.
    func getMessages() {
        db.collection("messages").addSnapshotListener { querySnapshot, error in
            // Exit the function if we do not have any documents.
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(String(describing: error))")
                return
            }
            
            // 'compactMap' is similar to a regular map, except that it will only return the non-nil values of the document array.
            self.messages = documents.compactMap { document -> Message? in
                do {
                    // Convert each document into the 'Message' model (note that 'data(as:)' is a function available only in the 'FirebaseFirestoreSwift' package).
                    return try document.data(as: Message.self)
                } catch {
                    print("Error decoding document into Message: \(error)")
                    // Return nil if we run into an error (note that 'compactMap' will not include it in the final array).
                    return nil
                }
            }
            
            // Sort the messages by timestamp (oldest => newest). 
            self.messages.sort { $0.timestamp < $1.timestamp }
            
            // Unwrap the optional and get the ID of the last message so that we can automatically scroll to it in 'ContentView'.
            if let id = self.messages.last?.id {
                self.lastMessageId = id
            }
        }
    }
    
    // Add a message document in Firestore based on the 'text' argument.
    func sendMessage(text: String) {
        do {
            let newMessage = Message(id: "\(UUID())", text: text, received: false, timestamp: Date())
            // Create a new document in Firestore with 'newMessage' and use 'setData(from:)' to convert the 'Message' into Firestore data (note that 'setData(from:)' is only available in the 'FirebaseFirestoreSwift' package).
            try db.collection("messages").document().setData(from: newMessage)
        } catch {
            print("Error adding message to Firestore: \(error)")
        }
    }
}
