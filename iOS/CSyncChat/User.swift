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

class User {
	let userId : String
	let googleId : String?
	let name : String
	let email : String
	let smallImageUrl : URL?
	let largeImageUrl : URL?

	required init(userId: String, googleId: String?, name: String, email: String, smallImageUrl: URL?, largeImageUrl: URL?) {
		self.userId = userId
		self.googleId = googleId
		self.name = name
		self.email = email
		self.smallImageUrl = smallImageUrl
		self.largeImageUrl = largeImageUrl
	}

	fileprivate(set) static var currentUser : User? = nil

	class func setCurrentUser(_ userId: String, googleId: String?, name: String, email: String, smallImageUrl: URL?, largeImageUrl: URL?)
	{
		currentUser = self.init(userId: userId, googleId: googleId, name: name, email: email, smallImageUrl: smallImageUrl, largeImageUrl: largeImageUrl)
	}

	/* Set the currentUser using the Google Sign-In SDK for iOS
	class func setCurrentUser(_ authData: AuthData, user: GIDGoogleUser)
	{
	setCurrentUser(authData.uid, googleId: user.userID, name: user.profile.name, email: user.profile.email, smallImageUrl: user.profile.imageURL(withDimension: 30), largeImageUrl: user.profile.imageURL(withDimension: 240))
	}
	*/

	class func clearCurrentUser()
	{
		currentUser = nil
	}

	lazy var smallImage : Data? = {
		if let url = self.smallImageUrl {
			return (try? Data(contentsOf: url))
		} else {
			return nil
		}
	}()

	lazy var largeImage : Data? = {
		if let url = self.largeImageUrl {
			return (try? Data(contentsOf: url))
		} else {
			return nil
		}
	}()
}
