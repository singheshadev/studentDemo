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
    
    private var students = [Student]()
    private var selectedStudent: Int?
    
    var db: OpaquePointer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.delegate = self
        nameTextField.layer.borderWidth = 1
        nameTextField.layer.borderColor = UIColor.green.cgColor
        nameTextField.layer.cornerRadius = 3
        
        standardTextField.delegate = self
        standardTextField.layer.borderWidth = 1
        standardTextField.layer.borderColor = UIColor.green.cgColor
        standardTextField.layer.cornerRadius = 3
        
        schoolTextField.delegate = self
        schoolTextField.layer.borderWidth = 1
        schoolTextField.layer.borderColor = UIColor.green.cgColor
        schoolTextField.layer.cornerRadius = 3
        
        openDatabase()
        
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
        if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS Student (id INTEGER, name TEXT, standard INTEGER, school TEXT)", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error creating table: \(errmsg)")
        }else{
            print("successfully created table")
            
        }
        
    }
    
    //MARK:- Insert data into database
    
    let insertStatementString = "INSERT INTO Student (name, standard ,school) VALUES (?, ?,?);"
    
    func insert() {
        var insertStatement: OpaquePointer? = nil
        
        // 1
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            let name: NSString = nameTextField.text! as NSString
            let standard : Int32 = Int32(standardTextField!.text!)!
            let school: NSString = schoolTextField.text! as NSString
            
            // 2
            sqlite3_bind_int(insertStatement, 3, Int32(standard))
            // 3
            sqlite3_bind_text(insertStatement, 2, name.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 4, school.utf8String, -1, nil)
            
            // 4
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Successfully inserted row.")
            } else {
                print("Could not insert row.")
            }
        } else {
            print("INSERT statement could not be prepared.")
        }
        // 5
        sqlite3_finalize(insertStatement)
    }
    
    
    @IBAction func addStudentButton(_ sender: Any) {
        
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
                            self.navigationController?.popViewController(animated: true)
                        }
                }
                insert()
            }else{
                insert()
            }
        }
    }
    
}
