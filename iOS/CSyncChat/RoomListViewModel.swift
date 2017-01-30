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

enum RoomSection: Int {
	case privateRoom = 0
	case publicRoom = 1
}

class RoomListViewModel {

	private var roomListCompletionHandler: (() -> Void)? = nil

	private var chatRooms : [[Room]] = [[],[]]
	private var currentlyListening = false
	private let cSyncDataManager = CSyncDataManager.sharedInstance

	init(withRoomListCompletionHandler roomListHandler: (() -> ())?){
		roomListCompletionHandler = roomListHandler
	}

	deinit {
		stopListening()
	}

	// MARK: - Listening Functions
	func startListening(){
		//Return if we are already listening for changes
		if currentlyListening{
			return
		}
		currentlyListening = true

		cSyncDataManager.startListeningForRoomListChanges(){ [unowned self] room, stillExists in
			//find the type of room so we know what list to put it in
			let type = room.isPrivate ? RoomSection.privateRoom : RoomSection.publicRoom

			//Is the item already in the list?
			if let index = self.chatRooms[type.rawValue].index(of: room){
				if stillExists {
					//If it is already in the list and still exists in CSync, update it
					self.chatRooms[type.rawValue][index] = room
				} else {
					//If it is already in the list and was deleted in CSync, delete it
					self.chatRooms[type.rawValue].remove(at: index)
				}
			}
			else if stillExists{
				//add the item if it wasn't already in the array and it still exists
				let pos = self.chatRooms[type.rawValue].filter({ elem in elem.roomName<room.roomName }).count
				self.chatRooms[type.rawValue].insert(room, at: pos)
			}
			//TODO: Update table with individual changes rather then forcing a refresh
			self.roomListCompletionHandler?()
		}
	}

	func stopListening(){
		if currentlyListening {
			cSyncDataManager.stopListeningForRoomListChanges()
			currentlyListening = false
		}
		chatRooms = [[],[]]
	}


	// Returns the number of rows
	func numberOfRows(in section : Int) -> Int {
		return chatRooms[section].count
	}

	func room(forIndex index: Int, inSection section: Int) -> Room {
		return chatRooms[section][index]
	}

	func add(room: Room, ofType type: RoomSection) {
		if type == .publicRoom{
			room.isPrivate = false
		}
		else {
			room.isPrivate = true
		}
		cSyncDataManager.add(room)
		let pos = self.chatRooms[type.rawValue].filter({ elem in elem.roomName<room.roomName }).count
		self.chatRooms[type.rawValue].insert(room, at: pos)
		roomListCompletionHandler?()
	}
}
