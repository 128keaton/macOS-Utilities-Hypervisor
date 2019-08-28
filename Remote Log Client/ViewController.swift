//
//  ViewController.swift
//  Remote Log Client
//
//  Created by Keaton Burleson on 8/28/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Cocoa
import MultipeerConnectivity

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet var tableView: NSTableView!

    var beepService = BeepService()
    var peers: [MCPeerID] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.beepService.delegate = self
    }


    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.peers.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let peer = self.peers[row]

        let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView


        if tableColumn!.identifier.rawValue == "modelIdentifier" {
            cell?.textField?.stringValue = String(peer.displayName.split(separator: ":")[0])
        } else {
            cell?.textField?.stringValue = String(peer.displayName.split(separator: ":")[1])
        }

        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = self.tableView.selectedRow

        if (self.peers.indices.contains(selectedRow)) {
            let peer = self.peers[selectedRow]
            self.beepService.beep(atPeer: peer)
            NSWorkspace.shared.open(URL(string: "http://\(peer.displayName.split(separator: ":")[1]):8080")!)
        }
    }
}

extension ViewController: BeepServiceDelegate {
    func connectedDevicesChanged(manager: BeepService, connectedDevices: [MCPeerID]) {
        connectedDevices.forEach { (peer) in
            self.peers.removeAll { $0.displayName == peer.displayName }
            self.peers.append(peer)
        }

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

}
