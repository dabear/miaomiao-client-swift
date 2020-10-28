//
//  BluetoothSelection.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 17/10/2020.
//  Copyright © 2020 Bjørn Inge Vikhammermo Berg. All rights reserved.
//

import SwiftUI
import MiaomiaoClient
import CoreBluetooth
import Combine

fileprivate struct Defaults {
    static let rowBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let selectedRowBackground = Color.orange.opacity(0.2)
    static let background = Color(UIColor.systemGroupedBackground)
}



// CBPPeripheral's init() method is not available in swift. This is a workaround
// This should be considered experimental and not future proof.
// You should only use this for mock data
/*fileprivate func createCBPeripheral(name: String?) -> CBPeripheral{


    var aClass = NSClassFromString("CBPeripheral")!

    var peripheral = aClass.alloc() as? CBPeripheral
    print("peripheral is: \(peripheral)")

    //peripheral.debugName = name

    //some posts online indicate this is necessary. Not sure about that though
    peripheral!.addObserver(peripheral!, forKeyPath: "delegate", options: .new, context: nil)
    //peripheral.name = name


    return peripheral!
}

//should only be used in swiftui debug area
public extension PeripheralProtocol {
    public var debugName : String? {
        get {
            return globalDebugDatas[self.asStringIdentifier]
        }
        set {
            globalDebugDatas[self.asStringIdentifier] = newValue
        }
    }

}*/




fileprivate struct ListHeader: View {
    var body: some View {
        Text("Select the third party transmitter you want to connect to")
            .listRowBackground(Defaults.background)
            .padding(.top)
        HStack {
            Image(systemName: "link.circle")
            Text("Libre Transmitters")

        }


    }
}



fileprivate struct ListFooter: View {

    var devicesCount = 0
    var body: some View {
        Text("Found devices: \(devicesCount)")

    }
}

fileprivate struct DeviceItem: View {

    var device: SomePeripheral

    @EnvironmentObject var selection: SelectionState

    func getDeviceImage(_ device: SomePeripheral) -> Image{

        //only for artificially created CBPeripherals
        /*if device.debugName?.isEmpty == false, let img = LibreTransmitters.all.randomElement()?.smallImage {
            return Image(uiImage: img)
        }*/

        var image  : UIImage!
        switch device {
        case let .Left(realDevice):
            image = LibreTransmitters.getSupportedPlugins(realDevice)?.first?.smallImage

        case .Right(_):
            image =  LibreTransmitters.all.randomElement()?.smallImage
        }


        return image == nil  ?  Image(systemName: "xmark") : Image(uiImage:image)
    }

    func getRowBackground(device: SomePeripheral)-> Color {

        let deviceId = device.asStringIdentifier


        if let selectedId = selection.selectedStringIdentifier, selectedId == deviceId{
            return Defaults.selectedRowBackground
        }

        return  Defaults.rowBackground

    }




    init(device: SomePeripheral) {
        self.device = device
    }


    var body : some View {
        HStack {
            getDeviceImage(device)
            .frame(width: 100, height: 50, alignment: .leading)

            VStack(alignment: .leading) {
                Text("\(device.name2)")
                    .font(.system(size: 20, weight: .medium, design: .default))

                Text("details")
                Text("details2")

            }

        }
        .listRowBackground(getRowBackground(device: device))
        .onTapGesture(count: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/) {
            print("tapped")
            selection.selectedStringIdentifier = device.asStringIdentifier
        }



    }
}


class SelectionState: ObservableObject {
    @Published var selectedStringIdentifier : String?
}


struct BluetoothSelection: View{


    @EnvironmentObject var selection: SelectionState




    public func getNewDeviceId ()->String? {
        return selection.selectedStringIdentifier
    }

    private var searcher: BluetoothSearchManager!



    static func asHostedViewController()-> UIHostingController<Self> {
        let env = SelectionState()
        //env.selectedStringIdentifier = UserDefaults.standard.preSelectedDevice

        print("BluetoothSelection initiated with selectedIdentifer: \(env.selectedStringIdentifier)")

        return UIHostingController(rootView: self.init().environmentObject(env) as! BluetoothSelection)
    }

    // Should contain all discovered and compatible devices
    // This list is expected to contain 10 or 20 items at the most
    @State var allDevices = [SomePeripheral]()



    var nullPubliser : Empty<CBPeripheral, Never>!
    var debugMode = false

    init(debugMode : Bool = false) {

        self.debugMode = debugMode

        if debugMode {
            allDevices = Self.getMockData()
            nullPubliser = Empty<CBPeripheral, Never>()

        }
        else {

            self.searcher = BluetoothSearchManager(discoverDelegate: nil)
        }


    }


    var list : some View {
        List {
            Section(){
                ListHeader()
            }
            Section(){
                ForEach(allDevices) { device in
                    DeviceItem(device: device)

                }
            }
            Section{
                ListFooter(devicesCount: allDevices.count)
            }
        }
        .onAppear {
            //devices = Self.getMockData()
            if debugMode {
                allDevices = Self.getMockData()

            }

        }
    }


    var body: some View {

        if debugMode {
            list
                .onReceive(nullPubliser) { (device) in
                    print("nullpublisher received element!?")
                    //allDevices.append(SomePeripheral.Left(device))
                }

        } else {

            list
                .onReceive(searcher.passThrough) { (newDevice) in
                    print("received searcher passthrough")

                    let alreadyAdded = allDevices.contains{ (existingDevice) -> Bool in
                        existingDevice.asStringIdentifier == newDevice.asStringIdentifier
                    }
                    if !alreadyAdded {
                        allDevices.append(SomePeripheral.Left(newDevice))
                    }

                }
        }
    }






}

extension BluetoothSelection {
    static func getMockData() -> [SomePeripheral]{

        [
            SomePeripheral.Right(MockedPeripheral(name: "device1")),
            SomePeripheral.Right(MockedPeripheral(name: "device2")),
            SomePeripheral.Right(MockedPeripheral(name: "device3")),
            SomePeripheral.Right(MockedPeripheral(name: "device4"))

        ]
    }
}

struct BluetoothSelection_Previews: PreviewProvider {





    static var previews: some View {
        var testData = SelectionState()
        testData.selectedStringIdentifier = "device4"
        return BluetoothSelection(debugMode: true).environmentObject(testData)
    }
}

