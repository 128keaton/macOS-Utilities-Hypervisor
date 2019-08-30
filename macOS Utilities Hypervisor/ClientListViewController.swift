//
//  ClientListViewController.swift
//  macOS Utilities: Hypervisor
//
//  Created by Keaton Burleson on 8/28/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Foundation
import Cocoa
import MultiPeer
import MultipeerConnectivity

public func log(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    let output = items.map { "\($0)" }.joined(separator: separator)
    Swift.print(output, terminator: terminator)
    XLSharedFacility.logMessage(output, withTag: nil, level: .logLevel_Info)
}


class ClientListViewController: NSViewController {
    @IBOutlet private var tableView: NSTableView!
    @IBOutlet private var segmentedControl: NSSegmentedControl!
    @IBOutlet private var progressIndicator: NSProgressIndicator!
    @IBOutlet private var foundCountLabel: NSTextField!

    private var pendingClients: [Client] = []
    private var currentClients: [Client] = []
    private var selectedClient: Client? = nil

    private let queue = DispatchQueue(label: "com.er2.macOS-Utilities.RemoteLogClient.ClientQueue")

    override func viewDidLoad() {
        super.viewDidLoad()

        self.buttonsEnabled = false
        self.foundCountLabel.stringValue = "\(self.currentClients.count) Found"
        self.progressIndicator.startAnimation(self)

        setupTableView()
        setupMultiPeer()
    }

    private func setupMultiPeer() {
        MultiPeer.instance.delegate = self

        MultiPeer.instance.initialize(serviceType: "mac-os-utils")
        MultiPeer.instance.startInviting()
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }

    private var buttonsEnabled: Bool {
        set {
            self.segmentedControl.setEnabled(newValue, forSegment: 0)
            self.segmentedControl.setEnabled(newValue, forSegment: 1)
            self.segmentedControl.setEnabled(newValue, forSegment: 2)
        }
        get {
            return (self.segmentedControl.isEnabled(forSegment: 0) && self.segmentedControl.isEnabled(forSegment: 1) && self.segmentedControl.isEnabled(forSegment: 2))
        }
    }

    @IBAction private func segmentClicked(_ sender: NSSegmentedControl) {
        guard let validSelectedClient = self.selectedClient else {
            return
        }

        switch sender.indexOfSelectedItem {
        case 0:
            MultiPeer.instance.send(object: MultiPeer.instance.devicePeerID!, type: MessageType.locateRequest.rawValue, toPeer: validSelectedClient.peer)
            break
        case 1:
            NSWorkspace.shared.open(URL(string: "vnc://\(validSelectedClient.ipAddress)")!)
            break
        case 2:
            NSWorkspace.shared.open(URL(string: "http://\(validSelectedClient.ipAddress):8080")!)
            break
        default:
            break
        }
    }
}

extension ClientListViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.currentClients.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if self.currentClients.indices.contains(row) {
            let client = self.currentClients[row]

            var cell: NSTableCellView?


            if tableColumn!.identifier.rawValue == "configurationCode" {
                cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? ConfigurationCodeCell
                (cell as! ConfigurationCodeCell).client = client
            } else if tableColumn!.identifier.rawValue == "ipAddress" {
                cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView
                cell?.textField?.stringValue = client.ipAddress
            } else if tableColumn!.identifier.rawValue == "serialNumber" {
                cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? SerialNumberCell
                (cell as! SerialNumberCell).client = client
            } else {
                cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? StatusCell
                (cell as! StatusCell).client = client
            }

            return cell
        }

        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = self.tableView.selectedRow

        if (self.currentClients.indices.contains(selectedRow)) {
            self.buttonsEnabled = true
            self.selectedClient = self.currentClients[selectedRow]

            if let validSelectedClient = self.selectedClient, validSelectedClient.serialNumber == nil {
                MultiPeer.instance.send(object: MultiPeer.instance.devicePeerID!, type: MessageType.clientInfoRequest.rawValue, toPeer: validSelectedClient.peer)
            }
        } else {
            self.buttonsEnabled = false
            self.selectedClient = nil
        }
    }

    func addClient(_ client: Client) {
        self.currentClients.append(client)
        self.currentClientsUpdated()
    }

    func currentClientsUpdated() {
        DispatchQueue.main.async {
            self.foundCountLabel.stringValue = "\(self.currentClients.count) Found"
            self.tableView.reloadData()

            if (self.currentClients.count == 0) {
                self.buttonsEnabled = false
            }
        }
    }
}

extension ClientListViewController: MultiPeerDelegate {
    func multiPeer(didReceiveData data: Data, ofType type: UInt32) {
        switch type {
        case MessageType.locateResponse.rawValue:
            log("locateResponse")
            break

        case MessageType.clientInfoResponse.rawValue:
            var returnedClientInfo: ClientInfo

            NSKeyedUnarchiver.setClass(ClientInfo.self, forClassName: "ClientInfo")
            if #available(OSX 10.13, *) {
                returnedClientInfo = try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [ClientInfo.self, NSString.self, MCPeerID.self], from: data)! as! ClientInfo
            } else {
                returnedClientInfo = NSKeyedUnarchiver.unarchiveObject(with: data) as! ClientInfo
            }

            log("Received serial number response: \(returnedClientInfo.serialNumber!)")

            if let existingClient = self.currentClients.first(where: { (client) -> Bool in
                client.peer.peerID == returnedClientInfo.peerID ||
                    (client.serialNumber != nil
                        && returnedClientInfo.serialNumber != nil
                        && client.serialNumber! == returnedClientInfo.serialNumber!)
            }) {
                existingClient.serialNumber = returnedClientInfo.serialNumber
                existingClient.status = returnedClientInfo.status ?? "Unknown"

                log("Updated client: \(existingClient.serialNumber!) - \(existingClient.status)")
            } else if let matchedClient = self.pendingClients.first(where: { (client) -> Bool in
                client.peer.peerID == returnedClientInfo.peerID
            }) {
                matchedClient.serialNumber = returnedClientInfo.serialNumber
                matchedClient.status = returnedClientInfo.status ?? "Unknown"

                log("Added client: \(matchedClient.serialNumber!) - \(matchedClient.status)")

                self.addClient(matchedClient)
                self.pendingClients.removeAll { (aClient: Client) in
                    return aClient == matchedClient
                }
            }

            break

        default:
            break
        }
    }

    func multiPeer(connectedPeersChanged peers: [Peer]) {
        log("Peers connected changed: \(peers)")
        if peers.count > 0 {
            peers.forEach { peer in
                if peer.state == .connected {
                    self.pendingClients.append(Client(peer))

                    MultiPeer.instance.send(object: MultiPeer.instance.devicePeerID!, type: MessageType.clientInfoRequest.rawValue, toPeer: peer)
                } else if peer.state == .notConnected {
                    self.currentClients.removeAll { $0.peer.peerID == peer.peerID }
                    self.pendingClients.removeAll { $0.peer.peerID == peer.peerID }
                } else {
                    log("Peer is currently connecting: \(peer.peerID.displayName)")
                }
            }
        } else {
            self.currentClients = []
            self.currentClientsUpdated()
        }
    }
}


