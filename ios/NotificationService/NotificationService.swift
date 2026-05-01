import UserNotifications

/// Notification Service Extension that downloads `fcm_options.image`
/// (or `image` / `mutable-content` payload variations) and attaches it
/// to the user-notification before iOS displays it in the system tray.
/// Required for rich pushes when the host app is backgrounded or killed
/// — without an NSE, `apple.imageUrl` is dropped by iOS.
class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttempt: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttempt = (request.content.mutableCopy() as? UNMutableNotificationContent)
        guard let bestAttempt = bestAttempt else {
            contentHandler(request.content)
            return
        }

        let urlString =
            (bestAttempt.userInfo["fcm_options"] as? [String: Any])?["image"] as? String
            ?? bestAttempt.userInfo["image"] as? String
            ?? (bestAttempt.userInfo["aps"] as? [String: Any])?["image"] as? String

        guard let raw = urlString,
              let url = URL(string: raw) else {
            contentHandler(bestAttempt)
            return
        }

        let task = URLSession.shared.downloadTask(with: url) { tempURL, _, _ in
            if let tempURL = tempURL {
                let ext = url.pathExtension.isEmpty ? "jpg" : url.pathExtension
                let dest = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent("nse_\(UUID().uuidString).\(ext)")
                try? FileManager.default.moveItem(at: tempURL, to: dest)
                if let attachment = try? UNNotificationAttachment(identifier: "image", url: dest, options: nil) {
                    bestAttempt.attachments = [attachment]
                }
            }
            contentHandler(bestAttempt)
        }
        task.resume()
    }

    override func serviceExtensionTimeWillExpire() {
        if let bestAttempt = bestAttempt, let handler = contentHandler {
            handler(bestAttempt)
        }
    }
}
