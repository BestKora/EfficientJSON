// Playground - noun: a place where people can play

import Foundation

//---- по статье http://robots.thoughtbot.com/efficient-json-in-swift-with-functional-concepts-and-generics

/*let parsedJSON : [String:AnyObject] = [
    "id": 1,
    "name": "Cool User",
    "email": "u.cool@example.com"
]
*/

// ~~~~~~~~~~~~~~ Модель User ~~~~~~~~~~~~~~~~~
struct User: Printable {
    let id: Int = 0
    let name: String = ""
    let email: String = ""
    
    var description : String {
        return "User { id = \(id), name = \(name), email = \(email)}"
    }
    
    static func create(id: Int)(name: String)(email: String) -> User {
        return User(id: id, name: name, email: email)
    }
}

//------- Исходные данные для парсинга User -----

//      ----- Тест 1 - правильные данные -----

let jsonString: String = "{ \"id\": 1, \"name\":\"Cool user\",  \"email\": \"u.cool@example.com\" }"

let jsonData: NSData? = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

//~~~~~~~~~~~~~~~ if-let конструкции ~~~~~~~

func getUser0(jsonOptional: NSData?, callback: (User) -> ()) {
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional!,
                                                     options: NSJSONReadingOptions(0),
                                                       error: &jsonErrorOptional)
    
    //это ошибка Swift, приводящая к "кастингу" AnyObject?
    
    if let json =  jsonObject as? Dictionary<String,AnyObject> {
        if let name = json["name"] as AnyObject? as? String {
            if let id = json["id"] as AnyObject? as? Int {
                if let email = json["email"] as AnyObject? as? String {
                    let user:User = User(id: id, name: name, email: email)
                    callback(user)
                }
            }
        }
    }
}
//      ----- Тест 1 правильные данные------

getUser0(jsonData){ user in
    println("\(user.description)")
    return // для удаления ошибки closure с одной строкой

}

//~~~~~~~~~~~~~~~~ Управление ошибками с помощью enum Result<A> ~~~~~~~

enum Result<A> {
    case Error(NSError)
    case Value(Box<A>)
    
    init(_ error: NSError?, _ value: A) {
        if let err = error {
            self = .Error(err)
        } else {
            self = .Value(Box(value))
        }
    }
}

final class Box<A> {
    let value: A
    
    init(_ value: A) {
        self.value = value
    }
}

//--------------- Для печати Result  ---


func stringResult<A:Printable>(result: Result<A> ) -> String {
    switch result {
    case let .Error(err):
        return "\(err.localizedDescription)"
    case let .Value(box):
        return "\(box.value.description)"
    }
}

// ------------ Возврат ошибки NSError ----
// Для упрощения работы с классом NSError создаем 
//    "удобный" инициализатор в расширении класса

extension NSError {
    convenience init(localizedDescription: String) {
        self.init(domain: "", code: 0,
            userInfo: [NSLocalizedDescriptionKey: localizedDescription])
    }
}

//--------------------- Возврат Result<User> ---
func getUser1(jsonOptional: NSData?, callback: (Result<User>) -> ()) {
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional!,
                                                     options: NSJSONReadingOptions(0),
                                                       error: &jsonErrorOptional)
    
    if let err = jsonErrorOptional {
        println("\(err.localizedDescription)")
        callback(.Error(err))
        return
    }
    
    //это ошибка Swift, приводящая к "кастингу" AnyObject?


    if let json =  jsonObject as? Dictionary<String,AnyObject> {
        if let name = json["name"] as AnyObject? as? String {
            if let id = json["id"] as AnyObject? as? Int {
                if let email = json["email"] as AnyObject? as? String {
                    let user:User = User(id: id, name: name, email: email)
                    
                     callback(.Value(Box(user)))
                    
                    return
                 }
            }
        }
    }
    
    callback(.Error(NSError(localizedDescription: "Отсутствуют компоненты User")))
}

//      ----- Тест 1 - правильные данные -----

let jsonString2: String =
        "{ \"id\": 1, \"name\":\"Cool user\",\"email\": \"u.cool@example.com\" }"

let jsonData2: NSData? = jsonString2.dataUsingEncoding(NSUTF8StringEncoding,
                                                 allowLossyConversion: true)

getUser1(jsonData2 ){ user in
    let a = stringResult(user)
    println("\(a)")
}

//      ----- Тест 2 - неправильные данные (лишняя фигурная скобка) -----

