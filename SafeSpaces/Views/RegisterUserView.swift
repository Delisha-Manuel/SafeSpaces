import Foundation
import SwiftUI

struct RegisterUserView: View {
    @State var nameText = ""
    @State var phoneText = ""
    @Environment(\.dismiss) var dismiss: DismissAction
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Welcome to SafeSpaces!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("This app helps people stay safe by ensuring they are in the expected safe spaces at the designated times. If they are unexpectedly taken out of the safe spaces, their designated guardian is notified and they can get help promptly.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.trailing)
            
            
            Text("")

            Text("You need to register to be able to use the safety features of this app. Please allow this app to access your location at all times and to send you notifications.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.trailing)
            
            HStack {
                Text("Name:")
                
                TextField("Enter name here", text: $nameText)
                    .font(.subheadline)
                    .padding(12)
                    .background(.white)
                    .padding()
                    .shadow(radius:10)
            }
            HStack{
                Text("Phone Number:")
                
                TextField("Enter Phone # Here", text: $phoneText)
                    .font(.subheadline)
                    .padding(12)
                    .background(.white)
                    .padding()
                    .shadow(radius:10)
                    .keyboardType(.decimalPad)
                
            }
            Button(action:{
            }) {
                Text("Register")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 170, height: 48)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding()
                    .onTapGesture {
                        AppData.data.me.name = nameText
                        AppData.data.me.phone = phoneText
                        AppData.data.save()
                        UIApplication.shared.registerForRemoteNotifications()
                        dismiss()
                    }
            }
        }.padding()
        
    }
}

#Preview {
    RegisterUserView()
}
