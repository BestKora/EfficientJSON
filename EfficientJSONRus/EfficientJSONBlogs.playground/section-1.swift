// Playground - noun: a place where people can play

import Foundation

//---- по статье http://robots.thoughtbot.com/parsing-embedded-json-and-arrays-in-swift

/*  структура Post поста социальных сетей

let parsedJSON : [String:AnyObject] =
{
"id": 5,
"text": "This is a post.",
"author": {
"id": 1,
"name": "Cool User"
}
}*/
// ---------- БУДЬТЕ ВНИМАТЕЛЬНЫ - КОМПИЛИРУЕТСЯ 1.5 -2 минуты--------


//~~~~~~~~~~~~~~~~~~~~~~~ ПАРСИНГ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
typealias JSON = AnyObject
typealias JSONObject = [String:JSON]
typealias JSONArray = [JSON]


//---------- ОПЕРАТОРЫ функционального программирования >>>  <^>   и  <*>  ---
infix operator >>> { associativity left precedence 150 } // Bind
infix operator <^> { associativity left } // Functor's fmap (usually <$>)
infix operator <*> { associativity left } // Applicative's apply

func >>><A, B>(a: A?, f: A -> B?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .None
    }
}

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

//~~~~~~~~~~ работаем с enum  Result<A> ~~~~~~~~~~~~

final class Box<A> {
    let value: A
    
    init(_ value: A) {
        self.value = value
    }
}

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
//--------------- Для печати Result ---


func stringResult<A:Printable>(result: Result<A> ) -> String {
    switch result {
    case let .Error(err):
        return "\(err.localizedDescription)"
    case let .Value(box):
        return "\(box.value.description)"
    }
}
//-----------------------------от Optional к  Result<A> ---------

func resultFromOptional<A>(optional: A?, error: NSError) -> Result<A> {
    if let a = optional {
        return .Value(Box(a))
    } else {
        return .Error(error)
    }
}
// ------------ Возврат ошибки NSError ----
// Для упрощения работы с классом NSError создаем "удобный" инициализатор в расширении класса

extension NSError {
    convenience init(localizedDescription: String) {
        self.init(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
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
//--------------------- Оператор >>> для Result---

func >>><A, B>(a: Result<A>, f: A -> Result<B>) -> Result<B> {
    switch a {
    case let .Value(x):     return f(x.value)
    case let .Error(error): return .Error(error)
    }
}
//~~~~~~~~~ДОБАВЛЯЕМ ФУНКЦИИ  ~~~~~~~~~~~~~~~~~~~
//------- flatten функцию ---
func flatten<A>(array: [A?]) -> [A] {
    var list: [A] = []
    for item in array {
        if let i = item {
            list.append(i)
        }
    }
    return list
}
//-------pure функцию ---
func pure<A>(a: A) -> A? {
    return .Some(a)
}
//---------------- Используем Generics -----------

protocol JSONDecodable {
    class func decode(json: JSON) -> Self?
}

func decodeObject<A: JSONDecodable>(json: JSON) -> Result<A> {
    return resultFromOptional(A.decode(json), NSError(localizedDescription: "Отсутствуют компоненты модели")) // custom error
}

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

//-------- Операторы извлечения данных из JSON-------

infix operator <| { associativity left precedence 150 }
infix operator <|* { associativity left precedence 150 }

func <|<A: JSONDecodable>(d: JSONObject, key: String) -> A? {
    return d[key] >>> _JSONParse
}

func <|(d: JSONObject, key: String) -> JSONObject {
    return d[key] >>> _JSONParse ?? JSONObject()
}

func <|<A: JSONDecodable>(d: JSONObject, key: String) -> [A]? {
    return d[key] >>> _JSONParse >>> { (array: JSONArray) in
        array.map { _JSONParse($0) } >>> flatten
    }
}

func <|*<A: JSONDecodable>(d: JSONObject, key: String) -> A?? {
    return pure(d <| key)
}

//~~~~~~~~~~~~ BLOGS ~~~~~~~~~~~~~~~~~~
// Данные как в статье Cris Eidnof http://chris.eidhof.nl/posts/json-parsing-in-swift.html

/*
let parsedJSON : [String:AnyObject] = [
 "stat": "ok",
 "blogs": [
           "blog": [
                     [
                       "id" : 73,
                       "name" : "Bloxus test",
                       "needspassword" : true,
                       "url" : "http://remote.bloxus.com/"
                     ],
                     [
                       "id" : 74,
                       "name" : "Manila Test",
                       "needspassword" : false,
                       "url" : "http://flickrtest1.userland.com/"
                     ]
                   ]
             ]
]
*/
//~~~~~~~~~~~~~~~~~~~~~ корректные ДАННЫЕ для Blogs ~~~~~~~~~~~~~~~~~~~~~~~

var jsonString = "{ \"stat\": \"ok\", \"blogs\": { \"blog\": [ { \"id\" : 73, \"name\" : \"Bloxus test\", \"needspassword\" : true, \"url\" : \"http://remote.bloxus.com/\" }, { \"id\" : 74, \"name\" : \"Manila Test\", \"needspassword\" : false, \"url\" : \"http://flickrtest1.userland.com/\" } ] } }"
let jsonData = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)


//---------------------- String --> NSURL--------
func toURL(urlString: String) -> NSURL {
    return NSURL(string: urlString)!
}

//~~~~~~~~~~~~~~~~~~~~~~~  МОДЕЛЬ одного Blog ~~~~~~~~~~~~~~~

struct Blog: Printable,JSONDecodable  {
    let id: Int
    let name: String
    let needsPassword : Int
    let url: NSURL
    
    var description : String { get {
        return "Blog { id = \(id), name = \(name), needsPassword = \(needsPassword), url = \(url)}"
        }}
    
    static func create(id: Int)(name: String)(needsPassword: Int)(url:String) -> Blog {
        return Blog(id: id, name: name, needsPassword: needsPassword, url: toURL(url))
    }
    
    
    static func decode(json: JSON) -> Blog? {
        return _JSONParse(json) >>> { d in
            Blog.create
                <^> d <| "id"
                <*> d <| "name"
                <*> d <| "needspassword"
                <*> d <| "url"
        }
    }
}

//-------------------- МОДЕЛЬ массива блогов [Blog]--------

struct Blogs: Printable,JSONDecodable {
    
    var blogs : [Blog]
    
    var description :String  { get {
        var str: String = "Blogs :"
        for blog in self.blogs {
            str = str +  "\(blog.description) \n"
        }
        return str
        }
    }
    
    static func create(blogs: [Blog]) -> Blogs {
        return Blogs(blogs: blogs)
    }
    
    static func decode(json: JSON) -> Blogs? {
        return _JSONParse(json) >>> { d in
            Blogs.create
                <^> d <| "blogs" <| "blog"

        }
    }
}

//------------ Тест Blogs -----

func getBlogs(jsonOptional: NSData?, callback: (Result<Blogs>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional,
                       NSError(localizedDescription: " Неверные данные"))
    let user: ()? = jsonResult >>> decodeJSON >>> decodeObject >>> callback
}

getBlogs(jsonData){ user in
    let a = stringResult(user)
    println("\(a)")
}
