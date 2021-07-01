
//  BLEPeripheral.swift
//  MotionPeripheral
//
//  Created by Phước Trịnh on 18.6.2021.
//

import Foundation
import CoreBluetooth


protocol BLEPeripheralProtocol {
    func BlueToothStatus(peripheral: CBPeripheralManager)
}

class BLEPeripheralManager : NSObject, CBPeripheralManagerDelegate {

//  BLE Properties
    //  Service and characteristics UUID(CUUID)
    let motionserviceCBUUID = "1F8EBBAA-3816-4FFC-B268-362337C14297"
    let enablerCUUID = "781C6FE9-23FB-4D05-856A-EF10CA348EDF"
//    Processed data from sensor
    let allMotionCUUID = "E5477E42-3ED4-41A9-B377-C8C83D9D7145" 
//    Quaternion data from Core Motion
    let quaternionCBUUID = "DC0A1798-EDB0-4E8D-939A-52EEEA4F7379"
//    Processed rotation rate from sensor
    let rotationRateUUID = "15BFB9D0-421C-42FF-88B7-374345AC2F16"
    

    var notifyCharac: CBMutableCharacteristic? = nil
    var notifyCentral: CBCentral? = nil
    var cpt = 0
    
    // timer used to retry to scan for peripheral, when we don't find it
    var notifyValueTimer: Timer?
    
    var peripheral : CBPeripheral? = nil
    var peripheralManager : CBPeripheralManager! = nil
    var motionService : CBService? = nil
    
    var createdService : CBService? = nil
    var serviceName = "MoSes" //Motion senses
    var powerOn = false
    
    var quaternionCharacteristic: CBMutableCharacteristic!
    var allMotionCharacteristic: CBMutableCharacteristic!
    var rotationRateCharacteristic: CBMutableCharacteristic!

    // timer used to retry to scan for peripheral, when we don't find it
    var rescanTimer: Timer?
    
    var delegate: BLEPeripheralProtocol?
    
    
    
    
    func startBLEPeripheral(){
        print("start BLE service")
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func stopBLEPeripheral(){
        print("Stop services")
        self.peripheralManager?.removeAllServices()
        self.peripheralManager?.stopAdvertising()
        
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager){
        print("Did update state")
        if(peripheral.state == .poweredOn){
            self.powerOn = true
            self.startServices()
        }
        else {
            self.powerOn = true
            self.stopBLEPeripheral()
            print("Cannot create service")
        }
        
        // Call delegate for parent (viewController ???)
        //Tools.sendNotification(name: "BlueToothStatusUpdate", objectName: "peripheral", object: peripheral)
        
        // Send the status to delegate subscribed
//        if delegate != nil {
//            delegate?.BlueToothStatus(peripheral: peripheral)
//        }

    }
    
    func startServices(){
        print("Starting service")
        
        // Read characteristic
        let enablerCBUUID = CBUUID(string: enablerCUUID)
        let properties: CBCharacteristicProperties = [.read, .notify ] //.notify,
        let enablerCharacteristic = CBMutableCharacteristic(type: enablerCBUUID, properties: properties, value: nil, permissions: .readable)
        
        // quaternion characteristic
        let quaternionCBUUID = CBUUID(string: quaternionCBUUID)
        quaternionCharacteristic = CBMutableCharacteristic(type: quaternionCBUUID, properties: [.notify, .read ], value: nil, permissions: .readable)
        
        // all motion data characteristic
        let allMotionCBUUID = CBUUID(string: allMotionCUUID)
        allMotionCharacteristic = CBMutableCharacteristic(type: allMotionCBUUID, properties: [.notify, .read], value: nil, permissions: .readable)
        
        // rotaion rate data characteristic
        let rotationRateCBUUID = CBUUID(string: rotationRateUUID)
        rotationRateCharacteristic = CBMutableCharacteristic(type: rotationRateCBUUID, properties: [.notify, .read], value: nil, permissions: .readable)
        
        // Define service
        let serviceCBUUID = CBUUID(string: motionserviceCBUUID)
        let service = CBMutableService(type: serviceCBUUID, primary: true)
        
        // Create the service, add the characteristic to it
        service.characteristics = [enablerCharacteristic, allMotionCharacteristic, quaternionCharacteristic, rotationRateCharacteristic]
        motionService = service
        
        // Push to manager
        peripheralManager?.add(service)
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?){
       
        if let error = error {
                print("Add service failed: \(error.localizedDescription)")
            }
        else {
            motionService = service
        }
            print("Services are added")
        let advertisement: [String : Any] = [CBAdvertisementDataLocalNameKey: self.serviceName,
                                                         //CBAdvertisementDataManufacturerDataKey : manufacturerData,
                                             CBAdvertisementDataServiceUUIDsKey : [service.uuid],
                                            ]
                    // start the advertisement
                    self.peripheralManager.startAdvertising(advertisement)
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager,
                                                  error: Error?){
            if let error = error {
                print(("Error while advertising: \(error.localizedDescription)"))
            }
            else {
                print("adversiting done. no error")
            }
        }
    func peripheralManager(_ peripheral: CBPeripheralManager,
                               didReceiveRead request: CBATTRequest) {
            
        print("CB Central manager request from central: \(request)")
        
            
        }
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("peripheralManager didSubscribeTo characteristic :\n" + characteristic.uuid.uuidString)
        if(characteristic.uuid.uuidString == allMotionCUUID || characteristic.uuid.uuidString == quaternionCBUUID){
            self.notifyCharac = characteristic as? CBMutableCharacteristic
            self.notifyCentral = central
            
            // start a timer, which will update the value, every xyz seconds.
            self.notifyValueTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector:
                                                            #selector(self.notifyValue), userInfo: nil, repeats: true)
        }
        
    }
    
    
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
           print("CB Central Manager request write from central: ")

