//
//  CommandCell.swift
//  TrainToChangi
//
//  Created by Yong Lin Han on 17/3/17.
//  Copyright © 2017 nus.cs3217.a0139655u. All rights reserved.
//

import UIKit

class CommandCell: UICollectionViewCell {

    private typealias Drawer = UIEntityDrawer

    func setup(command: CommandData) {
        // Without this the previous subviews will still be present
        for view in self.subviews {
            view.removeFromSuperview()
        }

        let buttonOrigin = CGPoint(x: Constants.UI.CommandButton.commandCellLeftPadding, y: 0)
        let button = Drawer.drawCommandButton(command: command, origin: buttonOrigin,
                                              interactive: false)
        button.frame = self.convert(button.frame, to: self)
        self.addSubview(button)

        let labelOrigin = CGPoint(x: button.frame.width + Constants.UI.CommandIndex.commandCellLeftPadding, y: 0)
        guard let label = Drawer.drawCommandMemoryIndex(command: command, origin: labelOrigin) else {
            return
        }

        label.frame = self.convert(label.frame, to: self)
        self.addSubview(label)
    }

}
