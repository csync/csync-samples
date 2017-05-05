/*
* Copyright IBM Corporation 2016-2017
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation
import CSyncSDK

struct Config {let host: String; let port: Int; let authenticationProvider: String; let token: String; let options: [String:AnyObject]}

class CSyncDataManager {

	static var sharedInstance=CSyncDataManager.init()

	//CSync App
	let cSyncApp : App

	//CSKeys
	private var roomListKey : Key //Key used to monitor all chat room, is static
	private var messagesKey : Key? //Key used to monitor a specific chat room for messages
	private var roomKey : Key? //Key used to monitor a chat room to see information about that chat room

	//Completion Handlers
	private var roomListCompletionHandler: ((Room, Bool) -> Void)? = nil
	private var messagesCompletionHandler: ((Message) -> Void)? = nil
	private var roomCompletionHandler: ((Room, Bool) -> Void)? = nil

	private init(){
		//TODO: get from a config file
		//connect to a CSync Instance
		let config = CSyncDataManager.getConfig()
		cSyncApp = App(host: config.host, port: config.port, options: config.options)
		//setup room key since it is static
		roomListKey = cSyncApp.key("rooms.*")
	}

	// MARK: - CSyncDataManager Authentication Functions

	/*
	This is how you would authenticate a user in Contectual Sync using Google Sign-In SDK for iOS
	https://developers.google.com/identity/sign-in/ios/sdk/
	//Authenticate a Google User in CSync
	func authenticate(googleUser user: GIDGoogleUser,callback: @escaping (Bool) ->()){
	cSyncApp.authenticate("google", token: user.authentication.idToken) { authData, error in
	if error != nil {
	print(error.debugDescription)
	callback(false)
	}
	else{
	User.setCurrentUser(authData!, user: user)
	callback(true)
	}
	}
	}
	*/

	//Authenticate a dummy user in CSync
	func authenticate(withName name : String?,callback: @escaping (Bool) ->()){
		let config = CSyncDataManager.getConfig()

		let loginToken : String
		let sanitizedName : String

		if let nameParm = name , nameParm != "" {
			sanitizedName = nameParm
			loginToken = config.token + "(" + nameParm + ")"
		}
		else {
			sanitizedName = config.authenticationProvider
			loginToken = config.token
		}
		cSyncApp.authenticate(config.authenticationProvider, token: loginToken) { authData, error in
			if error != nil {
				print(error.debugDescription)
				callback(false)
			}
			else if let authData = authData{
				User.setCurrentUser(authData.provider, googleId: nil, name: sanitizedName, email : "", smallImageUrl: nil, largeImageUrl: nil)
				callback(true)
			}
		}
	}

	// MARK: - CSyncDataManager Listening Functions

	//Start listening for Chat rooms being added, edited or removed
	func startListeningForRoomListChanges(callback: @escaping (Room, Bool) -> ()){
		roomListCompletionHandler = callback
		roomListKey.listen(roomsListener)

	}

	//Stop Listening on Chat rooms
	func stopListeningForRoomListChanges(){
		roomListKey.unlisten()
		roomListCompletionHandler = nil
	}

	//Start Listening for messages in a chat room
	func startListeningForMessages(onChatRoom room: Room, callback: @escaping (Message) -> ()){
		messagesCompletionHandler = callback
		messagesKey?.unlisten()
		messagesKey = cSyncApp.key("rooms." + room.roomId + ".*")
		messagesKey?.listen(messageListener)
	}

	//Stop listening for messages in a chat room
	func stopListeningForMessagesOnChatRoom(){
		messagesKey?.unlisten()
		messagesKey = nil
		messagesCompletionHandler = nil
	}

	//Start Listening for changes on a single chatroom
	func startListening(onChatRoom room: Room, callback: @escaping (Room, Bool) -> ()){
		roomCompletionHandler = callback
		roomKey?.unlisten()
		roomKey = cSyncApp.key("rooms."+room.roomId)
		roomKey?.listen(roomListener)
	}

	//Stop Listening for changes on a single chatroom
	func stopListeningOnRoom(){
		roomKey?.unlisten()
		roomKey = nil
		roomCompletionHandler = nil
	}

	// MARK: - CSyncDataManager Adding Functions

	func add(_ room: Room){
		let acl = room.isPrivate ? ACL.Private : ACL.PublicReadCreate
		//creates a new key under the parent rooms key
		let roomKey = roomListKey.parent.child(room.roomId)
		//persist this key to CSyncDatabase
		roomKey.write(room.roomName, with: acl, completionHandler: nil)
	}

	func add(_ message: Message){
		//room key looks like roooms.roomId.*, create a child under it for our message in the form: rooms.roomId.messageID
        guard let messagesKey = self.messagesKey else { return }
		let keyToBeAdded = messagesKey.parent.child(message.messageId)
		keyToBeAdded.write(message.value, with: ACL.PublicRead) { (key, error) -> () in
			if let error = error {
				print("write for key \(messagesKey.key) failed: \(error)")
			}
		}
	}

	func edit(_ room: Room){
		let newAcl = room.isPrivate ? ACL.Private : ACL.PublicReadCreate
		roomKey?.write(room.roomName, with: newAcl) { (key, error) -> () in
			if let error = error {
				print("write for key \(String(describing: self.roomKey?.key)) failed: \(error)")
			}
		}
	}

	func delete(_ room: Room){
		if roomKey != nil{
			stopListeningOnRoom()
		}
		roomKey = cSyncApp.key(["rooms",room.roomId])
		roomKey?.delete()
	}

	// MARK: - CSyncDataManager Private Functions

	private func roomsListener(_ roomData: Value?, error: NSError?) {
		guard Thread.isMainThread else {
			DispatchQueue.main.async {
				self.roomsListener(roomData, error: error)
			}
			return
		}
		guard error == nil else {
			print("listener got error \(error!)")
			return
		}
		guard let roomData = roomData else {
			print("listener got nil value")
			return
		}
		let roomId = roomData.key.lastComponent()
		let room = Room.init(roomId: roomId!, roomName: roomData.data ?? "", isPrivate: roomData.acl == ACL.Private.id, allowUpdate: (roomData.creator == cSyncApp.authData?.uid))
		roomListCompletionHandler?(room, roomData.exists)
	}

	private func roomListener(_ roomData: Value?, error: NSError?) {
		guard Thread.isMainThread else {
			DispatchQueue.main.async {
				self.roomListener(roomData, error: error)
			}
			return
		}
		guard error == nil else {
			print("listener got error \(error!)")
			return
		}
		guard let roomData = roomData else {
			print("listener got nil value")
			return
		}
		if let completionHandler = roomCompletionHandler {
			let roomId = roomData.key.lastComponent()
			let room = Room.init(roomId: roomId!, roomName: roomData.data ?? "", isPrivate: roomData.acl == ACL.Private.id, allowUpdate: (roomData.creator == cSyncApp.authData?.uid))
			completionHandler(room, roomData.exists)
		}
	}

	private func messageListener(_ messageData: Value?, error: NSError?) {
		guard Thread.isMainThread else {
			DispatchQueue.main.async {
				self.messageListener(messageData, error: error)
			}
			return
		}
		guard error == nil else {
			print("listener got error \(error!)")
			return
		}

		if let messageId = messageData!.key.lastComponent(),
			let msgData = messageData!.data,
			let message = Message(messageId: messageId, message: msgData){
			messagesCompletionHandler?(message)
		}
	}

	static private func getConfig() -> Config {
		//let configPlist = Bundle(identifier:"com.ibm.CSyncChat")?.path(forResource: "Config", ofType: "plist")
		let configPlist = Bundle.main.path(forResource: "Config", ofType: "plist")
		let configDict = configPlist.map { plist in NSDictionary(contentsOfFile:plist) }

		guard let host = configDict??["CSYNC_HOST"] as? String,
			let port = configDict??["CSYNC_PORT"] as? Int,
			let authenticationProvider = configDict??["CSYNC_DEMO_PROVIDER"] as? String,
			let token = configDict??["CSYNC_DEMO_TOKEN"] as? String else{
				fatalError("Unable to find CSync config information, please specify in Config.plist")
		}

		if host == ""{
			fatalError("Unable to find CSync config information, please specify in Config.plist")
		}

		return Config(host: host, port: port, authenticationProvider: authenticationProvider, token: token, options:["useSSL":"NO" as AnyObject, "dbInMemory":"YES" as AnyObject])
	}
}
