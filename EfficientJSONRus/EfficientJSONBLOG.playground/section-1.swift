// Playground - noun: a place where people can play
import Foundation
import XCPlayground

XCPSetExecutionShouldContinueIndefinitely()

//---- по статье http://robots.thoughtbot.com/efficient-json-in-swift-with-functional-concepts-and-generics

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
//~~~~~~~~~~~~~~~~~~~~~ корректные ДАННЫЕ ~~~~~~~~~~~~~~~~~~~~~~~

var jsonString1 = "{ \"stat\": \"ok\", \"blogs\": { \"blog\": [ { \"id\" : 73, \"name\" : \"Bloxus test\", \"needspassword\" : true, \"url\" : \"http://remote.bloxus.com/\" }, { \"id\" : 74, \"name\" : \"Manila Test\", \"needspassword\" : false, \"url\" : \"http://flickrtest1.userland.com/\" } ] } }"
let jsonData1 = jsonString1.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

//~~~~~~~~~~~~~~~~~~~~~~~ ПАРСИНГ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
typealias JSON = AnyObject
typealias JSONDictionary = Dictionary<String, JSON>
typealias JSONArray = Array<JSON>



func JSONString(object: JSON) -> String? {
    return object as? String
}

func JSONInt(object: JSON) -> Int? {
    return object as? Int
}

func JSONObject(object: JSON) -> JSONDictionary? {
    return object as? JSONDictionary
}

func JSONCollection(object: JSON) -> JSONArray? {
    return object as? JSONArray
}

//--------------------- Новые операторы <^>   и  <*>  ---
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
    let jsonOptional: JSON? = NSJSONSerialization.JSONObjectWithData(data!,
                                          options: NSJSONReadingOptions(0),
                                                                error: nil)
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
//~~~~~~~~~~~~~ Используем Generics ~~~~~~~~~~~~~~~~

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

//-----------Вынимаем словари и массивы из словарей по ключам --------------

func dictionary(input: JSONDictionary, key: String) ->  JSONDictionary? {
    return input[key] >>> { $0 as? JSONDictionary }
}

func array(input: JSONDictionary, key: String) ->  JSONArray? {
    return input[key] >>> { $0 as?  JSONArray}
}

public func flatten<A>(array: [A?]) -> [A] {
    var list: [A] = []
    for item in array {
        if let i = item {
            list.append(i)
        }
    }
    return list
}

//----------------------------- enum  Result<A> ---------

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

//---------------------- String --> NSURL--------
func toURL(urlString: String) -> NSURL {
    return NSURL(string: urlString)!
}

//~~~~~~~~~~~~~~~~~~~~~~~  МОДЕЛЬ одного Blog ~~~~~~~~~~~~~~~

struct Blog: Printable,JSONDecodable  {
    let id: Int
    let name: String
    let needsPassword : Bool
    let url: NSURL

    var description : String { get {
        return "Blog { id = \(id), name = \(name), needsPassword = \(needsPassword), url = \(url)}"
        }}
    
    static func create(id: Int)(name: String)(needsPassword: Int)(url:String) -> Blog {
        return Blog(id: id, name: name, needsPassword: Bool(needsPassword), url: toURL(url))
    }
    
    static func decode(json: JSON) -> Result<Blog> {
        let blog = JSONObject(json) >>> { dict in
            Blog.create
                <^> dict["id"]   >>> JSONInt
                <*> dict["name"] >>> JSONString
                <*> dict["needspassword"] >>> JSONInt
                <*> dict["url"]  >>> JSONString
        }
        return resultFromOptional(blog, NSError()) // custom error message
    }

    static func decode(json: JSON) -> Blog? {
        return  JSONObject(json) >>> { dict in
            Blog.create
                <^> dict["id"]   >>> JSONInt
                <*> dict["name"] >>> JSONString
                <*> dict["needspassword"] >>> JSONInt
                <*> dict["url"]  >>> JSONString
        }
    }
}

//-------------------- МОДЕЛЬ массива блогов--------

struct Blogs: Printable,JSONDecodable {
    
    var blogs : [Blog]?
    
    var description :String  { get {
        var str: String = ""
        for blog in self.blogs! {
            str = str +  "\(blog.description) \n"
        }
        return str
        }
    }

    static func create(blogs: [Blog]) -> Blogs {
        return Blogs(blogs: blogs)
    }
    
    static func decode(json: JSON) -> Blogs? {
        return create <*> JSONObject(json) >>> {
                   dictionary ($0,"blogs") >>> {
                         array($0, "blog") >>> {flatten($0.map(Blog.decode))}
            }
        }
    }
}
// ---- Конец структуры Blogs----


