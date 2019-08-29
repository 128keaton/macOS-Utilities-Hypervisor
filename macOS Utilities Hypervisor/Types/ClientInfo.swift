//
//  ClientInfo.swift
//  MultiPeer_Sample-macOS
//
//  Created by Keaton Burleson on 8/28/19.
//  Copyright © 2019 Wilson Ding. All rights reserved.
//

import Foundation
import MultipeerConnectivity

public class ClientInfo:  NSObject, NSCoding, NSSecureCoding {
    public static var supportsSecureCoding: Bool = true
    
    var serialNumber: String?
    var peerID: MCPeerID?
    var status: String?
    
    init(serialNumber: String, peerID: MCPeerID) {
        self.serialNumber = serialNumber
        self.peerID = peerID
    }
    
    required public init(coder decoder: NSCoder) {
        self.serialNumber = decoder.decodeObject(forKey: "serialNumber") as? String
        self.peerID = decoder.decodeObject(forKey: "peerID") as? MCPeerID
        self.status = decoder.decodeObject(forKey: "status") as? String
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(serialNumber, forKey: "serialNumber")
        coder.encode(peerID, forKey: "peerID")
        coder.encode(status, forKey: "status")
    }
}
