//
//  PlaceModel.swift
//  MyPlaces
//
//  Created by Dmytro Grytsenko on 21.11.2022.
//

import UIKit

struct Place {
    
    let name: String
    let location: String?
    let type: String?
    let image: UIImage?
    let restaurantImage: String?
    
    static private let restaurantNames = [
        "Украинские Стравы", "Gorcafe 1654", "Корчма Качка", "Мир кофе",
        "Портофино", "Кафе Библиотека", "Штефаньо"
    ]
    
    static func getPlaces() -> [Place] {
        
        var places = [Place]()
        
        for place in restaurantNames {
            places.append(Place(name: place, location: "Украина", type: "ресторан", image: nil, restaurantImage: place))
        }
        
        return places
    }
}
