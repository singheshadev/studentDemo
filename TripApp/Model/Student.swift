//
//  Student.swift
//  TripApp
//
//  Created by mac_5 on 12/06/19.
//  Copyright © 2019 Mac_mojave-2k19(2). All rights reserved.
//

import Foundation

class Student {
    let id: Int64?
    var name: String
    var school: String
    var standard: String
    
    init(id: Int64) {
        self.id = id
        name = ""
        school = ""
        standard = ""
    }
    
    init(id: Int64, name: String, school: String, standard: String) {
        self.id = id
        self.name = name
        self.school = school
        self.standard = standard
    }
}
