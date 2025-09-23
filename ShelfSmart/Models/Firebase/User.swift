//
//  User.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/5/25.
//

import Foundation

struct User : Codable{
    var name : String
    var email : String
    var joinDate : Date = Date.now
    var signupMethod : String
}
