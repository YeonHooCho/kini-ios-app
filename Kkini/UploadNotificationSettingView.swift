import SwiftUI

// MARK: - 업로드 알림 상세 설정 뷰
struct UploadNotificationSettingView: View {
    var onBack: () -> Void
    
    // 💡 3가지 핵심 활동 알림 토글 영구 저장 (기본값 ON)
    @AppStorage("notifyOnMealUpload") private var notifyOnMealUpload: Bool = true
    @AppStorage("notifyOnChatMessage") private var notifyOnChatMessage: Bool = true
    @AppStorage("notifyOnNewspaper") private var notifyOnNewspaper: Bool = true
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 상단 헤더
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.appTextBrown)
                            .frame(width: 30, height: 30, alignment: .leading)
                    }
                    Spacer()
                    Text("업로드 알림 설정")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color.appTextBrown)
                    Spacer()
                    Spacer().frame(width: 30)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.appHeader)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        
                        Text("가족 활동 알림")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.appTextBrown.opacity(0.8))
                            .padding(.top, 16)
                            .padding(.horizontal, 4)
                        
                        // 알림 옵션 리스트 카드
                        VStack(spacing: 0) {
                            
                            // 1. 식탁 사진 업로드 알림
                            notificationToggleRow(
                                icon: "camera",
                                title: "식탁 사진 공유 알림",
                                description: "가족이 새로운 식사 사진을 올렸을 때 알림을 받습니다.",
                                isOn: $notifyOnMealUpload
                            )
                            
                            Divider()
                                .background(Color.appTextBrown.opacity(0.12))
                                .padding(.horizontal, 16)
                            
                            // 2. 가족 대화 알림
                            notificationToggleRow(
                                icon: "bubble.left.and.bubble.right",
                                title: "가족 채팅 알림",
                                description: "가족들이 채팅방에 새 메시지를 남겼을 때 알림을 받습니다.",
                                isOn: $notifyOnChatMessage
                            )
                            
                            Divider()
                                .background(Color.appTextBrown.opacity(0.12))
                                .padding(.horizontal, 16)
                            
                            // 3. 끼니 신문 발행 알림
                            notificationToggleRow(
                                icon: "newspaper",
                                title: "끼니 신문 발행 알림",
                                description: "어제 식탁을 요약한 신문이 도착했을 때 알림을 받습니다.",
                                isOn: $notifyOnNewspaper
                            )
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                        
                        // 하단 안내 문구
                        Text("• 기기 자체의 '설정 > 끼니 > 알림'이 켜져 있어야 알림을 정상적으로 수신할 수 있습니다.")
                            .font(.system(size: 12))
                            .foregroundColor(Color.appTextBrown.opacity(0.6))
                            .padding(.horizontal, 8)
                            .lineSpacing(4)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // 알림 토글 행 컴포넌트
    private func notificationToggleRow(icon: String, title: String, description: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color(red: 254/255, green: 242/255, blue: 228/255))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(Color.appTextBrown)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.appTextBrown)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Color.appTextBrown.opacity(0.65))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.appActiveTab)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
}
