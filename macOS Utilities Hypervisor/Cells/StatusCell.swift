//
//  StatusCell.swift
//  macOS Utilities: Hypervisor
//
//  Created by Keaton Burleson on 8/28/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Foundation
import Cocoa

class StatusCell: NSTableCellView {
    @IBOutlet private var statusLabel: NSTextField!
    
    override func awakeFromNib() {
        self.statusLabel.stringValue = "Connecting.."
        self.statusLabel.textColor = NSColor.tertiaryLabelColor
    }
    
    public var client: Client? {
        didSet {
            guard let validClient = self.client else {
                return
            }
            
            validClient.statusUpdated = { status in
                self.statusLabel.stringValue = status
                self.statusLabel.textColor = NSColor.labelColor
            }
        }
    }
}
