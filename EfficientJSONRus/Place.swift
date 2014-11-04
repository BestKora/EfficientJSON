//
//  Place.swift
//  EfficientJSON
//
//  Created by Tatiana Kornilova on 10/15/14.
//  Copyright (c) 2014 Tatiana Kornilova. All rights reserved.
//

import Foundation

// ---- Модель Place ----

struct Place: Printable ,JSONDecodable {
    let placeURL: String
    let timeZone: String
    let photoCount : String
    let content : String
    
    var description :String {
      return "Place { placeURL = \(placeURL), timeZone = \(timeZone), photoCount = \(photoCount),content = \(content)} \n"
    }
    
    static func create(placeURL: String)(timeZone: String)(photoCount: String)(content: String) -> Place {
        return Place(placeURL: placeURL, timeZone: timeZone, photoCount: photoCount,content: content)
    }
    static func decode(json: JSON) -> Place? {
        return _JSONParse(json) >>> { d in
            Place.create
                <^> d <| "place_url"
                <*> d <| "timezone"
                <*> d <| "photo_count"
                <*> d <| "_content"
        }
    }
   
}

// ---- Модель Places ----

struct Places: Printable,JSONDecodable {
    
    var places : [Place]
    
    var description :String  { get {
        var str: String = ""
            for place in self.places {
             str = str +  "\(place) \n"
            }
          return str
        }
    }
    static func create(places: [Place]) -> Places {
        return Places(places: places)
    }
/* ----- В статье у Chris Eidhof ----
    
    static func decode(json: JSON) -> Places? {
        return create <^> JSONObject(json) >>> {
                  dictionary ($0,"places") >>> {
                        array($0, "place") >>> { flatten($0.map(Place.decode))
                        }
                  }
        }
    }

    static func decode(json: JSON) -> Places? {
        return create <^> JSONObject(json)
                       |> "places"
                      ||> "place" >>> {flatten($0.map(Place.decode))}
    }
*/
    static func decode(json: JSON) -> Places? {
        return _JSONParse(json) >>> { d in
            Places.create
                <^> d <| "places" <| "place"
            
        }
    }
}
// ---- Конец структуры Places----

