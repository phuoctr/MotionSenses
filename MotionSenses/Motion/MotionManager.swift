//
//  MotionManager.swift
//  MotionSenses
//
//  Created by Phước Trịnh on 21.6.2021.
//

import Foundation
import CoreMotion

class MotionManager{
    
    static let sharedInstance = MotionManager()
//    Motion services properties
    var motionManager = CMMotionManager()
    var allDataUpdated: ((MotionData, MotionData, MotionData, MotionData) -> (Void))?
    var quaternionDataUpdated: ((MotionData) -> (Void))?
    var rotationRateDataUpdated: ((MotionData) -> (Void))?
    
    var timer: Timer?
    var updateInterval = 1.0 / 60.0 // 60 Hz
    
    func startUpdateAllData(){
        self.motionManager.deviceMotionUpdateInterval = updateInterval
        self.motionManager.showsDeviceMovementDisplay = true
//        Update motion with referenced north
        self.motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xMagneticNorthZVertical, to: OperationQueue(), withHandler: {
            (motion: CMDeviceMotion?, Error ) -> Void in
            
        })
        
        self.timer = Timer(fire: Date(), interval: updateInterval, repeats: true,
                           block: {(timer) in
                            if let data = self.motionManager.deviceMotion{
                                let accelData = MotionData()
                                let gyroData = MotionData()
                                let magnetoData = MotionData()
                                let quaternionData = MotionData()
                                
                                //User generated data
                                accelData.xValue = Float(data.userAcceleration.x)
                                accelData.yValue = Float(data.userAcceleration.y)
                                accelData.zValue = Float(data.userAcceleration.z)
                                
                                //Rotation rate
                                gyroData.xValue = Float(data.rotationRate.x)
                                gyroData.yValue = Float(data.rotationRate.y)
                                gyroData.zValue = Float(data.rotationRate.z)
                                
                                //Magnetic field vector
                                magnetoData.xValue = Float(data.magneticField.field.x)
                                magnetoData.yValue = Float(data.magneticField.field.y)
                                magnetoData.zValue = Float(data.magneticField.field.z)
                                
                                //Quaternion vector
                                quaternionData.xValue = Float(data.attitude.quaternion.x)
                                quaternionData.yValue = Float(data.attitude.quaternion.y)
                                quaternionData.zValue = Float(data.attitude.quaternion.z)
                                quaternionData.wValue = Float(data.attitude.quaternion.w)
                                
                                self.allDataUpdated?(accelData, gyroData, magnetoData, quaternionData)
                            }
                            
        })
        // Add the timer to the current run loop.
        RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.default)
        
    }
    func startUpdateRotationRate(){
       
        self.motionManager.startDeviceMotionUpdates()
        self.motionManager.deviceMotionUpdateInterval = updateInterval
        self.motionManager.showsDeviceMovementDisplay = true
        self.timer = Timer(fire: Date(), interval: updateInterval, repeats: true,
                           block: { (timer) in
                            if let data = self.motionManager.deviceMotion {
                                // Get the attitude relative to the magnetic north reference frame.
                                let rotationRate: MotionData = MotionData()
                                rotationRate.xValue = Float(data.rotationRate.x)
                                rotationRate.yValue = Float(data.rotationRate.y)
                                rotationRate.zValue = Float(data.rotationRate.z)
                               
                                
                                // Use the motion data in your app.
                                self.rotationRateDataUpdated?(rotationRate)
                                
                                
                            }
                           })
        // Add the timer to the current run loop.
        RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.default)
        
    }
    
    func startUpdateQuaternionData(){
        self.motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xMagneticNorthZVertical, to: OperationQueue(), withHandler: {
            (motion: CMDeviceMotion?, Error ) -> Void in
            
        })
        self.motionManager.deviceMotionUpdateInterval = updateInterval
        self.motionManager.showsDeviceMovementDisplay = true
        self.timer = Timer(fire: Date(), interval: updateInterval, repeats: true,
                           block: { (timer) in
                            if let data = self.motionManager.deviceMotion {
                                // Get the attitude relative to the magnetic north reference frame.
                                let quaternionData: MotionData = MotionData()
                                quaternionData.xValue = Float(data.attitude.quaternion.x)
                                quaternionData.yValue = Float(data.attitude.quaternion.y)
                                quaternionData.zValue = Float(data.attitude.quaternion.z)
                                quaternionData.wValue = Float(data.attitude.quaternion.w)
                                
                                // Use the motion data in your app.
                                self.quaternionDataUpdated?(quaternionData)
                                
                                
                            }
                           })
        // Add the timer to the current run loop.
        RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.default)
    }
    
    func stopUpdateDeviceMotionData(){
        self.motionManager.stopDeviceMotionUpdates()
        self.timer?.invalidate()
        self.timer = nil
    }
}
