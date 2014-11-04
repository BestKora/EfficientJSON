//
//  User.swift
//  EfficientJSON
//
//  Created by Tatiana Kornilova on 10/13/14.
//  Copyright (c) 2014 Tatiana Kornilova. All rights reserved.
//

import Foundation

//----------------- МОДЕЛЬ User --------

struct User:  JSONDecodable, Printable {
    let id: Int
    let name: String
    let email: String?
    
    var description : String {
        return "User { id = \(id), name = \(name), email = \(email)}"
    }

    static func create(id: Int)(name: String)(email: String?) -> User {
        return User(id: id, name: name, email: email)
    }
  
    static func decode(json: JSON) -> User? {
        return _JSONParse(json) >>> { d in
            User.create
                <^> d <| "id"
                <*> d <| "name"
                <*> d <|* "email"
          
        }
    }
/* ---- Старый вариант -----
    static func decode(json: JSON) -> User? {
        return _JSONParse(json) >>> { d in
            User.create
                <^> extract (d,"id")
                <*> extract (d,"name")
                <*> extractPure (d,"email")
        }
    }
*/
    static func decode(json: JSON) -> Result<User> {  
        
        let user = _JSONParse(json) >>> { d in
            User.create
                <^> d <| "id"
                <*> d <| "name"
                <*> d <|* "email"
                /*
                <^> dict["id"]    >>> JSONInt
                <*> dict["name"]  >>> JSONString
                <*> pure(dict["email"] >>> JSONString)
*/
        }
        return resultFromOptional(user, NSError(localizedDescription: "Отсутствуют компоненты User")) // custom error message
    }

}

//-------------------------ФУНКЦИИ ПАРСИНГА------

func getUser4(jsonOptional: NSData?, callback: (Result<User>) -> ()) {
    let result: ()? = decodeJSON(jsonOptional) >>> User.decode >>> callback
    
}

func getUser6(jsonOptional: NSData?, callback: (Result<User>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional, NSError(localizedDescription: "JSON данные неверны"))
    let user: ()? = jsonResult >>> decodeJSON >>> decodeObject >>> callback
}

