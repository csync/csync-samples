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

class SectionHeader: UITableViewHeaderFooterView
{
	@IBOutlet weak var title: UILabel!
	@IBOutlet weak var addButton: UIButton!
}

class RoomListViewController: UITableViewController {

	fileprivate var chatViewController: ChatViewController? = nil
	fileprivate var roomListViewModel : RoomListViewModel!

	//Constants
	fileprivate let sectionTitles = ["Private", "Public"]
	fileprivate let headerHeight = 36

	//MARK: - Overrides
	override func viewDidLoad() {
		super.viewDidLoad()

		//setup completion handler to be a weak reference so there are no memory leaks
		let roomListCompletionHandler = {[unowned self] in
			self.refreshTableView()
		}
		//Initialize the view model
		roomListViewModel = RoomListViewModel(withRoomListCompletionHandler: roomListCompletionHandler)

		// Do any additional setup after loading the view, typically from a nib.
		let nib = UINib(nibName: "SectionHeader", bundle: nil)
		tableView.register(nib, forHeaderFooterViewReuseIdentifier: "SectionHeader")
		// Set Nav Bar controller text to white
		navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
		navigationController?.navigationBar.tintColor = UIColor.white
		if let split = self.splitViewController {
			let controllers = split.viewControllers
			self.chatViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? ChatViewController
		}
	}


	override func viewWillAppear(_ animated: Bool) {
		roomListViewModel.startListening()
		refreshTableView()
		self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
		super.viewWillAppear(animated)
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		roomListViewModel.stopListening()
	}

	//MARK: - Private Functions
	private func refreshTableView(){
		self.tableView.reloadData()
	}

	// MARK: - Button Actions

	//Button clicked to add a new room
	func insertNewObject(_ sender: AnyObject) {
		let section = sender.tag
		let alert = UIAlertController(title: "New Room", message: "Enter Room Name", preferredStyle: UIAlertControllerStyle.alert)
		alert.addTextField(configurationHandler: {(textField: UITextField!) in
			textField.placeholder = "new " + (section == 0 ? "private" : "public") + " room"
		})
		alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) in
			if let roomName = alert.textFields![0].text {
				//Add room
				self.roomListViewModel.add(room: Room.init(roomName: roomName), ofType: RoomSection(rawValue: section!)!)
			}

		}))
		alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
		self.present(alert, animated: true, completion: nil)
	}

	// MARK: - Segues

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showDetail" {
			if let indexPath = self.tableView.indexPathForSelectedRow {
				let controller = (segue.destination as! UINavigationController).topViewController as! ChatViewController
				controller.detailItem = roomListViewModel.room(forIndex: indexPath.row, inSection: indexPath.section)
				controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
				controller.navigationItem.leftItemsSupplementBackButton = true
			}
		}
	}

	// MARK: - Table View

	override func numberOfSections(in tableView: UITableView) -> Int {
		return sectionTitles.count
	}

	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SectionHeader") as! SectionHeader
		header.title.text = sectionTitles[section]
		header.addButton.addTarget(self, action: #selector(insertNewObject(_:)), for: .touchUpInside)
		header.addButton.tag = section
		return header
	}

	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return CGFloat(headerHeight)
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return roomListViewModel.numberOfRows(in: section)
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
		cell.textLabel!.text = roomListViewModel.room(forIndex: indexPath.row, inSection: indexPath.section).roomName
		return cell
	}
	
}
