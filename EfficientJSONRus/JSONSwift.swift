//
//  JSONSwift.swift
//  EfficientJSON
//
//  Created by Tatiana Kornilova on 8/7/14.
//  Copyright (c) 2014 Tatiana Kornilova. All rights reserved.
//

import Foundation

typealias JSON = AnyObject
typealias JSONDictionary = Dictionary<String, JSON>
typealias JSONArray = Array<JSON>


//------- JSON functions -----
/*
func dictionary(input: JSONDictionary, key: String) ->  JSONDictionary? {
    return input[key] >>> { $0 as? JSONDictionary }
}

func array(input: JSONDictionary, key: String) ->  JSONArray? {
    return input[key] >>> { $0 as?  JSONArray}                     
}

func JSONString(object: JSON) -> String? {
    return object as? String
}

func JSONInt(object: JSON) -> Int? {
    return object as? Int
}

func JSONBool(object: JSON) -> Bool? {
    return object as? Bool
}
func JSONObject(object: JSON) -> JSONDictionary? {
    return object as? JSONDictionary
}

func JSONCollection(object: JSON) -> JSONArray? {
    return object as? JSONArray
}
*/
//------------Functions------------------

public func flatten<A>(array: [A?]) -> [A] {
    var list: [A] = []
    for item in array {
        if let i = item {
            list.append(i)
        }
    }
    return list
}

public func pure<A>(a: A) -> A? {
    return .Some(a)
}
//---------------------------- Универсальный парсер --------

func _JSONParse<A>(json: JSON) -> A? {
    return json as? A
}

func _JSONParse<A: JSONDecodable>(json: JSON) -> A? {
    return A.decode(json)
}

extension String: JSONDecodable {
    static func decode(json: JSON) -> String? {
        return json as? String
    }
}

extension Int: JSONDecodable {
    static func decode(json: JSON) -> Int? {
        return json as? Int
    }
}

extension Double: JSONDecodable {
    static func decode(json: JSON) -> Double? {
        return json as? Double
    }
}

extension Bool: JSONDecodable {
    static func decode(json: JSON) -> Bool? {
        return json as? Bool
    }
}

// ----------------operators Optional ----

infix operator >>> { associativity left precedence 150 }
infix operator <^> { associativity left } // Functor's fmap (usually <$>)
infix operator <*> { associativity left } // Applicative's apply

public func >>><A, B>(a: A?, f: A -> B?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .None
    }
}

public func <^><A, B>(f: A -> B, a: A?) -> B? {
    if let x = a {
        return (f(x))
    } else {
        return .None
    }
}

public func <*><A, B>(f: (A -> B)?, a: A?) -> B? {
    if let x = a {
        if let fx = f {
            return fx(x)
        }
    }
    return .None
}

// Для упрощения работы с классом NSError создаем "удобный" инициализатор в расширении класса

extension NSError {
    convenience init(localizedDescription: String) {
        self.init(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
    }
}

//------------------ Преобразование Optionals в Result -----

func resultFromOptional<A>(optional: A?, error: NSError) -> Result<A> {
    if let a = optional {
        return .Value(Box(a))
    } else {
        return .Error(error)
    }
}
//------------------ Протокол  JSONDecodable -----

protocol JSONDecodable {
    class func decode(json: JSON) -> Self?
}

func decodeObject<A: JSONDecodable>(json: JSON) -> Result<A> {
    return resultFromOptional(A.decode(json),
                       NSError(localizedDescription: "Отсутствуют компоненты Модели"))
}

//------------- JSON -> A? -------------

func decodeObject<A: JSONDecodable>(json: JSON) -> A? {
    return A.decode(json)
}

//------------------ Для Optionals JSON? -----

func decodeJSON(data: NSData?) -> JSON? {
    var jsonErrorOptional: NSError?
    let jsonOptional: JSON? = NSJSONSerialization.JSONObjectWithData(data!,
                                          options: NSJSONReadingOptions(0),
                                                 error: &jsonErrorOptional)
    if let json: JSON = jsonOptional {
        return json
    } else {
        return .None
    }
}

//------------------ Для Result<JSON> -----

func decodeJSON(data: NSData) -> Result<JSON> {
    var jsonErrorOptional: NSError?
    let jsonOptional: JSON! = NSJSONSerialization.JSONObjectWithData(data,
        options: NSJSONReadingOptions(0),
        error: &jsonErrorOptional)
    if let err = jsonErrorOptional {
        return resultFromOptional(jsonOptional,
            NSError (localizedDescription: err.localizedDescription ))
    } else {
        
        return resultFromOptional(jsonOptional, NSError ())
    }
}

// ----------------operators Result<A> ----

func >>><A, B>(a: Result<A>, f: A -> Result<B>) -> Result<B> {
    switch a {
    case let .Value(x):     return f(x.value)
    case let .Error(error): return .Error(error)
    }
}
//------------------------------------------
//---------------------Новые операторы --------
//  Для извлечения словаря
/*
infix operator  |> { associativity left precedence 150 }
func |>(input: [String:AnyObject]?, key: String) ->  [String:AnyObject]? {
    return input![key] >>> { $0 as? [String:AnyObject] }
}

//  Для извлечения массива

infix operator  ||> { associativity left precedence 150 }
func ||>(input: [String:AnyObject]?, key: String) ->  [AnyObject]? {
    return input![key] >>> { $0 as? [AnyObject] }
}
*/
//-------- Операторы извлечения данных из JSON-------

infix operator <|* { associativity left precedence 150 }
infix operator <| { associativity left precedence 150 }

func <|<A: JSONDecodable>(d: JSONDictionary, key: String) -> A? {
    return d[key] >>> _JSONParse
}

func <|(d: JSONDictionary, key: String) -> JSONDictionary {
    return d[key] >>> _JSONParse ?? JSONDictionary()
}

func <|<A: JSONDecodable>(d: JSONDictionary, key: String) -> [A]? {
    return d[key] >>> _JSONParse >>> { (array: JSONArray) in
        array.map { _JSONParse($0) } >>> flatten
    }
}

func <|*<A: JSONDecodable>(d: JSONDictionary, key: String) -> A?? {
    return pure(d <| key)
}







