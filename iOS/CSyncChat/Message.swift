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

struct Message : Equatable, Comparable
{
	let messageId : String
	let message : String
	let creatorId : String
	let creatorName : String
	let imageUrl : String?
	let timestamp : Date
	let isPrivate : Bool = false

	var value : String {
		let timestampInMs = Int64(timestamp.timeIntervalSince1970*1000)
		let urlprop = (imageUrl != nil) ? "\"imageUrl\": \"\(imageUrl!)\", " : ""
		return "{\"message\": \"\(message)\", \"creatorId\": \"\(creatorId)\", \"creatorName\": \"\(creatorName)\", "+urlprop+"\"timestamp\": \(timestampInMs) }"
	}


	init(messageId: String, message: String, creatorId: String, creatorName: String, imageUrl: String?, timestamp: Date) {
		self.messageId = messageId
		self.message = message
		self.creatorId = creatorId
		self.creatorName = creatorName
		self.imageUrl = imageUrl
		self.timestamp = timestamp
	}

	init?(message: String) {
		if let currentUser = User.currentUser {
			let creatorId = currentUser.userId
			let creatorName = currentUser.name
			let imageUrl = currentUser.smallImageUrl?.absoluteString
			let timestamp = Date()
			self.init(messageId: UUID().uuidString, message: message, creatorId: creatorId, creatorName: creatorName, imageUrl: imageUrl, timestamp: timestamp)
		} else {
			return nil
		}
	}

	init?(messageId: String, message: String) {
		guard let data = message.data(using: String.Encoding.utf8) else {
			self.init(messageId: "", message: "", creatorId: "", creatorName: "", imageUrl:"", timestamp: Date())
			return nil
		}

		do {
			let msgDict = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions(rawValue: 0)) as! [String:AnyObject]
			if let message = msgDict["message"] as? String,
				let creatorId = msgDict["creatorId"] as? String,
				let creatorName = msgDict["creatorName"] as? String,
				let imageUrl = msgDict["imageUrl"] as? String?,
				let timestampInMs = msgDict["timestamp"] as? Int {
				let timestamp = Date(timeIntervalSince1970: TimeInterval(Double(timestampInMs)/1000.0))
				self.init(messageId: messageId, message: message, creatorId: creatorId, creatorName: creatorName, imageUrl: imageUrl,timestamp: timestamp)
			} else {
				return nil
			}
		} catch {
			return nil
		}
	}
}

// Equatable protocol methods
internal func == (left: Message, right: Message) -> Bool {
	return (left.messageId == right.messageId)
}

// Comparable protocol methods
internal func < (left: Message, right: Message) -> Bool {
	return (left.timestamp.timeIntervalSince1970 < right.timestamp.timeIntervalSince1970)
}
