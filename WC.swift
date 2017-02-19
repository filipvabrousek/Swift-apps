import Foundation

struct User {
  
  let uid: String
  let email: String
  
  init(authData: FIRUser) {
    uid = authData.uid
    email = authData.email!
  }
  
  init(uid: String, email: String) {
    self.uid = uid
    self.email = email
  }
  
}



import Foundation

struct GroceryItem {
  
  let key: String
  let name: String
  let addedByUser: String
  let ref: FIRDatabaseReference?
  var completed: Bool
  
  init(name: String, addedByUser: String, completed: Bool, key: String = "") {
    self.key = key
    self.name = name
    self.addedByUser = addedByUser
    self.completed = completed
    self.ref = nil
  }
  
  init(snapshot: FIRDataSnapshot) {
    key = snapshot.key
    let snapshotValue = snapshot.value as! [String: AnyObject]
    name = snapshotValue["name"] as! String
    addedByUser = snapshotValue["addedByUser"] as! String
    completed = snapshotValue["completed"] as! Bool
    ref = snapshot.ref
  }
  
  func toAnyObject() -> Any {
    return [
      "name": name,
      "addedByUser": addedByUser,
      "completed": completed
    ]
  }
  
}







import UIKit

class LoginViewController: UIViewController {

  let loginToList = "LoginToList"
  @IBOutlet weak var textFieldLoginEmail: UITextField!
  @IBOutlet weak var textFieldLoginPassword: UITextField!
  
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    FIRAuth.auth()!.addStateDidChangeListener() { auth, user in
      if user != nil {
        self.performSegue(withIdentifier: self.loginToList, sender: nil)
      }
    }
  }
  
  /*--------------------------------------------LOGIN---------correct-------------------------------------*/
  @IBAction func loginDidTouch(_ sender: AnyObject) {
    FIRAuth.auth()!.signIn(withEmail: textFieldLoginEmail.text!,
                           password: textFieldLoginPassword.text!)
  }

  
  /*---------------------------------------------SIGN UP--------------------------------------*/
  @IBAction func signUpDidTouch(_ sender: AnyObject) {
    let alert = UIAlertController(title: "Register", message: "Register", preferredStyle: .alert)
    
    let saveAction = UIAlertAction(title: "Save", style: .default) { action in
        let emailField = alert.textFields![0] 
        let passwordField = alert.textFields![1] 
      
        FIRAuth.auth()!.createUser(withEmail: emailField.text!, password: passwordField.text!) { user, error in
          if error == nil {
            FIRAuth.auth()!.signIn(withEmail: self.textFieldLoginEmail.text!, password: self.textFieldLoginPassword.text!)
          }
        }
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .default)
    
    alert.addTextField { textEmail in
      textEmail.placeholder = "Enter your email"
    }
    
    alert.addTextField { textPassword in
      textPassword.isSecureTextEntry = true
      textPassword.placeholder = "Enter your password"
    }
    
    alert.addAction(saveAction)
    alert.addAction(cancelAction)
    
    present(alert, animated: true, completion: nil)
  }

}



/*-------------------------------TEXTFIELD DELEGATE EXTENSION---------------------------*/
extension LoginViewController: UITextFieldDelegate {
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == textFieldLoginEmail {
      textFieldLoginPassword.becomeFirstResponder()
    }
    if textField == textFieldLoginPassword {
      textField.resignFirstResponder()
    }
    return true
  }
  
}
















import UIKit

class GroceryListTableViewController: UITableViewController {

  let listToUsers = "ListToUsers"
  var items: [GroceryItem] = []
  let ref = FIRDatabase.database().reference(withPath: "grocery-items")
  let usersRef = FIRDatabase.database().reference(withPath: "online")
  var user: User!
  var userCountBarButtonItem: UIBarButtonItem!
  

  /*-------------------------------VIEW DID LOAD---------------------------
   1 - order database items by "completed"
   2 - append databse items to newItems
   3 - append items to newItems
   */
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.allowsMultipleSelectionDuringEditing = false
    
    userCountBarButtonItem = UIBarButtonItem(title: "1",
                                             style: .plain,
                                             target: self,
                                             action: #selector(userCountButtonDidTouch))
    userCountBarButtonItem.tintColor = UIColor.white
    navigationItem.leftBarButtonItem = userCountBarButtonItem
    
    usersRef.observe(.value, with: { snapshot in
      if snapshot.exists() {
        self.userCountBarButtonItem?.title = snapshot.childrenCount.description
      } else {
        self.userCountBarButtonItem?.title = "0"
      }
    })
    
    //1
    ref.queryOrdered(byChild: "completed").observe(.value, with: { snapshot in
      var newItems: [GroceryItem] = []
      
      //2
      for item in snapshot.children {
        let groceryItem = GroceryItem(snapshot: item as! FIRDataSnapshot)
        newItems.append(groceryItem)
      }
      
      //3
      self.items = newItems
      self.tableView.reloadData()
    })
    
    FIRAuth.auth()!.addStateDidChangeListener { auth, user in
      guard let user = user else { return }
      self.user = User(authData: user)
      let currentUserRef = self.usersRef.child(self.user.uid)
      currentUserRef.setValue(self.user.email)
      currentUserRef.onDisconnectRemoveValue()
    }
  }
  
  
  /*-------------------------------TABLEVIEW METHODS--------------------------*/
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
    let groceryItem = items[indexPath.row]
    
