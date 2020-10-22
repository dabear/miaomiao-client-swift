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

fileprivate let defaultBackground = Color(UIColor.systemGroupedBackground)


fileprivate struct ListHeader: View {
    var body: some View {
        Text("Select the third party transmitter you want to connect to")
            .listRowBackground(defaultBackground)
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

fileprivate struct DeviceItem<T>: View where T:PeripheralProtocol & Hashable & Identifiable{

    var device: T

    @EnvironmentObject var selection: SelectionState

    func getDeviceImage(_ device: PeripheralProtocol) -> Image{
        if let image = LibreTransmitters.getSupportedPlugins(device)?.first?.smallImage {
            return Image(uiImage: image)
        }

        return Image(uiImage: LibreTransmitters.all[1].smallImage!)
        return Image(systemName: "xmark")
    }

    func getRowBackground(device: T)-> Color {

        if let selectedId = selection.selectedStringIdentifier, selectedId == device.asStringIdentifier{
            return selectedRowBackground
        }
        return  defaultRowBackground

    }

    private let defaultRowBackground = Color(UIColor.secondarySystemGroupedBackground)
    private let selectedRowBackground = Color.orange.opacity(0.2)


    init(device: T) {
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
        env.selectedStringIdentifier = UserDefaults.standard.preSelectedDevice

        print("BluetoothSelection initiated with selectedIdentifer: \(env.selectedStringIdentifier)")

        return UIHostingController(rootView: self.init().environmentObject(env) as! BluetoothSelection)
    }


    //@State var devices = [CBPeripheral]()

    var devicesReceiver : ConcreteBluetoothSearchDelegate! = ConcreteBluetoothSearchDelegate()

    init() {
        self.searcher = BluetoothSearchManager(discoverDelegate: devicesReceiver)
    }


    var body: some View {
        List {
            Section(){
                ListHeader()
            }
            Section(){
                ForEach(devicesReceiver.allDevices) { device in
                    DeviceItem(device: device)

                }
            }
            Section{
                ListFooter(devicesCount: devicesReceiver.allDevices.count)
            }
        }
        .onAppear {
            //devices = Self.getMockData()
            
            
        }
    }


    static func getMockData() -> [MockedPeripheral]{
        var m2 = MockedPeripheral(identifier: 2)

        return [
            m2,
            MockedPeripheral(identifier: 1),
            MockedPeripheral(identifier: 3),
            MockedPeripheral(identifier: 4)

        ]
    }
}

struct BluetoothSelection_Previews: PreviewProvider {





    static var previews: some View {
        var testData = SelectionState()
        testData.selectedStringIdentifier = "3"
        return BluetoothSelection().environmentObject(testData)
    }
}

