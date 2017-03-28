//
// Created by zhongwei zhang on 3/26/17.
// Copyright (c) 2017 nus.cs3217.a0139655u. All rights reserved.
//

import UIKit

extension CGPoint {
    // make CGPoint init less verbose
    // swiftlint:disable variable_name
    init(_ x: CGFloat, _ y: CGFloat) {
        self.x = x
        self.y = y
    }

    func distance(to another: CGPoint) -> CGFloat {
        let dx = x - another.x
        let dy = y - another.y
        return sqrt(dx * dx + dy * dy)
    }
}