//
//  ContentView.swift
//  SwiftUITester
//
//  Created by Bjørn Inge Berg on 14/03/2020.
//  Copyright © 2020 Bjørn Inge Vikhammermo Berg. All rights reserved.
//

import SwiftUI
import SwiftUICharts


struct ContentView: View {
    var body: some View {
        TabView {

            MainContentView()
            .tabItem {
                Text("Glucose")
                Image(systemName: "heart.circle")
            }

            SettingsContentView()
            .tabItem {
                Text("Settings")
                Image(systemName: "list.dash")
            }

        }
    }
}

var glucose = 5

struct MainContentView: View {
    var body: some View {
        VStack {
            Text("Glucose: \(glucose)")
            LineView(data: [8,23,54,32,12,37,7,23,439], title: nil, legend: nil)
        }
    }
}

struct SettingsContentView: View {
    var body: some View {
        Text("Some Settings content view")

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}




