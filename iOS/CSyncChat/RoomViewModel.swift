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

class RoomViewModel {

	//Completion Handlers for messages and room changes
	private var messageCompletionHandler: (() -> Void)? = nil
	private var roomCompletionHandler: ((Room, Bool) -> Void)? = nil

	private var isListening = false

	private(set) var room : Room

	private var messages = [Message]()

	private let cSyncDataManager = CSyncDataManager.sharedInstance

	init(forRoom room: Room,withMessageCompletionHandler messageHandler: (() -> ())? = nil, withRoomCompletionHandler roomHandler: ((Room,Bool) -> ())? = nil){
		messageCompletionHandler = messageHandler
		roomCompletionHandler = roomHandler
		self.room = room
	}

	deinit {
		stopListening()
	}

	//MARK: - Listening Functions

	func startListening(){
		//if we are already listening, return
		if isListening{
			return
		}
		isListening = true

		// If we have a message completion handler, send messages and new indexes to the completionHandler
		if messageCompletionHandler != nil {
			cSyncDataManager.startListeningForMessages(onChatRoom: room){[unowned self] message in
				if let _ = self.messages.index(of: message){
					//TODO: ignore it for now, we need to do some handling here
				}
				else {
					//Add the message to the list
					let pos = self.messages.filter({ elem in elem<message }).count
					//insert the message
					self.messages.insert(message, at: pos)
					self.messageCompletionHandler?()
				}
			}
		}

		//if we have a room completion handler, send room changes to the completionHandler
		if roomCompletionHandler != nil {
			cSyncDataManager.startListening(onChatRoom: room){[unowned self]  room, stillExists in
				self.room = room
				self.roomCompletionHandler?(room,stillExists)
			}
		}
	}

	func stopListening() {
		if isListening == false {
			return
		}
		isListening = false
		cSyncDataManager.stopListeningOnRoom()
		cSyncDataManager.stopListeningForMessagesOnChatRoom()
		messages = []
	}

	// MARK: - Message Functions

	var numberOfMessages : Int {
		return messages.count
	}

	func message(atIndex index: Int) -> Message {
		return messages[index]
	}

	func send(_ message: Message){
		cSyncDataManager.add(message)
		//messages.append(message)
		//messageCompletionHandler?()
	}

	// MARK: - Room Functions

	func setRoomType(toPrivate isPrivate: Bool){
		//If there is no change, just return
		if room.isPrivate == isPrivate {
			return
		}

		room.isPrivate = isPrivate
		cSyncDataManager.edit(room)
	}

	func setRoomName(toString name: String){
		//If the roon name changed, persist the change
		if room.roomName != name{
			room.roomName = name
			cSyncDataManager.edit(room)
		}
	}

	func deleteRoom(){
		//deleting a room will stop us from listening on it.
		isListening = false
		cSyncDataManager.delete(room)
	}

	// MARK: - Timestamp functions

	//Creates a formatted timestamp for a message
	static func timestamp(forMessage message: Message) -> String{
		if message.timestamp.timeIntervalSinceNow < -24.0*60*60 {
			return dateAndTimeFormatter.string(from: message.timestamp as Date)
		} else if message.timestamp.timeIntervalSinceNow < -1.0*60 {
			return timeFormatter.string(from: message.timestamp as Date)
		} else {
			return "just now"
		}
	}

	static private let dateAndTimeFormatter : DateFormatter = {
		var df = DateFormatter()
		df.dateFormat = "MM/dd/yyyy hh:mma"
		return df
	}()

	static private let timeFormatter : DateFormatter = {
		var df = DateFormatter()
		df.dateFormat = "hh:mma"
		return df
	}()
}
