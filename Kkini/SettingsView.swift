import SwiftUI
import UserNotifications

// MARK: - Settings View
struct SettingsView: View {
    var onBack: (() -> Void)? = nil
    
    // 💡 선택된 언어 키 연동
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ko"
    
    @AppStorage("isAIChatSuggestEnabled") private var isAIChatSuggestEnabled: Bool = true
    @AppStorage("isDailyMealReminderEnabled") private var isNotificationEnabled: Bool = true
    @AppStorage("reminderHour") private var reminderHour: Int = 20
    @AppStorage("reminderMinute") private var reminderMinute: Int = 0
    
    @State private var reminderTime: Date = Date()
    @State private var isSystemExpanded: Bool = true
    @State private var isPersonalExpanded: Bool = true
    
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    
    // 상세 화면 전환 상태 변수들
    @State private var showPersonalProfileSetting: Bool = false
    @State private var showAccountManagement: Bool = false
    @State private var showUploadNotificationSetting: Bool = false
    @State private var showAutoQuestionSetting: Bool = false
    @State private var showLanguageSetting: Bool = false // 💡 언어 설정 상세 화면 트리거
    
    // 선택된 언어에 따른 상단 카드 표시 텍스트
    private var languageDisplayText: String {
        switch selectedLanguage {
        case "en":
            return "English"
        case "system":
            return "시스템 기본값"
        default:
            return "한국어 (Korean)"
        }
    }
    
