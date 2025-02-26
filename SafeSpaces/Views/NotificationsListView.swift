import SwiftUI

struct Notification: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let timestamp: Date
}

struct NotificationsListView: View {
    @StateObject private var notificationHandler = NotificationHandler.shared

    var body: some View {
        NavigationView {
            List(notificationHandler.notifications) { notification in
                HStack {
                    VStack(alignment: .leading) {
                        Text(notification.title)
                            .font(.headline)
                        Text(notification.body)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text(timeAgo(notification.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 5)
            }
            .navigationTitle("Notifications")
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NotificationsListView()
}
