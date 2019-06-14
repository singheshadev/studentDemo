//
//  TripAppTests.swift
//  TripAppTests
//
//  Created by Mac_mojave-2k19(2) on 20/05/19.
//  Copyright © 2019 Mac_mojave-2k19(2). All rights reserved.
//

import XCTest
@testable import TripApp

class TripAppTests: XCTestCase {

    let view = StudentListViewController()
    var window: UIWindow!
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
//        var dict: [String: Any] = [:]
        
        window = UIWindow()
        
        let array = NSMutableArray()
        
        let data1 = ["startDate" : "25-4-19",
                     "endDate" : "26-4-19",
                     "name" : "trip 1"] as [String : Any]
        
        array.add(data1)
        
        let data2 = ["startDate" : "25-5-19",
                     "endDate" : "26-5-19",
                     "name" : "trip 2"] as [String : Any]
        array.add(data2)
        
        let data3 = ["startDate" : "25-6-19",
                     "endDate" : "26-6-19",
                     "name" : "trip 3"] as [String : Any]
        array.add(data3)
        
        view.UserDate(Data: array as! Array<Any>);
        
        self.loadView()
    }
    
    func loadView()
    {
        window.addSubview(view.view)
        RunLoop.current.run(until: Date())
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