    var body: some View {
        ZStack {
            if showPersonalProfileSetting {
                PersonalProfileSettingView(onBack: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showPersonalProfileSetting = false
                    }
                })
                .transition(.move(edge: .trailing))
            } else if showAccountManagement {
                AccountManagementView(onBack: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAccountManagement = false
                    }
                })
                .transition(.move(edge: .trailing))
            } else if showUploadNotificationSetting {
                UploadNotificationSettingView(onBack: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showUploadNotificationSetting = false
                    }
                })
                .transition(.move(edge: .trailing))
            } else if showAutoQuestionSetting {
                AutoQuestionSettingView(onBack: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAutoQuestionSetting = false
                    }
                })
                .transition(.move(edge: .trailing))
            } else if showLanguageSetting {
                // 💡 언어 설정 상세 화면 연결
                LanguageSettingView(onBack: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showLanguageSetting = false
                    }
                })
                .transition(.move(edge: .trailing))
            } else {
                VStack(spacing: 0) {
                    SettingsHeaderBar(onBack: onBack)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            
                            // MARK: - 1. 핵심 시스템 메뉴 섹션
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("핵심 시스템 메뉴")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Color.appTextBrown)
                                    Spacer()
                                    Text("연동 상태 정상")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.appTextBrown.opacity(0.75))
                                }
                                .padding(.horizontal, 4)
                                
                                VStack(spacing: 0) {
                                    // 언어 설정 카드 행 (터치 시 언어 설정 화면으로 바로 이동)
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showLanguageSetting = true
                                        }
                                    }) {
                                        HStack(spacing: 14) {
                                            Circle()
                                                .fill(Color(red: 254/255, green: 242/255, blue: 228/255))
                                                .frame(width: 44, height: 44)
                                                .overlay(
                                                    Image(systemName: "globe")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(Color.appTextBrown)
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text("언어 설정")
                                                    .font(.system(size: 15, weight: .bold))
                                                    .foregroundColor(Color.appTextBrown)
                                                Text("기록 및 알림 인터페이스 언어")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color.appTextBrown.opacity(0.65))
                                            }
                                            Spacer()
                                            
                                            // 💡 동적 언어 표기 + 이동 chevron
                                            HStack(spacing: 6) {
                                                Text(languageDisplayText)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(Color.appTextBrown)
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(Color.appTextBrown.opacity(0.5))
                                            }
                                        }
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 16)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Divider()
                                        .background(Color.appTextBrown.opacity(0.15))
                                        .padding(.horizontal, 16)
                                    
                                    // 알림 설정
                                    VStack(spacing: 0) {
                                        HStack(spacing: 14) {
                                            Circle()
                                                .fill(Color(red: 254/255, green: 242/255, blue: 228/255))
                                                .frame(width: 44, height: 44)
                                                .overlay(
                                                    Image(systemName: "bell.badge")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(Color.appTextBrown)
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text("알림 설정")
                                                    .font(.system(size: 15, weight: .bold))
                                                    .foregroundColor(Color.appTextBrown)
                                                Text(isNotificationEnabled ? "매일 \(formattedTimeString(hour: reminderHour, minute: reminderMinute)) 발송" : "알림 꺼짐")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color.appTextBrown.opacity(0.65))
                                            }
                                            Spacer()
                                            Toggle("", isOn: $isNotificationEnabled)
                                                .labelsHidden()
                                                .tint(Color.appActiveTab)
                                                .onChange(of: isNotificationEnabled) { _, isEnabled in
                                                    handleNotificationToggle(isEnabled: isEnabled)
                                                }
                                        }
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 16)
                                        
                                        if isNotificationEnabled {
                                            HStack {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "clock.fill")
                                                        .font(.system(size: 13))
                                                        .foregroundColor(Color.appActiveTab)
                                                    Text("알림 시간 변경")
                                                        .font(.system(size: 13, weight: .medium))
                                                        .foregroundColor(Color.appTextBrown)
                                                }
                                                Spacer()
                                                DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                                    .labelsHidden()
                                                    .datePickerStyle(.compact)
                                                    .tint(Color.appActiveTab)
                                                    .onChange(of: reminderTime) { _, newTime in
                                                        updateReminderTime(from: newTime)
                                                    }
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.bottom, 12)
                                            .transition(.opacity.combined(with: .move(edge: .top)))
                                        }
                                    }
                                    
                                    Divider()
                                        .background(Color.appTextBrown.opacity(0.15))
                                        .padding(.horizontal, 16)
                                    
                                    // 자동 질문 설정
                                    HStack(spacing: 14) {
                                        Circle()
                                            .fill(Color(red: 254/255, green: 242/255, blue: 228/255))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Image(systemName: "lightbulb")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(Color.appTextBrown)
                                            )
                                        
                                        HStack(spacing: 6) {
                                            Text("자동 질문 설정")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(Color.appTextBrown)
                                            if isAIChatSuggestEnabled {
                                                Circle()
                                                    .fill(Color.appActiveTab)
                                                    .frame(width: 6, height: 6)
                                            }
                                        }
                                        Spacer()
                                        Toggle("", isOn: $isAIChatSuggestEnabled)
                                            .labelsHidden()
                                            .tint(Color.appActiveTab)
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 16)
                                }
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 14)
                            
                            // 2. 세부 설정 헤더 타이틀
                            Text("세부 설정")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.appTextBrown)
                                .padding(.horizontal, 22)
                                .padding(.top, 6)
                            
                            // 3. 세부 설정 아코디언 메뉴 리스트
                            VStack(spacing: 0) {
                                SettingAccordionSection(
                                    title: "시스템 설정",
                                    isExpanded: $isSystemExpanded
                                ) {
                                    VStack(spacing: 0) {
                                        // 💡 언어 설정 클릭 시 상세 서브뷰 이동
                                        SettingSubRow(title: "언어 설정") {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                showLanguageSetting = true
                                            }
                                        }
                                        SettingSubRow(title: "알림 설정") { showMenuAlert("알림 설정") }
                                        SettingSubRow(title: "자동 질문 설정") {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                showAutoQuestionSetting = true
                                            }
                                        }
                                    }
                                }
                                
                                SettingAccordionSection(
                                    title: "개인 설정",
                                    isExpanded: $isPersonalExpanded
                                ) {
                                    VStack(spacing: 0) {
                                        SettingSubRow(title: "프로필 사진") {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                showPersonalProfileSetting = true
                                            }
                                        }
                                        SettingSubRow(title: "계정 변경") {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                showAccountManagement = true
                                            }
                                        }
                                        SettingSubRow(title: "업로드 알림 설정") {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                showUploadNotificationSetting = true
                                            }
                                        }
                                    }
                                }
                                
                                VStack(spacing: 0) {
                                    NoticeRow(title: "공지 사항") { showMenuAlert("공지 사항") }
                                    NoticeRow(title: "문의 사항") { showMenuAlert("문의 사항") }
                                    NoticeRow(title: "이용 약관") { showMenuAlert("이용 약관") }
                                }
                                .background(Color.appHeader)
                            }
                            
                            Spacer(minLength: 40)
                        }
                    }
                }
                .transition(.move(edge: .leading))
            }
        }
        .background(Color.appBackground)
        .onAppear {
            syncInitialTime()
            if isNotificationEnabled {
                scheduleDailyMealReminder(hour: reminderHour, minute: reminderMinute)
            }
        }
        .alert("안내", isPresented: $showAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("'\(alertMessage)' 상세 설정 화면은 추후 연결될 예정입니다.")
        }
    }
    
    private func syncInitialTime() {
        var comp = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comp.hour = reminderHour
        comp.minute = reminderMinute
        reminderTime = Calendar.current.date(from: comp) ?? Date()
    }
    
    private func updateReminderTime(from newDate: Date) {
        let comp = Calendar.current.dateComponents([.hour, .minute], from: newDate)
        let hour = comp.hour ?? 20
        let minute = comp.minute ?? 0
        self.reminderHour = hour
        self.reminderMinute = minute
        if isNotificationEnabled {
            scheduleDailyMealReminder(hour: hour, minute: minute)
        }
    }
    
    private func handleNotificationToggle(isEnabled: Bool) {
        let center = UNUserNotificationCenter.current()
        if isEnabled {
            center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                if granted {
                    scheduleDailyMealReminder(hour: reminderHour, minute: reminderMinute)
                } else {
                    DispatchQueue.main.async {
                        self.isNotificationEnabled = false
                    }
                }
            }
        } else {
            center.removePendingNotificationRequests(withIdentifiers: ["dailyMealReminder"])
        }
    }
    
    private func scheduleDailyMealReminder(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyMealReminder"])
        let content = UNMutableNotificationContent()
        content.title = "끼니"
        content.body = "오늘 가족들과 식사는 챙기셨나요? 오늘의 식탁 사진을 공유해보세요! 🍚"
        content.sound = .default
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyMealReminder", content: content, trigger: trigger)
        center.add(request) { _ in }
    }
    
    private func formattedTimeString(hour: Int, minute: Int) -> String {
        let isPM = hour >= 12
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let period = isPM ? "오후" : "오전"
        return String(format: "%@ %d시 %02d분", period, displayHour, minute)
    }
    
    private func showMenuAlert(_ title: String) {
        alertMessage = title
        showAlert = true
    }
}

