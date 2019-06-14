//
//  Student.swift
//  Student Demo
//
//  Created by mac_5 on 12/06/19.
//  Copyright © 2019 Mac_mojave-2k19(2). All rights reserved.
//

import Foundation

class Student {
    let id: String
    var name: String
    var school: String
    var standard: String
    
    init(id: String) {
        self.id = id
        name = ""
        school = ""
        standard = ""
    }
    
    init(id: String, name: String, school: String, standard: String) {
        self.id = id
        self.name = name
        self.school = school
        self.standard = standard
    }
}
