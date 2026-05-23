import UserNotifications
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent
        guard let best = bestAttemptContent else {
            contentHandler(request.content)
            return
        }
        #if canImport(FirebaseMessaging)
        Messaging.serviceExtension().populateNotificationContent(
            best, withContentHandler: contentHandler
        )
        #else
        contentHandler(best)
        #endif
    }

    override func serviceExtensionTimeWillExpire() {
        if let h = contentHandler, let b = bestAttemptContent { h(b) }
    }
}
