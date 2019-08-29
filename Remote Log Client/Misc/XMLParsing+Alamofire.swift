//
//  XMLParsing+Alamofire.swift
//  Remote Log Client
//
//  Created by Keaton Burleson on 8/28/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Foundation
import XMLParsing
import Alamofire

extension XMLDecoder {
    public enum XMLError: Error {
        case parsing(reason: String)
    }
    
    func decodeResponse<T: Decodable>(from response: DataResponse<Data>) -> Result<T> {
        guard response.error == nil else {
            print(response.error!.localizedDescription)
            return .failure(response.error!)
        }
        
        guard let responseData = response.data else {
            print("didn't get any data from API")
            return .failure(XMLError.parsing(reason: "Did not get data in response"))
        }
        
        do {
            let item = try decode(T.self, from: responseData)
            return .success(item)
        } catch {
            print(error.localizedDescription)
            return .failure(error)
        }
    }
}
