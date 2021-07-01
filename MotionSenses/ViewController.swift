//
//  ViewController.swift
//  MotionSenses
//
//  Created by Phước Trịnh on 21.6.2021.
//


import UIKit
import CoreBluetooth


class ViewController: UIViewController {
    
    var blePeripheral = BLEPeripheralManager()
    var startButtonIsActive = false
    
    private var oneFingerButtonState: UInt8 = 0b00000000
    private var twoFingersButtonState: UInt8 = 0b00000000
    
    @IBOutlet weak var oneFingerButton: UIButton!
    @IBOutlet weak var twoFingersButton: UIButton!
    @IBAction func oneFingerDown(_ sender: Any) {
        print("One finger down")
        oneFingerButtonState = 0b00000001
        setHoldState(primaryButton: oneFingerButton, secondaryButton: twoFingersButton)
    }
    
    @IBAction func oneFingerRelease(_ sender: Any) {
        print("One finger released")
        oneFingerButtonState = 0b00000000
        setReleaseState(primaryButton: oneFingerButton, secondaryButton: twoFingersButton)
    }
    
    @IBAction func twoFingerDown(_ sender: Any) {
        print("Two fingers down")
        oneFingerButtonState = 0b00000010
        setHoldState(primaryButton: twoFingersButton, secondaryButton: oneFingerButton)
    }
    @IBAction func twoFingersRelease(_ sender: Any) {
        print("Two fingers released")
        oneFingerButtonState = 0b00000000
        setReleaseState(primaryButton: twoFingersButton, secondaryButton: oneFingerButton)
    }
    
    @IBOutlet weak var startServiceButton: UIButton!
    @IBAction func startService(_ sender: Any) {
        if(!startButtonIsActive){
        print("Starting...")
            blePeripheral.startBLEPeripheral()
            //startMonitoringQuaternion()
            //startMonitoringAll()
            startMonitoringRotationRate()
            startButtonIsActive = true
            startServiceButton.setTitle("Stop", for: UIControl.State.normal)
            startServiceButton.setTitleColor(UIColor.red, for: UIControl.State.normal)
        }
        else {
            startButtonIsActive = false
            MotionManager.sharedInstance.stopUpdateDeviceMotionData()
            blePeripheral.stopBLEPeripheral()
            startServiceButton.setTitle("Start", for: UIControl.State.normal)
            startServiceButton.setTitleColor(UIColor.blue, for: UIControl.State.normal)
           
        }
    }
    @IBOutlet weak var motionDataTextView: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        MotionManager.sharedInstance.enableMotionUpdate()
        
        // Do any additional setup after loading the view.
    }
    
    func startMonitoringQuaternion(){
        MotionManager.sharedInstance.quaternionDataUpdated = {(data) in // data = {x,y,z,w}
            print("Button State:\(self.oneFingerButtonState|self.twoFingersButtonState) \nx: \(data.xValue) y: \(data.yValue), z: \(data.zValue),  w: \(data.wValue as Float)")
            self.motionDataTextView.text = "Button State:\(self.oneFingerButtonState|self.twoFingersButtonState)\n Quaternion vector: \nx: \(data.xValue) \ny: \(data.yValue) \nz: \(data.zValue) \nw: \(data.wValue as Float)"
            self.blePeripheral.updateQuaternionValue(buttonState: self.oneFingerButtonState | self.twoFingersButtonState, quaternion: data)
        }
        MotionManager.sharedInstance.startUpdateQuaternionData()
        
    }
    
    func startMonitoringAll(){
        MotionManager.sharedInstance.allDataUpdated = {(accel, gyro, magneto, quaternion) in // data = {x,y,z}
            
            print(" Acceleration \nx: \(accel.xValue) \ny: \(accel.yValue), \nz: \(accel.zValue) ")
            print(" Gyroscope \nx: \(gyro.xValue) \ny: \(gyro.yValue), \nz: \(gyro.zValue) ")
            print(" Magnetometer \nx: \(magneto.xValue) \ny: \(magneto.yValue), \nz: \(magneto.zValue) ")
            print("Quaternion: \nx: \(quaternion.xValue) y: \(quaternion.xValue) z: \(quaternion.xValue) w: \(quaternion.xValue)   ")
            
            
            self.motionDataTextView.text = "Acceleration\n x: \(accel.xValue) y: \(accel.yValue), z: \(accel.zValue)\n Gyroscope\n x: \(gyro.xValue) y: \(gyro.yValue), z: \(gyro.zValue)\n Magnetometer\n x: \(magneto.xValue) y: \(magneto.yValue), z: \(magneto.zValue)\n Quaternion:\n x: \(quaternion.xValue) y: \(quaternion.xValue) z: \(quaternion.xValue) w: \(quaternion.xValue)   "
            
            self.blePeripheral.updateAllValue(buttonState: self.oneFingerButtonState | self.twoFingersButtonState ,accelData: accel, gyroData: gyro, magneticData: magneto, quaternionData: quaternion)
        }
        MotionManager.sharedInstance.startUpdateAllData()
    }
    
    func startMonitoringRotationRate(){
        MotionManager.sharedInstance.rotationRateDataUpdated = {(data) in // data = {x,y,z,w}
            print("Button State:\(self.oneFingerButtonState|self.twoFingersButtonState) \nx: \(data.xValue) y: \(data.yValue), z: \(data.zValue)")
            self.motionDataTextView.text = "Button State:\(self.oneFingerButtonState|self.twoFingersButtonState)\n Rotation Rate: \nx: \(data.xValue) \ny: \(data.yValue) \nz: \(data.zValue)"
            self.blePeripheral.updateRotationRateValue(buttonState: self.oneFingerButtonState | self.twoFingersButtonState, rotationRate: data)
        }
        MotionManager.sharedInstance.startUpdateRotationRate()
        
    }
    
    func setHoldState(primaryButton: UIButton, secondaryButton: UIButton){
        //For primary button
        primaryButton.backgroundColor = UIColor.red
        
        //For secondary button
        secondaryButton.backgroundColor = UIColor.gray
        secondaryButton.isEnabled = false
    }
    func setReleaseState(primaryButton: UIButton, secondaryButton: UIButton){
        //For primary button
        primaryButton.backgroundColor = UIColor.systemBlue
        
        //For secondary button
        secondaryButton.backgroundColor = UIColor.systemBlue
        secondaryButton.isEnabled = true
    }
    
    
}

