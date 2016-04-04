//
//  CruncherPortTableViewCell.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 11/3/15.
//
//

import UIKit

enum CCPortConnectionState {
    case NotConnected
    case Connecting
    case Connected
}

class Port {
    var name: String = ""
    var connection: CCPortConnectionState = CCPortConnectionState.Connected
}

class InputPort: Port {}
class OutputPort: Port {}

class CruncherPortTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configureCell(port: Port) {
        let image: UIImage
        switch (port.connection) {
        case .Connected:
            image = UIImage(named: "ConnectedIndicator")!
            break
        case .Connecting:
            image = UIImage(named: "ConnectingIndicator")!
            break
        case .NotConnected:
            image = UIImage(named: "EmptyIndicator")!
            break
        }
        if let _ = port as? InputPort {
            self.imageView?.image = image
        } else {
            self.accessoryView = UIImageView(image: image)
            self.accessoryView?.frame = CGRectMake(0, 0, self.frame.size.height, self.frame.size.height)
        }
        
        self.layer.borderWidth = 1;
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    public var port: Port?
    
}
