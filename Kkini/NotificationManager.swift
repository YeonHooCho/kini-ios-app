import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    /// 매일 특정 시각(기본: 오후 8시) 알림 등록
    func scheduleDailyMealReminder(hour: Int = 20, minute: Int = 0) {
        let center = UNUserNotificationCenter.current()
        
        // 기존 예약 제거 후 재등록
        center.removePendingNotificationRequests(withIdentifiers: ["dailyMealReminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "끼니"
        content.body = "오늘 가족들과 식사는 챙기셨나요? 오늘의 식탁 사진을 공유해보세요! 🍚"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        // 매일 해당 시간에 반복 트리거
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyMealReminder", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("8시 알림 등록 실패: \(error.localizedDescription)")
            } else {
                print("매일 \(hour)시 \(minute)분 로컬 알림 예약 완료")
            }
        }
    }
    
    /// 알림 토글 OFF 시 예약 취소
    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyMealReminder"])
    }
}