    cell.textLabel?.text = groceryItem.name
    cell.detailTextLabel?.text = groceryItem.addedByUser
    
    toggleCellCheckbox(cell, isCompleted: groceryItem.completed)
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let groceryItem = items[indexPath.row]
      groceryItem.ref?.removeValue()
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let cell = tableView.cellForRow(at: indexPath) else { return }
    let groceryItem = items[indexPath.row]
    let toggledCompletion = !groceryItem.completed
    toggleCellCheckbox(cell, isCompleted: toggledCompletion)
    groceryItem.ref?.updateChildValues([
      "completed": toggledCompletion
    ])
  }
  
  
  
  /*-------------------------------TOOGLE CELL CHECKBOX (check / uncheck an item)--------------------------*/
  func toggleCellCheckbox(_ cell: UITableViewCell, isCompleted: Bool) {
    if !isCompleted {
      cell.accessoryType = .none
      cell.textLabel?.textColor = UIColor.black
      cell.detailTextLabel?.textColor = UIColor.black
    } else {
      cell.accessoryType = .checkmark
      cell.textLabel?.textColor = UIColor.gray
      cell.detailTextLabel?.textColor = UIColor.gray
    }
  }
  
  /*-------------------------------------------------ADD ITEM------------------------------------------------*/
  @IBAction func addButtonDidTouch(_ sender: AnyObject) {
    let alert = UIAlertController(title: "Grocery Item",
                                  message: "Add an Item",
                                  preferredStyle: .alert)
    
    let saveAction = UIAlertAction(title: "Save",
                                   style: .default) { _ in
                                    // 1
                                    guard let textField = alert.textFields?.first,
                                      let text = textField.text else { return }

                                    // 2
                                    let groceryItem = GroceryItem(name: text,
                                                                  addedByUser: self.user.email,
                                                                  completed: false)
                                    // 3
                                    let groceryItemRef = self.ref.child(text.lowercased())

                                    // 4
                                    groceryItemRef.setValue(groceryItem.toAnyObject())
    }
    
    let cancelAction = UIAlertAction(title: "Cancel",
                                     style: .default)
    
    alert.addTextField()
    
    alert.addAction(saveAction)
    alert.addAction(cancelAction)
    
    present(alert, animated: true, completion: nil)
  }
  
  func userCountButtonDidTouch() {
    performSegue(withIdentifier: listToUsers, sender: nil)
  }
  
}














import UIKit

class OnlineUsersTableViewController: UITableViewController {

  let userCell = "UserCell"
  let usersRef = FIRDatabase.database().reference(withPath: "online")
  var currentUsers: [String] = []
  

  override func viewDidLoad() {
    super.viewDidLoad()
    
    /*-------------------------------USERS REF OBSERVE---------------1----------*/
    usersRef.observe(.childAdded, with: { snap in
      guard let email = snap.value as? String else { return }
      self.currentUsers.append(email)
      let row = self.currentUsers.count - 1
      let indexPath = IndexPath(row: row, section: 0)
      self.tableView.insertRows(at: [indexPath], with: .top)
    })
    
    
    /*-------------------------------USERS REF OBSERVE---------------2----------*/
    usersRef.observe(.childRemoved, with: { snap in
      guard let emailToFind = snap.value as? String else { return }
      for (index, email) in self.currentUsers.enumerated() {
        if email == emailToFind {
          let indexPath = IndexPath(row: index, section: 0)
          self.currentUsers.remove(at: index)
          self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
      }
    })
    
  }
  
  /*-------------------------------TABLEVIEW METHODS--------------------------*/
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return currentUsers.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: userCell, for: indexPath)
    let onlineUserEmail = currentUsers[indexPath.row]
    cell.textLabel?.text = onlineUserEmail
    return cell
  }
  
  /*-----------------------------------SIGN OUT--------------------------------*/
  @IBAction func signoutButtonPressed(_ sender: AnyObject) {
    do {
      try FIRAuth.auth()!.signOut()
      dismiss(animated: true, completion: nil)
    } catch {
      
    }
  }
  
}


