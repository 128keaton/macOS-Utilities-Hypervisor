//
//  Peer.swift
//  Remote Log Client
//
//  Created by Keaton Burleson on 8/28/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class Peer {
    var peerID: MCPeerID
    
    init(_ peerID: MCPeerID) {
        self.peerID = peerID
    }
}
