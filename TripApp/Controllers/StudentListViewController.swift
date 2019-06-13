//
//  TripListViewController.swift
//  Trip App
//
//  Created by mac_5 on 21/05/19.
//  Copyright © 2019 mac_5. All rights reserved.

import UIKit
import RxSwift
import RxCocoa
import Firebase
import SQLite3

class Trips: NSObject {
    var tripId : String = ""
    var name : String = ""
    var standard : String = ""
    var school : String = ""
}


class TripListViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    let trips: BehaviorRelay<[Trips]> =  BehaviorRelay(value: [])
    
    @IBOutlet weak var tableView: UITableView!
    
    private var arrTrips : NSMutableArray = []
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
        trips.bind(to: tableView.rx.items(cellIdentifier: "cell")) { row, model, cell in
            let cell = cell as! TripTableViewCell
            let standard = model.standard
            let school = model.school
            
            cell.nameLabel.text = "Name : \(model.name)"
            cell.dateLabel.text = "Standard : \(standard)"
            cell.schoolLabel.text = "School : \(school)"
            cell.selectionStyle = .none
            
            }.disposed(by: disposeBag)
        
        tableView.rx.modelSelected(Trips.self)
            .map{ URL(string: $0.name) }
            .subscribe(onNext: { [weak self] url in
                guard url != nil else {
                    return
                }
            }).disposed(by: disposeBag)
        
        tableView.rx.itemDeleted
            .subscribe(onNext: { print($0.last ?? 0)
                if Reachability.isConnectedToNetwork(){
                    let obj = self.arrTrips[$0.last ?? 0] as! Trips
                    let db = Firestore.firestore()
                    db.collection("students").rx.base
                        .document(obj.tripId).delete() { err in
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
                    //delete row and reload table
                }
            })
            
            .disposed(by: disposeBag)
    }
    
    //MARK:- Viewwillappear
    
    override func viewWillAppear(_ animated: Bool) {
        openDatabase()
        fetchingData()
    }
    
    // MARK: - API Calling -
    func fetchingData() {
//        if Reachability.isConnectedToNetwork() {
//            let db = Firestore.firestore()
//            db.collection("students")
//                .addSnapshotListener { documentSnapshot, error in
//                    guard documentSnapshot != nil else {
//                        print("Error fetching document: \(error!)")
//                        return
//                    }
//                    self.loadingData()
//            }
//        }else{
            let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent("Student.sqlite")
            if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
                print("error opening database")
            }else{
                print("successfully opened database")
                
                dataFetch()
                
            }
//        }
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
    
    
    //MARK:- Select Query to get local data
    let selectStatementString = "SELECT * FROM Student;"
    
    func dataFetch() {
        
        var selectStatement: OpaquePointer? = nil
        
        if sqlite3_prepare(db, selectStatementString, -1, &selectStatement, nil) == SQLITE_OK{
            self.arrTrips.removeAllObjects()
            
            while(sqlite3_step(selectStatement) == SQLITE_ROW){
                let id = sqlite3_column_int(selectStatement, 1)
                
                var name = "temp"
                if (sqlite3_column_text(selectStatement, 2) != nil){
                    name = String(cString: sqlite3_column_text(selectStatement, 2))
                }else{
                    name = "temp"
                }
                
//                let name = ( ? String(cString: sqlite3_column_text(selectStatement, 1)) : "temp")
                let standard = sqlite3_column_int(selectStatement, 3)
                var school = "school"
                if sqlite3_column_text(selectStatement, 4) != nil {
                 school = String(cString: sqlite3_column_text(selectStatement, 4))
                }else{
                    school = "school"
                }
                print("Query Result:")
                print("\(id) | \(name) | \(school) | \(standard)")
                let obj = Trips()
                obj.tripId = "\(id)"
                obj.name = name
                obj.standard = "\(standard)"
                obj.school = school
                
                self.arrTrips.add(obj)
            }
            
            self.trips.accept(self.arrTrips as! [Trips])
            self.tableView.reloadData()
            
            sqlite3_finalize(selectStatement)
            
        }else{
            
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing select: \(errmsg)")
            return
            
        }
        
    }
    
    //MARK:- Insert data into local database
    
    let insertStatementString = "INSERT INTO Student (name, standard ,school) VALUES (?,?,?);"
    
    func insert(name: String, school: String, standard: String) {
        var insertStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            let name: NSString = name as NSString
            let standard : Int32 = Int32(standard)!
            let school: NSString = school as NSString
            
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
    //MARK:- Load Data
    
    func loadingData() {
        let db = Firestore.firestore()
        db.collection("students").rx.base
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    self.arrTrips = []
                    for document in querySnapshot!.documents {
                        print("\(document.documentID) => \(document.data())")
                        
                        let dict = document.data() as NSDictionary
                        
                        let obj = Trips()
                        obj.tripId =  document.documentID
                        obj.name = dict["name"] as! String
                        obj.standard = "\(dict["standard"] ?? 1)"
                        obj.school = dict["school"] as! String
                        print("obj \(obj)")
                        self.insert(name: obj.name, school: obj.school, standard: obj.standard)
                        self.arrTrips.add(obj)
                    }
                    self.trips.accept(self.arrTrips as! [Trips])
                    self.tableView.reloadData()
                }
        }
        
    }
    
    //MARK:- Button Action
    
    @IBAction func addTrips(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "AddStudentViewController") as! AddStudentViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