// MARK: - 아코디언 컴포넌트
struct SettingAccordionSection<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.22)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.appTextBrown)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.appTextBrown)
                }
                .padding(.horizontal, 22)
                .frame(height: 48)
                .background(Color.appHeader)
            }
            
            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - 서브 메뉴 아이템 행 컴포넌트
struct SettingSubRow: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color.appTextBrown)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.appTextBrown.opacity(0.8))
            }
            .padding(.horizontal, 22)
            .frame(height: 44)
            .background(Color.appBackground)
        }
    }
}

// MARK: - 하단 공지/문의/약관 행 컴포넌트
struct NoticeRow: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color.appTextBrown)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.appTextBrown.opacity(0.8))
            }
            .padding(.horizontal, 22)
            .frame(height: 46)
        }
    }
}

// MARK: - 상단 헤더 바 (뒤로가기 액션 연결 및 높이 규격 일치)
struct SettingsHeaderBar: View {
    var onBack: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            if let onBack = onBack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.appTextBrown)
                        .frame(width: 30, height: 30, alignment: .leading)
                }
            } else {
                Spacer().frame(width: 30)
            }
            
            Spacer()
            
            Text("설정")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color.appTextBrown)
            
            Spacer()
            
            Image(systemName: "ellipsis")
                .rotationEffect(.degrees(90))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.appTextBrown)
                .frame(width: 30, height: 30, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.appHeader)
    }
}
