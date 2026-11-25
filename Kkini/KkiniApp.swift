import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // 1. 알림 권한 델리게이트 등록
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            print("푸시 알림 권한 허용 여부: \(granted)")
        }
        
        // 2. APNs 원격 알림 시스템 등록
        application.registerForRemoteNotifications()
        
        // 3. FCM 메시징 델리게이트 등록
        Messaging.messaging().delegate = self
        
        return true
    }
    
    // APNs 디바이스 토큰 등록 성공 시 Firebase에 전달
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // FCM 등록 토큰 수신 시 호출
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("✅ 발급된 내 기기 FCM 토큰:\n\(token)")
        
        // 토큰 영구 저장 및 서버 업데이트
        UserDefaults.standard.set(token, forKey: "kkini_fcm_token")
        FirebaseManager.shared.updateFCMToken(token: token)
    }
    
    // 앱이 화면에 켜져 있는 상태(Foreground)에서도 상단 배너 알림 표시
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

@main
struct KkiniApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // 스플래시 화면 표시 여부 상태값
    @State private var showSplash: Bool = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                // ContentView 내부에 selectedTab 기본값이 2(식탁 업로드)로 설정되어 있습니다.
                ContentView()
                
                // 1초간 화면 최상단에 노출된 뒤 부드럽게 페이드아웃되는 스플래시 화면
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(999)
                }
            }
            .onAppear {
                // 1.0초 노출 후 0.45초 동안 페이드아웃 전환
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
