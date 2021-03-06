//
// Created by zhongwei zhang on 3/22/17.
// Copyright (c) 2017 nus.cs3217.a0139655u. All rights reserved.
//

import UIKit

struct Memory {
    typealias CGP = CGPoint

    // Specify how the memory are laid out in each level. Each CGPoint is the center of the memory slot.
    // Add case and specify in `locations` to add more memory layouts.
    enum Layout {
        case twoByOne, twoByTwo, threeByThree

        var locations: [CGPoint] {
            let centerX = Constants.ViewDimensions.centerX, centerY = Constants.ViewDimensions.centerY
            let boxWidth = Constants.Memory.size.width, boxHeight = Constants.Memory.size.height

            switch self {

            case .twoByOne:
                return [CGP(centerX - boxWidth / 2, centerY), CGP(centerX + boxWidth / 2, centerY)]

            case .twoByTwo:
                let x1 = centerX - boxWidth / 2, x2 = centerX + boxWidth / 2
                let y1 = centerY - boxHeight / 2, y2 = centerY + boxHeight / 2

                return [CGP(x1, y1), CGP(x2, y1),
                        CGP(x1, y2), CGP(x2, y2)]

            case .threeByThree:
                let x1 = centerX - boxWidth, x2 = centerX, x3 = centerX + boxHeight
                let y1 = centerY - boxHeight, y2 = centerY, y3 = centerY + boxHeight

                return [CGP(x1, y1), CGP(x2, y1), CGP(x3, y1),
                        CGP(x1, y2), CGP(x2, y2), CGP(x3, y2),
                        CGP(x1, y3), CGP(x2, y3), CGP(x3, y3)]
            }
        }
    }

    // specifies person's actions involving memory, for the game scene
    enum Action {
        case put                    // put payload down to the memory slot
        case get                    // pick up payload from memory slot
        case compute(expected: Int) // calculate using payload on the memory slot
    }
}
