//
//  RandomNumberGenerator.swift
//  AR-Jellyfish
//
//  Created by Tom on 30/01/2018.
//  Copyright © 2018 Tom. All rights reserved.
//

import Foundation
import UIKit

class RandomNumberGenerator
{

    func randomTimeInterval(time: Int, minTime: Int) -> Int
    {
        let timeInterval = Int(arc4random_uniform(UInt32(time)) + UInt32(minTime))

        return timeInterval
    }
}
