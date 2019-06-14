//
//  AddStudentViewController.swift
//  StudentDemo
//
//  Created by Mac_mojave-2k19(2) on 20/05/19.
//  Copyright © 2019 Mac_mojave-2k19(2). All rights reserved.

import UIKit
import FirebaseFirestore
import RxSwift
import SQLite3

class AddStudentViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var standardTextField: UITextField!
    @IBOutlet weak var schoolTextField: UITextField!
    @IBOutlet weak var mainBackView: UIView!
    @IBOutlet weak var addStudentButton: UIButton!
    
    private var students = [Student]()
    private var selectedStudent: Int?
    
    var isUpdate : Bool = false
    var updateName : String = ""
    var updateSchool : String = ""
    var updateStandard : String = ""
    var updateID : String = ""
    
    var db: OpaquePointer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.delegate = self
        nameTextField.layer.borderWidth = 1
        nameTextField.layer.borderColor = UIColor.green.cgColor
        nameTextField.layer.cornerRadius = 8
        
        standardTextField.delegate = self
        standardTextField.layer.borderWidth = 1
        standardTextField.layer.borderColor = UIColor.green.cgColor
        standardTextField.layer.cornerRadius = 8
        
        schoolTextField.delegate = self
        schoolTextField.layer.borderWidth = 1
        schoolTextField.layer.borderColor = UIColor.green.cgColor
        schoolTextField.layer.cornerRadius = 8
        
        addStudentButton.layer.cornerRadius = 8
        
        openDatabase()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if isUpdate{
            nameTextField.text = updateName
            schoolTextField.text = updateSchool
            standardTextField.text = updateStandard
            addStudentButton.setTitle("Update Student", for: .normal)
        }else{
            addStudentButton.setTitle("Add Student", for: .normal)
        }
    }
    
    // MARK:- OpenDatabase
    
    func openDatabase() {
        //the database file
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("Student.sqlite")
        
        //opening the database
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("error opening database")
        }else{
            print("successfully opened database")
        }
        
        //creating table
        if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS Student (id TEXT, name TEXT, standard INTEGER, school TEXT)", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error creating table: \(errmsg)")
        }else{
            print("successfully created table")
            
        }
        
    }
    
    //MARK:- Insert data
    
    let insertStatementString = "INSERT INTO Student (name, standard ,school) VALUES (?,?,?);"
    
    func insert() {
        var insertStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            let name: NSString = nameTextField.text! as NSString
            let standard : Int32 = Int32(standardTextField!.text!)!
            let school: NSString = schoolTextField.text! as NSString
            
            sqlite3_bind_int(insertStatement, 3, Int32(standard))
            sqlite3_bind_text(insertStatement, 2, name.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 4, school.utf8String, -1, nil)
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Successfully inserted row.")
            } else {
                print("Could not insert row.")
            }
        } else {
            print("INSERT statement could not be prepared.")
        }
        sqlite3_finalize(insertStatement)
    }
    
    //MARK:- Update data
    func update(id: String,name: String, standard: Int32, school: String) {
        var updateStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, "UPDATE Student SET name = '\(name)',school = '\(school)', standard = \(standard) WHERE id = '\(id)';", -1, &updateStatement, nil) == SQLITE_OK {
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("Successfully updated row.")
            } else {
                print("Could not update row.")
            }
        } else {
            print("UPDATE statement could not be prepared")
        }
        sqlite3_finalize(updateStatement)
    }
    
    //MARK:- Button Action
    
    @IBAction func addStudentButton(_ sender: Any) {
        if isUpdate == false {
            addStudentButton.setTitle("Add Student", for: .normal)
        if(nameTextField.text == ""){
            let alert = UIAlertController(title: "Alert", message: "Please enter name.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }else if(schoolTextField.text == ""){
            let alert = UIAlertController(title: "Alert", message: "Please enter school.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }else if(standardTextField.text == ""){
            let alert = UIAlertController(title: "Alert", message: "Please enter standard.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }else{
            
            if Reachability.isConnectedToNetwork() {
                
                let db = Firestore.firestore()
                db.collection("students").rx.base
                    .addDocument(data: [
                        "name": nameTextField.text!,
                        "school": schoolTextField.text!,
                        "standard": standardTextField.text!,
                    ]) { (err) in
                        if let err = err {
                            let alert = UIAlertController(title: "Alert", message: err.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        } else {
                            
                        }
                }
                insert()
                self.navigationController?.popViewController(animated: true)
            }else{
                insert()
                self.navigationController?.popViewController(animated: true)
            }
        }
    }else if isUpdate{
            addStudentButton.setTitle("Update Student", for: .normal)
        
            if(nameTextField.text == ""){
                let alert = UIAlertController(title: "Alert", message: "Please enter name.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }else if(schoolTextField.text == ""){
                let alert = UIAlertController(title: "Alert", message: "Please enter school.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }else if(standardTextField.text == ""){
                let alert = UIAlertController(title: "Alert", message: "Please enter standard.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }else{
            if Reachability.isConnectedToNetwork() {
                let db = Firestore.firestore()
                db.collection("students").rx.base
                    .whereField("name", isEqualTo: updateName)
                    .getDocuments() { (querySnapshot, err) in
                        if err != nil {
                            // Some error occured
                        } else if querySnapshot!.documents.count != 1 {
                            // Perhaps this is an error for you?
                        } else {
                            let document = querySnapshot!.documents.first
                            document?.reference.updateData([
                                "name": self.nameTextField.text!,
                                "school": self.schoolTextField.text!,
                                "standard": self.standardTextField.text!,
                                ])
                        }
                }
                
                
                //update in local
                update(id: updateID, name: nameTextField.text!, standard: Int32(standardTextField.text!)!, school: schoolTextField.text!)
                isUpdate = false
                self.navigationController?.popViewController(animated: true)
            }else{
                //update in local
                
                if(nameTextField.text == ""){
                    let alert = UIAlertController(title: "Alert", message: "Please enter name.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }else if(schoolTextField.text == ""){
                    let alert = UIAlertController(title: "Alert", message: "Please enter school.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }else if(standardTextField.text == ""){
                    let alert = UIAlertController(title: "Alert", message: "Please enter standard.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }else{
                update(id: updateID, name: nameTextField.text!, standard: Int32(standardTextField.text!)!, school: schoolTextField.text!)
                isUpdate = false
                self.navigationController?.popViewController(animated: true)
                }
            }
            }
    }
    }
    
}