let jsonString3: String =
        "{ {\"id\": 1, \"name\":\"Cool user\",\"email\": \"u.cool@example.com\" }"

let jsonData3: NSData? = jsonString3.dataUsingEncoding(NSUTF8StringEncoding,
                                                 allowLossyConversion: true)

getUser1(jsonData3 ){ user in
    let a = stringResult(user)
    println("\(a)")
}

//      ----- Тест 3 - неправильные данные ( вместо "id" "id1") -----

let jsonString4: String =
        "{ \"id1\": 1, \"name\":\"Cool user\",\"email\": \"u.cool@example.com\" }"

let jsonData4: NSData? = jsonString4.dataUsingEncoding(NSUTF8StringEncoding,
                                                allowLossyConversion: true)

getUser1(jsonData4 ){ user in
    let a = stringResult(user)
    println("\(a)")
}

//~~~~~~~~~~~~~~~~ Уничтожаем проверку типов ~~~~~~~

typealias JSON = AnyObject
typealias JSONDictionary = Dictionary<String, JSON>
typealias JSONArray = Array<JSON>

infix operator >>> { associativity left precedence 150 }

func >>><A, B>(a: A?, f: A -> B?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .None
    }
}

func JSONString(object: JSON) -> String? {
    return object as? String
}

func JSONInt(object: JSON) -> Int? {
    return object as? Int
}

func JSONObject(object: JSON) -> JSONDictionary? {
    return object as? JSONDictionary
}

//--------------------- Используем оператор >>> ---

func getUser2(jsonOptional: NSData?, callback: (Result<User>) -> ()) {
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional!,
                                                     options: NSJSONReadingOptions(0),
                                                       error: &jsonErrorOptional)
    
    if let err = jsonErrorOptional {
        callback(.Error(err))
        return
    }
    
    if let json =  jsonObject >>> JSONObject {
        if let name = json["name"] >>> JSONString {
            if let id = json["id"] >>> JSONInt {
            if let email = json["email"] >>> JSONString {
                    let user:User = User(id: id, name: name, email: email)
                    callback(.Value(Box(user)))
                    return
                }
            }
        }
    }
    
    callback(.Error(NSError(localizedDescription: "Отсутствуют компоненты User")))
}

//      ----- Тест 1 - правильные данные -----

getUser2(jsonData){ user in
    let a = stringResult(user)
    println("\(a)")
}

//--------------------- Новые операторы <^>   и  <*>  ---

infix operator <^> { associativity left } // Functor's fmap (usually <$>)
infix operator <*> { associativity left } // Applicative's apply

func <^><A, B>(f: A -> B, a: A?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .None
    }
}

func <*><A, B>(f: (A -> B)?, a: A?) -> B? {
    if let x = a {
        if let fx = f {
            return fx(x)
        }
    }
    return .None
}
//----------Расширяем struct User с помощью curried обертки инициализатора ---
//
//    static func create(id: Int)(name: String)(email: String) -> User {
//        return User(id: id, name: name, email: email)
//    }

//--------------------- Собираем все вместе ---

func getUser3(jsonOptional: NSData?, callback: (Result<User>) -> ()) {
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional!,
                                                     options: NSJSONReadingOptions(0),
                                                            error: &jsonErrorOptional)
    
    if let err = jsonErrorOptional {
        callback(.Error(err))
        return
    }
    
    if let json =  jsonObject >>> JSONObject {
        let user = User.create
            <^> json["id"]    >>> JSONInt
            <*> json["name"]  >>> JSONString
            <*> json["email"] >>> JSONString
        if let u = user {
            callback(.Value(Box(u)))
            return
        }
    }    
    callback(.Error(NSError(localizedDescription: "Отсутствуют компоненты User")))
}

//      ----- Тест 1 - правильные данные -----

getUser3(jsonData){ user in
    let a = stringResult(user)
    println("\(a)")
}

//~~~~~~~~~~~~~~~~ Уничтожаем многочисленные callback ~~~~~~~

func resultFromOptional<A>(optional: A?, error: NSError) -> Result<A> {
    if let a = optional {
        return .Value(Box(a))
    } else {
        return .Error(error)
    }
}

//--------------------- Оператор >>> для Result---

func >>><A, B>(a: Result<A>, f: A -> Result<B>) -> Result<B> {
    switch a {
    case let .Value(x):     return f(x.value)
    case let .Error(error): return .Error(error)
    }
}

