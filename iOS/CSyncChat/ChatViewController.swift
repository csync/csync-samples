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

class DetailCell: UITableViewCell
{
	@IBOutlet weak var authorImage: UIImageView!
	@IBOutlet weak var msgHeader: UILabel!
	@IBOutlet weak var msgText: UITextView!
}

class ChatViewController: UIViewController {

	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var messageEntry: UITextField!
	var roomViewModel : RoomViewModel!
	var shouldGoBack = false

	//Constants
	fileprivate let headerHeight = 0
	fileprivate let numberOfSections = 1
	fileprivate let nameAttrs = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)]
	fileprivate let hdrAttrs = [NSFontAttributeName: UIFont.systemFont(ofSize: 12)]

	lazy fileprivate var appDelegate : AppDelegate = {
		return UIApplication.shared.delegate as! AppDelegate
	}()

	var detailItem: Room?

	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.separatorStyle = UITableViewCellSeparatorStyle.none

		//setup the view model
		guard let room = detailItem else{
			print("Error: expected a room to be passed into the ChatViewController")
			return
		}
		//setup completion handler to be an unowned self to prevent memory leaks
		let messageCompletionHandler = {[unowned self] in
			self.updateView()
		}
		let roomCompletionHandler = {[unowned self] room, stillExists in
			if !stillExists {
				self.appDelegate.showSplitVC()
			}
			} as ((Room, Bool) -> ())
		//initialize the view model
		roomViewModel = RoomViewModel.init(forRoom: room, withMessageCompletionHandler: messageCompletionHandler, withRoomCompletionHandler: roomCompletionHandler)
	}

	override func viewWillAppear(_ animated: Bool) {
		//Start listening for data
		if shouldGoBack{
			appDelegate.showSplitVC()
			return;
		}
		roomViewModel.startListening()

		self.title = detailItem?.roomName ?? "Detail"
		if detailItem!.allowUpdate {
			let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(ChatViewController.editRoom(_:)))
			self.navigationItem.rightBarButtonItem = editButton
		}

		super.viewWillAppear(animated)
	}

	override func viewWillDisappear(_ animated: Bool) {
		roomViewModel.stopListening()
	}

	// MARK: - Private Functions

	//Refreshes the view with new data
	private func updateView(){
		self.tableView.reloadData()
	}

	// MARK: - Segues


	func editRoom(_ sender: AnyObject) {
		self.performSegue(withIdentifier: "editRoom", sender: self)
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "editRoom" {
			//The user may go back to this screen, so the Room View Model is not deallocated
			//Go ahead and stop listening, and start listening again when the view loads
			if let controller = segue.destination as? EditRoomViewController {
				controller.room = detailItem
				controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
				controller.navigationItem.leftItemsSupplementBackButton = true
			}
		}
	}
}
extension ChatViewController : UITextFieldDelegate{
	// MARK: - UITextFieldDelegate methods

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}

	func textFieldDidEndEditing(_ textField: UITextField) {
		if let messageText = textField.text , messageText.characters.count > 0,
			let message = Message(message: messageText) {
			//send message
			roomViewModel.send(message)
			self.tableView.scrollToNearestSelectedRow(at: .bottom, animated: false)
			textField.text = ""
		}
	}
}

extension ChatViewController : UITableViewDataSource, UITableViewDelegate {
	// MARK: - Table View

	func numberOfSections(in tableView: UITableView) -> Int {
		return numberOfSections
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return roomViewModel.numberOfMessages
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath) as! DetailCell

		let message = roomViewModel.message(atIndex: (indexPath as NSIndexPath).row)
		if let imageUrlStr = message.imageUrl,
			let imageUrl = URL(string: imageUrlStr),
			let imageData = try? Data(contentsOf: imageUrl),
			let image = UIImage(data: imageData) {
			cell.authorImage.image = image
		} else {
			cell.authorImage.image = UIImage(named: "picklesUser")
		}

		// Make author image a circle
		cell.authorImage.layer.cornerRadius = cell.authorImage.frame.size.width/2
		cell.authorImage.layer.masksToBounds = true
		cell.authorImage.layer.borderWidth = 2.0
		cell.authorImage.layer.borderColor = UIColor.clear.cgColor

		let msgHeader = NSMutableAttributedString.init(string: message.creatorName, attributes: nameAttrs)
		let hdrTime = NSMutableAttributedString.init(string: "  "+RoomViewModel.timestamp(forMessage: message), attributes: hdrAttrs)
		msgHeader.append(hdrTime)
		cell.msgHeader.attributedText = msgHeader
		cell.msgText.text = message.message
		cell.msgText.textContainer.lineBreakMode = .byWordWrapping
		return cell
	}

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return CGFloat(headerHeight)
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableViewAutomaticDimension
	}

	func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableViewAutomaticDimension
	}
}
