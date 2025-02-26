import Combine
import SwiftUI
import MapKit

struct ContentView: View {
    
    @State private var selectedTab: Tab = .map
    @State private var showRegisterUser = AppData.data.me.name == ""
    
    
    init() {
       UITabBar.appearance().isHidden = true
    }

    var body: some View {
        ZStack {
            VStack {
                TabView(selection: $selectedTab){
                    LocationMapView()
                        .tag(Tab.map)
                    SafeSpacesListView()
                       .tag(Tab.spaces)
                    NotificationsListView()
                        .tag(Tab.notifications)
                }
            }
            .onChange(of: AppData.data.me.name, { oldValue, newValue in
                showRegisterUser = newValue == ""
            })
            .sheet(isPresented: $showRegisterUser, content: {
                RegisterUserView()
            })

            VStack {
                Spacer()
                TabBarView(selectedTab: $selectedTab)
            }
        }
    }
}
    
    
#Preview {
    ContentView()
}