//------------ NSData -> Result<JSON> --------

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

//------------------ Для Optionals JSON? -----

func decodeJSON(data: NSData?) -> JSON? {
    let jsonOptional: JSON? = NSJSONSerialization.JSONObjectWithData(data!,
                                          options: NSJSONReadingOptions(0),
                                          error: nil)
    if let json: JSON = jsonOptional {
        return json
    } else {
        return .None
    }
}

//---------- Добавляем в Result<A> инициализатор ---
//    init(_ error: NSError?, _ value: A) {
//        if let err = error {
//            self = .Error(err)
//        } else {
//            self = .Value(Box(value))
//        }
//    }

extension User {
    static func decode(json: JSON) -> Result<User> {
        let user = JSONObject(json) >>> { dict in
            User.create
                <^> dict["id"]    >>> JSONInt
                <*> dict["name"]  >>> JSONString
                <*> dict["email"] >>> JSONString
        }
        return resultFromOptional(user,
            NSError(localizedDescription: "Отсутствуют компоненты User")) 
    }
}

//--------------------- Собираем все вместе ---

func getUser4(jsonOptional: NSData?, callback: (Result<User>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional,
                           NSError(localizedDescription: "JSON данные неверны"))
    let user: ()? = jsonResult >>> decodeJSON
                               >>> User.decode >>> callback
}

//      ----- Тест 1 - правильные данные -----

getUser4(jsonData){ user in
let a = stringResult(user)
println("\(a)")
}

//      ----- Тест 2 - неправильные данные (лишняя фигурная скобка) -----

getUser4(jsonData3){ user in
    let a = stringResult(user)
    println("\(a)")
}

//      ----- Тест 3 - неправильные данные ( вместо "id" "id1") -----

getUser4(jsonData4){ user in
    let a = stringResult(user)
    println("\(a)")
}

//~~~~~~~~~~~~~~~~~~~~~ Используем Generic ~~~~~~~~~~~~~~

protocol JSONDecodable {
    class func decode(json: JSON) -> Self?
}

//------------ JSON -> Result<A> --------

func decodeObject<A: JSONDecodable>(json: JSON) -> Result<A> {
    return resultFromOptional(A.decode(json),
                   NSError(localizedDescription: "Отсутствуют компоненты Модели")) 
}

//------------- JSON -> A? -------------

func decodeObject<A: JSONDecodable>(json: JSON) -> A? {
    return A.decode(json)
}

//--------- Модель User1 ------------------------------

struct User1: JSONDecodable, Printable {
    let id: Int = 0
    let name: String = ""
    let email: String = ""
    
    var description : String {
        return "User1 { id = \(id), name = \(name), email = \(email)}"
    }
    static func create(id: Int)(name: String)(email: String) -> User1 {
        return User1(id: id, name: name, email: email)
    }

    static func decode(json: JSON) -> User1? {
        return JSONObject(json) >>> { d in
            User1.create
                <^> d["id"]    >>> JSONInt
                <*> d["name"]  >>> JSONString
                <*> d["email"] >>> JSONString
        }
    }
}

func getUser5(jsonOptional: NSData?, callback: (Result<User1>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional,
                             NSError(localizedDescription: "JSON данные неверны"))
    jsonResult >>> decodeJSON >>> decodeObject >>> callback
}

//      ----- Тест 1 - правильные данные -----

getUser5(jsonData){ user1 in
    let a = stringResult(user1)
    println("\(a)")
}

//      ----- Тест 2 - неправильные данные (лишняя фигурная скобка) -----

getUser5(jsonData3){ user in
    let a = stringResult(user)
    println("\(a)")
}

//      ----- Тест 3 - неправильные данные ( вместо "id" "id1") -----

getUser5(jsonData4){ user in
    let a = stringResult(user)
    println("\(a)")
}
//~~~~~~~~~~~~ Вариант с Optional ~~~~~~~~~~~~~~~~~~~~~~~

func getUser6(jsonOptional: NSData?, callback: (User1?) -> ()) {
    jsonOptional >>> decodeJSON >>> decodeObject >>> callback
}

//      ----- Тест 1 - правильные данные -----

getUser6(jsonData){ user1 in
    println("\(user1?.description)")
    return
}
//      ----- Тест 2 - неправильные данные (лишняя фигурная скобка) -----

getUser6(jsonData3){ user1 in
    println("\(user1?.description)")
    return
}