//~~~~~~~~~~ специализированные ФУНКЦИИ ПАРСИНГА  для модели Blog ~~~~~~~~~~~~~~~~

//-------------- травиальная разборка с if-let------------------------------

func getBlog1(jsonOptional: NSData?, callback: (Blog) -> ()) {
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional!, options: NSJSONReadingOptions(0), error: &jsonErrorOptional)
    
    if let dict =  jsonObject as? Dictionary<String,AnyObject> {
        if let blogs = dict["blogs"] as AnyObject? as? Dictionary<String,AnyObject>   {
            if let blogItems : AnyObject = blogs["blog"] {
                if let collection = blogItems as? Array<AnyObject> {
                    for blog : AnyObject in collection {
                        if let blogInfo = blog as? Dictionary<String,AnyObject>  {
                            
                            if let id =  blogInfo["id"] as AnyObject? as? Int { // Currently in beta 5 there is a bug that forces us to cast to AnyObject? first
                                if let name = blogInfo["name"] as AnyObject? as? String {
                                    if let needPassword = blogInfo["needspassword"] as AnyObject? as? Bool {
                                        if let url = blogInfo["url"] as AnyObject? as? String {
                                            let blog = Blog(id: id, name: name, needsPassword:needPassword, url: NSURL(string:url)!)
                                            callback(blog)
                                            return
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
//------------- ТЕСТ 1 ВЫЗОВ ФУНКЦИЙ ПАРСИНГА правильных данных------------

println("----- 1:")
getBlog1(jsonData1){ blog in
    let a = blog.description
    println("\(a)")
}
//-------------------------------- возвращаем Result<Blog> ----

func getBlog2(jsonOptional: NSData?, callback: (Result<Blog>) -> ()) {
    var jsonErrorOptional: NSError?
    let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(jsonOptional!,
        options: NSJSONReadingOptions(0),
        error: &jsonErrorOptional)
    
    if let err = jsonErrorOptional {
        callback(.Error(err))
        return
    }
    
    
    if let dict =  jsonObject as? Dictionary<String,AnyObject> {
        if let blogs = dict["blogs"]  as AnyObject? as? Dictionary<String,AnyObject>   {
            if let blogItems : AnyObject = blogs["blog"] {
                if let collection = blogItems as? Array<AnyObject> {
                    for blog : AnyObject in collection {
                        if let blogInfo = blog as? Dictionary<String,AnyObject>  {
                            if let id =  blogInfo["id"] as AnyObject? as? Int { // Currently in beta 5 there is a bug that forces us to cast to AnyObject? first
                                if let name = blogInfo["name"] as AnyObject? as? String {
                                    if let needPassword = blogInfo["needspassword"] as AnyObject? as? Bool {
                                        if let url = blogInfo["url"] as AnyObject? as? String {
                                            let blog = Blog(id: id, name: name, needsPassword:needPassword, url: NSURL(string:url)!)
                                            callback(.Value(Box(blog)))
                                            return
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    callback(.Error(NSError()))
}

//------------- ТЕСТ 1  правильных данных------------

println("----- 2:")
getBlog2(jsonData1 ){ blog in
    let a = stringResult(blog)
    println(" \(a)")
}

//---- используем оператор >>> и функции JSONObject, JSONCollection и decodeJSON----

func getBlog6(jsonOptional: NSData?, callback: (Result<Blog>) -> ()) {
    
    if let dict =  jsonOptional >>> decodeJSON  >>> JSONObject  {
        if let blogs = dict["blogs"] >>> JSONObject   {
            if let collection = blogs["blog"] >>> JSONCollection {
                for blog : AnyObject in collection {
                    let blogInfo:()? = blog >>> JSONObject  >>>
                                                    Blog.decode >>> callback
                    return
                }
            }
        }
    }
}
//------------- ТЕСТ 1  правильных данных----

println("----- 6:")
getBlog6(jsonData1 ){ blog in
    let a = stringResult(blog)
    println(" \(a)")
}

//---- используем протокол JSONDecodable и дженерики для структуры Blogs ----

func getBlog11(jsonOptional: NSData?, callback: (Result<Blogs>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional,
                                          NSError(localizedDescription: "JSON данные неверны"))
    jsonResult  >>> decodeJSON  >>> decodeObject >>> callback
}

//------------- ТЕСТ 11 (структура Blogs) правильных данных это КЛАСС!!----

println("----- 11 БЛОГИ:")
getBlog11(jsonData1 ) { blogs in
    let a = stringResult(blogs)
    println(" \(a)")
}





