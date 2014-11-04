//
//  Blog.swift
//  EfficientJSON
//
//  Created by Tatiana Kornilova on 10/16/14.
//  Copyright (c) 2014 Tatiana Kornilova. All rights reserved.
//

import Foundation

func toURL(urlString: String) -> NSURL {
    return NSURL(string: urlString)!
}

struct Blog: Printable,JSONDecodable {
    let id: Int
    let name: String
    let needsPassword : Bool
    let url: NSURL
    var description : String {
        return "Blog { id = \(id), name = \(name), needsPassword = \(needsPassword), url = \(url)}"
    }
    
    static func create(id: Int)(name: String)(needsPassword: Int)(url:String) -> Blog {
        return Blog(id: id, name: name, needsPassword: Bool(needsPassword), url: toURL(url))
    }
    
    static func decode(json: JSON) -> Result<Blog> {
        let blog = _JSONParse(json) >>> { d in
            Blog.create
                <^> d <| "id"
                <*> d <| "name"
                <*> d <| "needspassword"
                <*> d <| "url"
        }
        return resultFromOptional(blog, NSError()) // custom error message
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
// ----Структура Blogs ----

struct Blogs: Printable,JSONDecodable {
    
    var blogs : [Blog]
    
    var description :String  { get {
        var str: String = ""
        for blog in self.blogs {
            str = str +  "\(blog) \n"
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
// ---- Конец структуры Blogs----

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
                                            let user = Blog(id: id, name: name, needsPassword:needPassword, url: NSURL(string:url)!)
                                            callback(user)
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





// ----- использована структура Blogs -----КЛАСС!!!

func getBlog11(jsonOptional: NSData?, callback: (Result<Blogs>) -> ()) {
    let jsonResult = resultFromOptional(jsonOptional, NSError(localizedDescription: " Неверные данные"))
    let json: ()? =  jsonResult  >>> decodeJSON  >>> decodeObject >>> callback
}



