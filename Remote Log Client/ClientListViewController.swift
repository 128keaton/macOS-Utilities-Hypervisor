//
//  ClientListViewController.swift
//  Remote Log Client
//
//  Created by Keaton Burleson on 8/28/19.
//  Copyright © 2019 Keaton Burleson. All rights reserved.
//

import Foundation
import Cocoa
import MultiPeer
import MultipeerConnectivity

class ClientListViewController: NSViewController {
    @IBOutlet private var tableView: NSTableView!
    @IBOutlet private var logButton: NSButton!
    @IBOutlet private var sendBeepButton: NSButton!
    @IBOutlet private var sendScreenSharingRequestButton: NSButton!

    private var currentClients: [Client] = []
    private var selectedClient: Client? = nil

    private let queue = DispatchQueue(label: "com.er2.macOS-Utilities.RemoteLogClient.ClientQueue")

    override func viewDidLoad() {
        super.viewDidLoad()

        self.buttonsEnabled = false

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
            self.sendBeepButton.isEnabled = newValue
            self.sendScreenSharingRequestButton.isEnabled = newValue
            self.logButton.isEnabled = newValue
        }
        get {
            return (self.sendBeepButton.isEnabled && self.sendScreenSharingRequestButton.isEnabled && self.logButton.isEnabled)
        }
    }

    @IBAction private func sendScreenSharingRequest(_ sender: NSButton) {
    }

    @IBAction private func sendBeepRequest(_ sender: NSButton) {
        guard let validSelectedClient = self.selectedClient else {
            return
        }

        MultiPeer.instance.send(object: MultiPeer.instance.devicePeerID!, type: MessageType.locateRequest.rawValue, toPeer: validSelectedClient.peer)
    }

    @IBAction private func viewLog(_ sender: NSButton) {
        guard let validSelectedClient = self.selectedClient else {
            return
        }

        NSWorkspace.shared.open(URL(string: "http://\(validSelectedClient.ipAddress):8080")!)
        print("view Log")
    }
}

extension ClientListViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.currentClients.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if self.currentClients.indices.contains(row) {
            let client = self.currentClients[row]

            let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView


            if tableColumn!.identifier.rawValue == "modelIdentifier" {
                cell?.textField?.stringValue = client.modelIdentifier
            } else {
                cell?.textField?.stringValue = client.ipAddress
            }
            
            return cell
        }
        
        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = self.tableView.selectedRow
        print(selectedRow)
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
}

extension ClientListViewController: MultiPeerDelegate {
    func multiPeer(didReceiveData data: Data, ofType type: UInt32) {
        switch type {
        case MessageType.locateResponse.rawValue:
            print("locateResponse")
            break

        case MessageType.clientInfoResponse.rawValue:
            var returnedClientInfo: ClientInfo

            NSKeyedUnarchiver.setClass(ClientInfo.self, forClassName: "ClientInfo")
            if #available(OSX 10.13, *) {
                returnedClientInfo = try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [ClientInfo.self, NSString.self, MCPeerID.self], from: data)! as! ClientInfo
            } else {
                returnedClientInfo = NSKeyedUnarchiver.unarchiveObject(with: data) as! ClientInfo
            }

            print("Received serial number response: \(returnedClientInfo.serialNumber!)")

            if let matchedClient = self.currentClients.first(where: { (client) -> Bool in
                client.peer.peerID == returnedClientInfo.peerID
            }) {
                matchedClient.serialNumber = returnedClientInfo.serialNumber
                print("Updated client: \(matchedClient.serialNumber!)")
            }
            break

        default:
            break
        }
    }

    func multiPeer(connectedPeersChanged peers: [Peer]) {
        queue.sync {
            if peers.count > 0 {
                peers.forEach { peer in
                    self.currentClients.removeAll { $0.peer.peerID == peer.peerID }
                    self.currentClients.append(Client(peer))

                    MultiPeer.instance.send(object: MultiPeer.instance.devicePeerID!, type: MessageType.clientInfoRequest.rawValue, toPeer: peer)
                }
            } else {
                self.currentClients = []
            }

        }

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }

    }
}


