//
//  SerialNumberCell.swift
//  Remote Log Client
//
//  Created by Keaton Burleson on 8/28/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Foundation
import Cocoa

class SerialNumberCell: NSTableCellView {
    @IBOutlet private var serialNumberLabel: NSTextField!
    
    public var client: Client? {
        didSet {
            guard let validClient = self.client  else {
                return
            }
            
            if let validSerialNumber = validClient.serialNumber {
                self.serialNumberLabel.stringValue = validSerialNumber
            } else {
                validClient.hasSerialNumber.append { serialNumber in
                     self.serialNumberLabel.stringValue = serialNumber
                }
            }
        }
    }
}
