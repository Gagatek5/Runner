//
//  GameTimeEvents.swift
//  FlappyBird
//
//  Created by Tom on 03/02/2018.
//  Copyright © 2018 Fullstack.io. All rights reserved.
//

import Foundation

class GameTimeEvents {
    
    func afterTimeSpeedInc(speed: Int)-> Int {
        var newSpeed = speed
        if speed <= 40 {
            newSpeed += 2
            return newSpeed
        }
        
        return newSpeed
    }
    
    func afterTimePointsInc() {
        
    }
    
    func afterTimeObstacleShowing() {
        
    }
    
}
