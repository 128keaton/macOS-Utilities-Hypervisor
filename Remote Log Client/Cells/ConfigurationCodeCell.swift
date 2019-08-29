//
//  ConfigurationCodeCell.swift
//  Remote Log Client
//
//  Created by Keaton Burleson on 8/28/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Foundation
import Cocoa

class ConfigurationCodeCell: NSTableCellView {
    @IBOutlet private var configurationCodeLabel: NSTextField!

    override func awakeFromNib() {
        self.configurationCodeLabel.stringValue = "Loading.."
        self.configurationCodeLabel.textColor = NSColor.tertiaryLabelColor
    }

    public var client: Client? {
        didSet {
            guard let validClient = self.client else {
                return
            }

            if let validSerialNumber = validClient.serialNumber {
                SerialNumberMatcher.matchToProductName(validSerialNumber) { (configurationCode) in
                    self.configurationCodeLabel.stringValue = configurationCode
                    self.configurationCodeLabel.textColor = NSColor.labelColor
                }
            } else {
                validClient.hasSerialNumber.append { serialNumber in
                    SerialNumberMatcher.matchToProductName(serialNumber) { (configurationCode) in
                        self.configurationCodeLabel.stringValue = configurationCode
                        self.configurationCodeLabel.textColor = NSColor.labelColor
                    }
                }
            }
        }
    }
}
