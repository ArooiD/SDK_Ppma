//
//  DeviceService.swift
//  MedicalApp
//
//  Created by Денис Комиссаров on 06.06.2023.
//

import Foundation
import CoreBluetooth

fileprivate class _baseCallback: DeviceCallback {
    func onExploreDevice(mac: UUID, atr: Atributes, value: Any){}
    
    func onStatusDevice(mac: UUID, status: BluetoothStatus){ }
    
    func onSendData(mac: UUID, status: PlatformStatus){ }
    
    func onExpection(mac: UUID, ex: Error){ }
    
    func onDisconnect(mac: UUID, data: ([Atributes: Any], Array<Measurements>)){}
    
    func findDevice(peripheral: DisplayPeripheral){}
    
    func searchedDevices(peripherals: [DisplayPeripheral]){}
}

private var instanceDS: DeviceService? = nil

public class DeviceService {
    internal var deviceService: DeviceService?
    
    internal var _login: String = ""
    
    internal var _password: String = ""
    
    private var _tag: String = ""
    
    private var _test: Bool = false
    
    internal var im: InternetManager
    
    private var _callback: DeviceCallback = _baseCallback()
    
    public static func getInstance() -> DeviceService {
        if(instanceDS == nil) {
            return DeviceService()
        }
        else{
            return instanceDS!
        }
    }
    
    init(){
        BLEManager.getSharedBLEManager().initCentralManager(queue: DispatchQueue.global(), options: nil)
        im = InternetManager(login: _login, password: _password, debug: _test, callback: _callback)
        instanceDS = self
    }
    
    public init(login: String, password: String, callbackFunction: DeviceCallback){
        BLEManager.getSharedBLEManager().initCentralManager(queue: nil, options: nil)
        _login = login
        _password = password
        _callback = callbackFunction
        im = InternetManager(login: _login, password: _password, debug: _test, callback: callbackFunction)
        instanceDS = self
    }
    
    public func changeCredentials(login: String, password: String){
        _login = login
        _password = password
        im = InternetManager(login: _login, password: _password, debug: _test, callback: _callback)
        instanceDS = self
    }
    
    public func changeCallback(callbackFunction: DeviceCallback){
        _callback = callbackFunction
    }
    
    public func connectToDevice(connectClass: ConnectClass, device: DisplayPeripheral){
        connectClass.callback = self._callback
        let _identifier: UUID = device.peripheral!.identifier
        if(connectClass is AndTonometr){
            if(!AndTonometr.activeExecute) {
                DispatchQueue.global().async {
                    connectClass.connect(device: device.peripheral!)
                }
            }
            else {
                self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.Connected)
            }
            return
        }
        if(connectClass is EltaGlucometr){
            if(connectClass.cred == nil){
                self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.NotCorrectPin)
            }else{
                if(!EltaGlucometr.activeExecute) {
                    DispatchQueue.global().async {
                        connectClass.connect(device: device.peripheral!)
                    }
                }
                else {
                    self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.Connected)
                }
            }
            return
        }
        self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.InvalidDeviceTemplate)
    }
    
    public func search(connectClass: ConnectClass, timeOut: UInt32){
        DispatchQueue.global().async {
            connectClass.callback = self._callback
            connectClass.search(timeout: timeOut)
        }
    }
    
    public func setLogTag(tag: String) {
        _tag = tag
    }
        
    public func toTest() {
        _test = true
        im = InternetManager(login: _login, password: _password, debug: _test, callback: _callback)
        instanceDS = self
    }
    public func toProd() {
        _test = false
        im = InternetManager(login: _login, password: _password, debug: _test, callback: _callback)
        instanceDS = self
    }
}

public struct DisplayPeripheral: Hashable {
    var peripheral: CBPeripheral?
    var lastRSSI: NSNumber?
    var isConnectable: Bool?
    var localName: String?
    
    public func hash(into hasher: inout Hasher) { }

    public static func == (lhs: DisplayPeripheral, rhs: DisplayPeripheral) -> Bool {
        if (lhs.peripheral! == rhs.peripheral) { return true }
        else { return false }
    }
}
public struct Measurements{
    internal var data: [Atributes: Any] = [:]
    
    init() {
        data = [Atributes: Any]()
    }
    
    public mutating func add(atr: Atributes, value: Any){
        data.updateValue(value, forKey: atr)
    }
    
    public func get() -> [Atributes: Any]?{
        return data
    }
    
    public func get(atr: Atributes) -> Any?{
        return data[atr]
    }
    
}
