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

class Room : Equatable, Comparable
{
	let roomId : String
	var roomName : String
	var isPrivate : Bool
	var allowUpdate : Bool

	init(roomId: String, roomName: String) {
		self.roomId = roomId
		self.roomName = roomName
		self.isPrivate = false
		self.allowUpdate = true
	}

	init(roomId: String, roomName: String, isPrivate: Bool, allowUpdate: Bool){
		self.roomId = roomId
		self.roomName = roomName
		self.isPrivate = isPrivate
		self.allowUpdate = allowUpdate
	}

	convenience init(roomName: String) {
		self.init(roomId: UUID().uuidString, roomName: roomName)
	}
}

// Equatable protocol methods
internal func == (left: Room, right: Room) -> Bool {
	return (left.roomId == right.roomId)
}

// Comparable protocol methods
internal func < (left: Room, right: Room) -> Bool {
	return (left.roomName < right.roomName)
}
