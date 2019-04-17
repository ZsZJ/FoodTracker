//
//  APIManager.swift
//  FoodTracker
//
//  Created by Joey Lim on 15/04/2019.
//  Copyright © 2019 Joey Lim. All rights reserved.
//

import UIKit
import SwiftyJSON

class APIManager: NSObject {
    let baseURL = "https://www.food2fork.com/api/"
    static let sharedInstance = APIManager()
//    static let APIKey = "a1bad66e2171d049b5babdcd1a2303ce"
    static let APIKey = "fb4b457b6c9d9f8a1022459f143356a4"
    static let getDishEndpoint = "/search?"
    static let getRecipeEndpoint = "/get?"
    
    func getDishWithName(dishName: String, onSuccess: @escaping(JSON) -> Void, onFailure: @escaping(Error) -> Void){
        let url : String = baseURL + APIManager.getDishEndpoint + "key=" + APIManager.APIKey + "&q=" + String(dishName)
        let request: NSMutableURLRequest = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        request.httpMethod = "GET"
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            if(error != nil){
                onFailure(error!)
            } else{
                do {
                    let result = try JSON(data: data!)
                    onSuccess(result)
                } catch {
                    print(error)
                }
            }
        })
        task.resume()
    }
    
    func getRecipeWithDishId(dishId: String, onSuccess: @escaping(JSON) -> Void, onFailure: @escaping(Error) -> Void) {
        let url : String = baseURL + APIManager.getRecipeEndpoint + "key=" + APIManager.APIKey + "&rId=" + String(dishId)
        let request: NSMutableURLRequest = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        request.httpMethod = "GET"
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            if(error != nil){
                onFailure(error!)
            } else{
                do {
                    let result = try JSON(data: data!)
                    onSuccess(result)
                    print(result)
                } catch {
                    print(error)
                }
            }
        })
        task.resume()
    }
    
}
