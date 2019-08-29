//
//  SerialNumberMatcher.swift
//  macOS Utilities: Hypervisor
//
//  Created by Keaton Burleson on 8/28/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Alamofire
import XMLParsing
import Foundation

struct Root: Codable {
    var configCode: String
}

class SerialNumberMatcher {
    static func matchToProductName(_ serialNumber: String, completion: @escaping (String) -> ()) {
        var lastSerialDigits = String(serialNumber.suffix(4))
        
        if serialNumber.count == 11 {
            lastSerialDigits = String(serialNumber.suffix(3))
        }
        
        Alamofire.request("https://support-sp.apple.com/sp/product?cc=\(lastSerialDigits)")
            .responseData { response in
            
                let parsedResponse: Result<Root> = XMLDecoder().decodeResponse(from: response)
                if let serialResponse = parsedResponse.value {
                    completion(serialResponse.configCode)
                }
        }
    }
}
