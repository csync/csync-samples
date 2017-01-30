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

import UIKit
import CSyncSDK

class EditRoomViewController: UIViewController {

	@IBOutlet weak var roomNameField: UITextField!
	@IBOutlet weak var privateSwitch: UISwitch!
	fileprivate var roomViewModel : RoomViewModel!

	var room: Room?

	override func viewDidLoad() {
		super.viewDidLoad()
		self.title = "Room Detail"
		let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveRoom(_:)))
		self.navigationItem.rightBarButtonItem = saveButton
		guard let room = room else {
			return
		}
		let roomCompletionHandler = {[unowned self] room, stillExists in
			if stillExists {
				self.updateView(withRoom: room)
			}
			else {
				let controller = self.navigationController?.viewControllers[0] as! ChatViewController
				controller.shouldGoBack = true
				_ = self.navigationController?.popToRootViewController(animated: true)

			}
			} as ((Room, Bool) -> ())
		//Initalize the View Model
		roomViewModel = RoomViewModel.init(forRoom: room, withMessageCompletionHandler: nil, withRoomCompletionHandler: roomCompletionHandler)
		roomViewModel.startListening()

		//update the view's data
		self.updateView(withRoom: roomViewModel.room)
	}

	override func viewWillDisappear(_ animated: Bool) {
		roomViewModel.stopListening()
		super.viewWillDisappear(animated)
	}

	func saveRoom(_ sender: AnyObject) {
		if roomViewModel.room.isPrivate != privateSwitch.isOn{
			roomViewModel.setRoomType(toPrivate: privateSwitch.isOn)
		}
		guard let newName = roomNameField.text else {
			_ = self.navigationController?.popViewController(animated: true)
			return
		}
		if newName != roomViewModel.room.roomName{
			roomViewModel.setRoomName(toString: newName)
		}
		_ = self.navigationController?.popViewController(animated: true)
	}


	@IBAction func deleteRoomPressed(_ sender: AnyObject) {
		roomViewModel.deleteRoom()
		let controller = self.navigationController?.viewControllers[0] as! ChatViewController
		controller.shouldGoBack = true
		_ = self.navigationController?.popToRootViewController(animated: true)
	}


	private func updateView(withRoom room: Room){
		roomNameField.text = room.roomName
		privateSwitch.isOn = room.isPrivate
	}
}

// MARK: - UITextFieldDelegate methods
extension EditRoomViewController : UITextFieldDelegate{
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}
