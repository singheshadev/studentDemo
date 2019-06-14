//
//  StudentListViewController.swift
//  Student Demo
//
//  Created by mac_5 on 21/05/19.
//  Copyright © 2019 mac_5. All rights reserved.

import UIKit
import RxSwift
import RxCocoa
import Firebase
import SQLite3

class Students: NSObject {
    var studentId : String = ""
    var name : String = ""
    var standard : String = ""
    var school : String = ""
}

class StudentListViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    let students: BehaviorRelay<[Students]> =  BehaviorRelay(value: [])
    
    @IBOutlet weak var tableView: UITableView!
    
    private var arrStudents : NSMutableArray = []
    var db: OpaquePointer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        //MARK:- Firestore connectivity
        if Reachability.isConnectedToNetwork() {
            let db = Firestore.firestore()
            db.collection("students")
                .addSnapshotListener { documentSnapshot, error in
                    guard documentSnapshot != nil else {
                        let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "ok", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                    self.loadingData()
            }
        }else{
            dataFetch()
        }
        
        // MARK: TableView Method
        students.bind(to: tableView.rx.items(cellIdentifier: "cell")) { row, model, cell in
            let cell = cell as! StudentTableViewCell
            let standard = model.standard
            let school = model.school
            print("model \(model.name)",model.school,model.standard,model.studentId)
            cell.nameLabel.text = "Name : \(model.name)"
            cell.standardLabel.text = "Standard : \(standard)"
            cell.schoolLabel.text = "School : \(school)"
            cell.selectionStyle = .none
            
            }.disposed(by: disposeBag)
        
        tableView.rx.modelSelected(Students.self)
            .subscribe(onNext: { [weak self] obj in
                print(obj.name, obj.standard,obj.school,obj.studentId)
                let vc = self?.storyboard?.instantiateViewController(withIdentifier: "AddStudentViewController") as! AddStudentViewController
                vc.isUpdate = true
                vc.updateName = obj.name
                vc.updateSchool = obj.school
                vc.updateStandard = obj.standard
                vc.updateID = obj.studentId
                self?.navigationController?.pushViewController(vc, animated: true)
            }).disposed(by: disposeBag)
        
        tableView.rx.itemDeleted
            .subscribe(onNext: { print($0.last ?? 0)
                if Reachability.isConnectedToNetwork(){
                    let obj = self.arrStudents[$0.last ?? 0] as! Students
                    let db = Firestore.firestore()
                    db.collection("students").rx.base
                        .document(obj.studentId).delete() { err in
                            if let err = err {
                                let alert = UIAlertController(title: "Error", message: err.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                                alert.addAction(UIAlertAction(title: "ok", style: UIAlertAction.Style.default, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            } else {
                                print("Document successfully removed!")
                            }
                    }
                    self.loadingData()
                }else{
                    let obj = self.arrStudents[$0.last ?? 0] as! Students
                    self.delete(id: obj.studentId)
                }
            })
            
            .disposed(by: disposeBag)
        
       

    }
    
    //MARK:- Viewwillappear
    
    override func viewWillAppear(_ animated: Bool) {
        openDatabase()
        fetchingData()
    }
    
    // MARK: - Fetching data -
    func fetchingData() {
        if Reachability.isConnectedToNetwork() {
            let db = Firestore.firestore()
            db.collection("students")
                .addSnapshotListener { documentSnapshot, error in
                    guard documentSnapshot != nil else {
                        print("Error fetching document: \(error!)")
                        return
                    }
                    self.loadingData()
            }
        }else{
            let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent("Student.sqlite")
            if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
                print("error opening database")
            }else{
                print("successfully opened database")
                
                dataFetch()
                
            }
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
    
    
    //MARK:- Select Query to get local data
    let selectStatementString = "SELECT * FROM Student;"
    
    func dataFetch() {
        
        var selectStatement: OpaquePointer? = nil
        
        if sqlite3_prepare(db, selectStatementString, -1, &selectStatement, nil) == SQLITE_OK{
            self.arrStudents = []
            
            while(sqlite3_step(selectStatement) == SQLITE_ROW){
                let name2 = String(cString: sqlite3_column_text(selectStatement, 1))
                let school = String(cString: sqlite3_column_text(selectStatement, 3))
                let id = String(cString: sqlite3_column_text(selectStatement,0))
                let standard = String(cString: sqlite3_column_text(selectStatement, 2))
    
                let obj = Students()
                obj.studentId = "\(id)"
                obj.name = name2
                obj.standard = "\(standard)"
                obj.school = school
                
                self.arrStudents.add(obj)
            }
            
            self.students.accept(self.arrStudents as! [Students])
            self.tableView.reloadData()
            
            sqlite3_finalize(selectStatement)
            
        }else{
            
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing select: \(errmsg)")
            return
            
        }
        
    }
    
    //MARK:- Insert data into local database
    
    let insertStatementString = "INSERT INTO Student (id, name, standard ,school) VALUES (?,?,?,?);"
    
    func insert(id: String, name: String, school: String, standard: String) {
        var insertStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            let name: NSString = name as NSString
            let standard : Int32 = Int32(standard)!
            let school: NSString = school as NSString
            let newId : NSString = id as NSString
            
            sqlite3_bind_int(insertStatement, 3, Int32(standard))
            sqlite3_bind_text(insertStatement, 2, name.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 4, school.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 1, newId.utf8String, -1, nil)
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("id: \(newId), name : \(name) , School: \(school), standard: \(standard)")
                print("Successfully inserted row.")
            } else {
                print("Could not insert row.")
            }
        } else {
            print("INSERT statement could not be prepared.")
        }
        
        sqlite3_finalize(insertStatement)
    }
    //MARK:- Delete One Record from local databse
    
    func delete(id: String) {
        var deleteStatement: OpaquePointer? = nil
        print("DELETE FROM Student WHERE Id = \(id);")
        if sqlite3_prepare_v2(db, "DELETE FROM Student WHERE id = '\(id)';", -1, &deleteStatement, nil) == SQLITE_OK {
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("Successfully deleted row.")
                dataFetch()
                tableView.reloadData()
            } else {
                print("Could not delete row.")
            }
        } else {
            print("DELETE statement could not be prepared")
        }
        
        sqlite3_finalize(deleteStatement)
    }
    
    //MARK:- Delete ALLData from local database
    
    let deleteStatementStirng = "DELETE FROM Student;"
    
    func deleteAll() {
        var deleteStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("Successfully deleted Data.")
            } else {
                print("Could not delete Data.")
            }
        } else {
            print("DELETE statement could not be prepared")
        }
        
        sqlite3_finalize(deleteStatement)
    }
    
    
    //MARK:- Load Data
    
    func loadingData() {
        let db = Firestore.firestore()
        db.collection("students").rx.base
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    self.arrStudents = []
                    self.deleteAll()
                    for document in querySnapshot!.documents {
                        print("\(document.documentID) => \(document.data())")
                        
                        let dict = document.data() as NSDictionary
                        
                        let obj = Students()
                        obj.studentId =  document.documentID
                        obj.name = dict["name"] as! String
                        obj.standard = "\(dict["standard"] ?? 1)"
                        obj.school = dict["school"] as! String
                        print("obj \(obj)")
                        self.insert(id: obj.studentId ,name: obj.name, school: obj.school, standard: obj.standard)
                        self.arrStudents.add(obj)
                    }
                    self.students.accept(self.arrStudents as! [Students])
                    self.tableView.reloadData()
                }
        }
        
    }
    
    //MARK:- Button Action
    
    @IBAction func addStudents(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "AddStudentViewController") as! AddStudentViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