           if requests.count > 0 {
               let str = NSString(data: requests[0].value!, encoding:String.Encoding.utf8.rawValue)!
               print("value sent by central Manager :  \(String(describing: str))")
           }
       }
    
    func updateQuaternionValue( buttonState: UInt8, quaternion: MotionData){
        // Acceleration Data
        var data = Data(buttonState.bytes)
        data.append(Data(quaternion.xValue.bytes))
        data.append(Data(quaternion.yValue.bytes))
        data.append(Data(quaternion.zValue.bytes))
        data.append(Data(quaternion.wValue.bytes))
        
        peripheralManager.updateValue(data, for: quaternionCharacteristic, onSubscribedCentrals: nil)
     }
    
    func updateRotationRateValue( buttonState: UInt8, rotationRate: MotionData){
        // Acceleration Data
        var data = Data(buttonState.bytes)
        data.append(Data(rotationRate.xValue.bytes))
        data.append(Data(rotationRate.yValue.bytes))
        data.append(Data(rotationRate.zValue.bytes))
        
        
        peripheralManager.updateValue(data, for: rotationRateCharacteristic, onSubscribedCentrals: nil)
     }
    
    func updateAllValue(buttonState: UInt8, accelData: MotionData, gyroData: MotionData, magneticData: MotionData, quaternionData: MotionData ) {
        
        //Unbiased motion data from the device
        var data = Data(buttonState.bytes)
        data.append(Data(accelData.xValue.bytes))
        data.append(Data(accelData.yValue.bytes))
        data.append(Data(accelData.zValue.bytes))
        
        //Rotation rate
        data.append(Data(gyroData.xValue.bytes))
        data.append(Data(gyroData.yValue.bytes))
        data.append(Data(gyroData.zValue.bytes))
        
        //Magnectic data
        data.append(Data(magneticData.xValue.bytes))
        data.append(Data(magneticData.yValue.bytes))
        data.append(Data(magneticData.zValue.bytes))
        
        //Quaternion data
        data.append(Data(quaternionData.xValue.bytes))
        data.append(Data(quaternionData.yValue.bytes))
        data.append(Data(quaternionData.zValue.bytes))
        data.append(Data(quaternionData.wValue.bytes))
    
        peripheralManager.updateValue(data, for: allMotionCharacteristic, onSubscribedCentrals: nil)
     }
    
    
    
    func respond(to request: CBATTRequest, withResult result: CBATTError.Code) {
        print("response requested")
    }
    
    @objc func notifyValue() {
        print("Notify a value to central manager")
        
        // Set the data to notify
        let text = " Hmmm " + String(describing: cpt)
        let data: Data = text.data(using: String.Encoding.utf16)!
        cpt += 1
        
        
        // update the value, which will generate a notification event on central side
        peripheralManager.updateValue(data, for: self.notifyCharac!, onSubscribedCentrals: [self.notifyCentral!])
        
    }
}
// Extension for converting double to bytes
extension Float {
   var bytes: [UInt8] {
       withUnsafeBytes(of: self, Array.init)
   }
}

// Extension for converting Int8 to bytes
extension UInt8 {
   var bytes: [UInt8] {
       withUnsafeBytes(of: self, Array.init)
   }
}
