import SwiftUI
import PhotosUI
import Photos
import UserNotifications

// MARK: - App Color Theme
extension Color {
    static let appBackground = Color(red: 254/255, green: 247/255, blue: 236/255)
    static let appHeader = Color(red: 219/255, green: 198/255, blue: 164/255)
    static let appCardBg = Color(red: 109/255, green: 99/255, blue: 76/255)
    static let appCardSecondary = Color(red: 168/255, green: 156/255, blue: 135/255)
    static let appPanelBg = Color(red: 217/255, green: 196/255, blue: 161/255)
    static let appActiveTab = Color(red: 126/255, green: 145/255, blue: 104/255)
    static let appTextBrown = Color(red: 88/255, green: 74/255, blue: 50/255)
    
    // 모달 & 팝업 전용 통일 컬러
    static let modalBg = Color(red: 255/255, green: 247/255, blue: 238/255)
    static let sandBeige = Color(red: 218/255, green: 196/255, blue: 158/255)
    
    // 채팅 & 리포트 전용 컬러
    static let chatInputBarBg = Color(red: 88/255, green: 78/255, blue: 56/255)
    static let chatSuggestBg = Color(red: 147/255, green: 174/255, blue: 122/255)
    static let chatBadgeBg = Color(red: 214/255, green: 187/255, blue: 148/255)
    static let reportAiBannerBg = Color(red: 212/255, green: 187/255, blue: 153/255)
    
    // 회원 탈퇴 및 삭제 전용 레드 (#BD4C4F)
    static let accountDeleteRed = Color(red: 189/255, green: 76/255, blue: 79/255)
}

// MARK: - 최근 사용 이모지 저장소 매니저 (채팅 & 식탁 업로드 공통 연동)
class RecentEmojiManager {
    static let shared = RecentEmojiManager()
    private let key = "kkini_recent_emojis_list"
    
    func getRecentEmojis() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }
    
    func addRecentEmoji(_ emoji: String) {
        var list = getRecentEmojis()
        list.removeAll { $0 == emoji }
        list.insert(emoji, at: 0)
        if list.count > 12 {
            list = Array(list.prefix(12))
        }
        UserDefaults.standard.set(list, forKey: key)
    }
}

// MARK: - Data Models
struct MealPost: Identifiable, Equatable {
    let id = UUID()
    var image: UIImage?
    var emojiName: String?
    var text: String
    var likedBy: [String] = []
    
    static func == (lhs: MealPost, rhs: MealPost) -> Bool {
        lhs.id == rhs.id && lhs.text == rhs.text && lhs.likedBy == rhs.likedBy && lhs.emojiName == rhs.emojiName
    }
}

struct FamilyMember: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var post: MealPost?
    
    static func == (lhs: FamilyMember, rhs: FamilyMember) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.post == rhs.post
    }
}

// MARK: - 채팅 메시지 모델 (텍스트, 사진, 원숭이 이모티콘 모두 지원)
struct ChatMessage: Identifiable, Hashable {
    var id: String = UUID().uuidString
    let text: String
    let time: String
    var senderName: String = ""
    var isFromMe: Bool = false
    var dateString: String = ""
    var image: UIImage? = nil
    var emojiName: String? = nil
}

enum OnboardingScreenState {
    case start
    case create
    case join
}

// MARK: - 일별 리포트 아카이빙 모델 (앱 시작일부터 오늘까지 동적 자동 생성)
struct DailyReport: Identifiable, Hashable {
    let id = UUID()
    let dateString: String
    let monthString: String
    let dayString: String
    let aiSummary: String
    let chatLogs: [ChatMessage]
    var isToday: Bool = false
    
    static func createRecentReports(
        startDate: Date = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 1)) ?? Date(),
        todayLogs: [ChatMessage] = []
    ) -> [DailyReport] {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: startDate)
        
        let dayDifference = calendar.dateComponents([.day], from: start, to: now).day ?? 0
        let totalDays = max(0, dayDifference)
        
        let fullFormatter = DateFormatter()
        fullFormatter.dateFormat = "yyyy.MM.dd"
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MM"
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "dd"
        
        let sampleSummaries = [
            "온 가족이 함께 완성한 오늘의 따뜻한 식탁",
            "정성 가득한 집밥으로 채운 든든한 하루",
            "가족들의 활기찬 대화와 함께한 점심 식사",
            "소박하지만 영양 만점인 건강 식단",
            "바쁜 일상 속 소중하게 챙겨먹은 저녁",
            "주말의 여유를 만끽한 브런치와 커피"
        ]
        
        return (0...totalDays).compactMap { offset in
            guard let targetDate = calendar.date(byAdding: .day, value: -offset, to: now) else { return nil }
            let dateStr = fullFormatter.string(from: targetDate)
            let monthStr = monthFormatter.string(from: targetDate)
            let dayStr = dayFormatter.string(from: targetDate)
            let summary = sampleSummaries[offset % sampleSummaries.count]
            let isCurrentDay = (offset == 0)
            
            let cleanTarget = dateStr.replacingOccurrences(of: " ", with: "")
            let matchingLogs = todayLogs.filter {
                $0.dateString.replacingOccurrences(of: " ", with: "") == cleanTarget
            }
            
            let logs: [ChatMessage]
            if !matchingLogs.isEmpty {
                logs = matchingLogs
            } else if isCurrentDay && !todayLogs.isEmpty {
                logs = todayLogs
            } else {
                logs = [
                    ChatMessage(text: "\(dayStr)일 식사 맛있게 챙겨먹었어!", time: "오후 1:10", senderName: "가족", isFromMe: false, dateString: dateStr),
                    ChatMessage(text: "나도 식탁 사진 올렸어~ 밥 꼭 챙겨먹어!", time: "오후 1:14", senderName: "나", isFromMe: true, dateString: dateStr)
                ]
            }
            
            return DailyReport(
                dateString: dateStr,
                monthString: monthStr,
                dayString: dayStr,
                aiSummary: summary,
                chatLogs: logs,
                isToday: isCurrentDay
            )
        }
    }
}

// MARK: - Root Main View
struct ContentView: View {
    @State private var selectedTab: Int = 2
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("myFamilyId") private var myFamilyId: String = ""
    @AppStorage("kkini_my_user_name") private var myUserName: String = ""
    
    // 당일 최초 접속 신문 팝업용 상태값
    @AppStorage("lastSeenNewspaperDate") private var lastSeenNewspaperDate: String = ""
    @State private var showNewspaperPopup: Bool = false
    @State private var latestArticle: NewspaperArticle? = nil
    @State private var showNewspaperArchive: Bool = false
    
    @State private var onboardingScreen: OnboardingScreenState = .start
    
    @State private var showNameSetupModal: Bool = false
    @State private var tempInputName: String = ""
    @State private var isChatInputActive: Bool = false
    
    @State private var myPost: MealPost? = nil
    @State private var otherFamilyMembers: [FamilyMember] = []
    
    @State private var chatMessages: [ChatMessage] = []
    
    private var needsOnboarding: Bool {
        !hasCompletedOnboarding || myFamilyId.trimmingCharacters(in: .whitespaces).isEmpty || myUserName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                switch selectedTab {
                case 0:
                    CharacterCustomView(
                        myPost: myPost,
                        otherFamilyMembers: otherFamilyMembers,
                        onBack: { selectedTab = 2 }
                    )
                case 1:
                    ChatRoomView(
                        myUserName: myUserName,
                        myPost: myPost,
                        otherFamilyMembers: otherFamilyMembers,
                        messages: $chatMessages,
                        isInputActive: $isChatInputActive,
                        onBack: { selectedTab = 2 }
                    )
                case 2:
                    DiningHomeView(
                        myUserName: myUserName,
                        myPost: $myPost,
                        otherFamilyMembers: $otherFamilyMembers,
                        onChangeName: {
                            tempInputName = myUserName
                            showNameSetupModal = true
                        }
                    )
                case 3:
                    ReportMainView(
                        myUserName: myUserName,
                        myPost: myPost,
                        otherFamilyMembers: otherFamilyMembers,
                        chatLogs: chatMessages,
                        onBack: { selectedTab = 2 }
                    )
                case 4:
                    SettingsView(onBack: {
                        selectedTab = 2
                    })
                default:
                    EmptyView()
                }
                
                if !(selectedTab == 1 && isChatInputActive) {
                    Spacer(minLength: 70)
                }
            }
            
            if !(selectedTab == 1 && isChatInputActive) {
                CustomBottomBar(selectedTab: $selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // 첫 접속 시 메인 식탁 화면 위에 뜨는 끼니 신문 팝업
            if showNewspaperPopup, let article = latestArticle {
                LatestNewspaperPopupView(
                    article: article,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showNewspaperPopup = false
                        }
                    },
                    onShowMore: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showNewspaperPopup = false
                            showNewspaperArchive = true
                        }
                    }
                )
                .zIndex(850)
                .transition(.opacity)
            }
            
            if showNameSetupModal {
                NameSetupOverlayView(
                    inputText: $tempInputName,
                    currentSavedName: myUserName
                ) { newName in
                    myUserName = newName
                    showNameSetupModal = false
                    startListeningServices()
                }
                .zIndex(900)
            }
            
            if needsOnboarding {
                ZStack {
                    switch onboardingScreen {
                    case .start:
                        OnboardingStartView(
                            onSelectCreate: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    onboardingScreen = .create
                                }
                            },
                            onSelectJoin: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    onboardingScreen = .join
                                }
                            }
                        )
                    case .create:
                        CreateFamilyFlowView(
                            onBackToRoot: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    onboardingScreen = .start
                                }
                            },
                            onComplete: { familyId, nickname in
                                myFamilyId = familyId
                                myUserName = nickname
                                hasCompletedOnboarding = true
                                withAnimation {
                                    startListeningServices()
                                    checkAndAutoShowNewspaper()
                                }
                            }
                        )
                    case .join:
                        JoinFamilyFlowView(
                            onBackToRoot: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    onboardingScreen = .start
                                }
                            },
                            onComplete: { familyId, nickname in
                                myFamilyId = familyId
                                myUserName = nickname
                                hasCompletedOnboarding = true
                                withAnimation {
                                    startListeningServices()
                                    checkAndAutoShowNewspaper()
                                }
                            }
                        )
                    }
                }
                .transition(.opacity)
                .zIndex(1000)
            }
        }
        .fullScreenCover(isPresented: $showNewspaperArchive) {
            NavigationStack {
                NewspaperArchiveMainView()
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab != 1 {
                isChatInputActive = false
            }
        }
        .onAppear {
            if !needsOnboarding {
                startListeningServices()
                checkAndAutoShowNewspaper()
            }
        }
    }
    
    // MARK: - 첫 접속 자동 감지 및 조용한 신문 발행 (Lazy Generation)
    private func checkAndAutoShowNewspaper() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        
        let todayKey = formatter.string(from: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayKey = formatter.string(from: yesterday)
        
        let activeFamily = myFamilyId.trimmingCharacters(in: .whitespaces)
        guard !activeFamily.isEmpty else { return }
        
        guard lastSeenNewspaperDate != todayKey else { return }
        
        FirebaseManager.shared.fetchNewspaper(familyId: activeFamily, dateString: yesterdayKey) { cachedDict in
            if let dict = cachedDict {
                self.latestArticle = NewspaperArticle.from(dict: dict, dateStr: yesterdayKey)
                self.lastSeenNewspaperDate = todayKey
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        self.showNewspaperPopup = true
                    }
                }
            } else {
                self.autoGenerateYesterdayNewspaper(familyId: activeFamily, yesterdayKey: yesterdayKey, todayKey: todayKey)
            }
        }
    }
    
    // MARK: - 백그라운드 자동 생성 파이프라인
    private func autoGenerateYesterdayNewspaper(familyId: String, yesterdayKey: String, todayKey: String) {
        FirebaseManager.shared.fetchArchivedMeals(familyId: familyId, dateString: yesterdayKey) { mealDict in
            var meals: [(userName: String, text: String, image: UIImage?)] = []
            for (user, data) in mealDict {
                if !data.text.isEmpty || data.image != nil {
                    meals.append((userName: user, text: data.text, image: data.image))
                }
            }
            
            FirebaseManager.shared.fetchAllNewspapers(familyId: familyId) { allList in
                let nextIssueNumber = allList.count + 1
                
                AIService.shared.generateNewspaperArticle(
                    yesterdayDateString: yesterdayKey,
                    issueNumber: nextIssueNumber,
                    familyMeals: meals
                ) { generatedData in
                    var dataToSave = generatedData
                    
                    if let mainImg = meals.compactMap({ $0.image }).first,
                       let jpeg = mainImg.jpegData(compressionQuality: 0.5) {
                        dataToSave["mainImageBase64"] = jpeg.base64EncodedString()
                    }
                    if meals.count > 1,
                       let subImg = meals.compactMap({ $0.image }).last,
                       let subJpeg = subImg.jpegData(compressionQuality: 0.5) {
                        dataToSave["subImageBase64"] = subJpeg.base64EncodedString()
                    }
                    
                    FirebaseManager.shared.saveNewspaper(
                        familyId: familyId,
                        dateString: yesterdayKey,
                        data: dataToSave
                    ) { success in
                        if success {
                            self.latestArticle = NewspaperArticle.from(dict: dataToSave, dateStr: yesterdayKey)
                            self.lastSeenNewspaperDate = todayKey
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    self.showNewspaperPopup = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 매일 오전 9시 로컬 푸시 알림 등록
    private func scheduleDailyNewspaperNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["kkini_daily_morning_newspaper"])
        
        let content = UNMutableNotificationContent()
        content.title = "끼니 신문 도착 🗞️"
        content.body = "어제 우리 가족의 식탁 이야기가 담긴 신문이 도착했어요!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "kkini_daily_morning_newspaper", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("신문 알림 등록 실패: \(error.localizedDescription)")
            } else {
                print("매일 오전 9시 신문 알림 등록 완료")
            }
        }
    }
    
    private func startListeningServices() {
        let activeName = myUserName.trimmingCharacters(in: .whitespaces)
        let activeFamily = myFamilyId.trimmingCharacters(in: .whitespaces)
        guard !activeName.isEmpty, !activeFamily.isEmpty else { return }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                print("푸시 알림 권한 허용 완료")
                self.scheduleDailyNewspaperNotification()
            }
        }
        
        FirebaseManager.shared.cleanLegacyDummyData(familyId: activeFamily)
        FirebaseManager.shared.registerUser(familyId: activeFamily, userName: activeName)
        
        FirebaseManager.shared.listenTodayMeals(familyId: activeFamily) { mealDict in
            if let myData = mealDict[activeName] {
                let hasMeal = (myData.image != nil) || (myData.emoji != nil && !myData.emoji!.isEmpty) || !myData.text.isEmpty
                self.myPost = hasMeal ? MealPost(image: myData.image, emojiName: myData.emoji, text: myData.text) : nil
            } else {
                self.myPost = nil
            }
            
            var dynamicList: [FamilyMember] = []
            for (senderName, data) in mealDict where senderName != activeName && senderName != "나" {
                let hasMeal = (data.image != nil) || (data.emoji != nil && !data.emoji!.isEmpty) || !data.text.isEmpty
                let post = hasMeal ? MealPost(image: data.image, emojiName: data.emoji, text: data.text) : nil
                dynamicList.append(FamilyMember(name: senderName, post: post))
            }
            self.otherFamilyMembers = dynamicList.sorted(by: { $0.name < $1.name })
        }
        
        FirebaseManager.shared.listenChatMessages(familyId: activeFamily) { firestoreList in
            let myCleanName = activeName.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let newMessages = firestoreList.map { m in
                let senderClean = m.senderName.trimmingCharacters(in: .whitespacesAndNewlines)
                let isMe = (senderClean == myCleanName) || (senderClean == "나")
                
                var img: UIImage? = nil
                if let b64 = m.imageBase64, let data = Data(base64Encoded: b64) {
                    img = UIImage(data: data)
                }
                
                let parsedEmoji: String? = {
                    if m.text.hasPrefix("[emoji:") && m.text.hasSuffix("]") {
                        return m.text.replacingOccurrences(of: "[emoji:", with: "").replacingOccurrences(of: "]", with: "")
                    }
                    return nil
                }()
                
                return ChatMessage(
                    id: m.id,
                    text: m.text,
                    time: m.time,
                    senderName: m.senderName,
                    isFromMe: isMe,
                    dateString: m.dateString,
                    image: img,
                    emojiName: parsedEmoji
                )
            }
            
            let isChatNotifyEnabled = UserDefaults.standard.bool(forKey: "notifyOnChatMessage")
            
            if !self.chatMessages.isEmpty,
               let lastMsg = newMessages.last,
               newMessages.count > self.chatMessages.count {
                
                let lastSenderClean = lastMsg.senderName.trimmingCharacters(in: .whitespacesAndNewlines)
                let isReallyFromMe = (lastSenderClean == myCleanName) || (lastSenderClean == "나") || lastMsg.isFromMe
                
                if !isReallyFromMe && isChatNotifyEnabled {
                    let content = UNMutableNotificationContent()
                    content.title = "\(lastMsg.senderName)"
                    content.body = lastMsg.image != nil ? "사진을 보냈어요 📷" : (lastMsg.emojiName != nil ? "이모티콘을 보냈어요!" : lastMsg.text)
                    content.sound = .default
                    
                    let request = UNNotificationRequest(
                        identifier: UUID().uuidString,
                        content: content,
                        trigger: nil
                    )
                    UNUserNotificationCenter.current().add(request)
                }
            }
            
            self.chatMessages = newMessages
        }
    }
}

// MARK: - 이름 설정 모달창
struct NameSetupOverlayView: View {
    @Binding var inputText: String
    let currentSavedName: String
    var onConfirm: (String) -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 46))
                    .foregroundColor(Color.appActiveTab)
                
                Text("이 휴대폰은 누구의 폰인가요?")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color.appTextBrown)
                
                Text("식탁에서 사용할 본인의 이름을 직접 입력해 주세요.\n(예: 큰딸, 지선, 엄마, 아빠)")
                    .font(.system(size: 13))
                    .foregroundColor(Color.appTextBrown.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                TextField("이름 입력", text: $inputText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appHeader, lineWidth: 1.5)
                    )
                    .foregroundColor(.black)
                
                Button(action: {
                    let trimmed = inputText.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        onConfirm(trimmed)
                    }
                }) {
                    Text("끼니 시작하기")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.5) : Color.appActiveTab)
                        .cornerRadius(12)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(26)
            .background(Color.modalBg)
            .cornerRadius(22)
            .padding(.horizontal, 32)
            .shadow(radius: 14)
        }
    }
}

// MARK: - 0. Character Customization View
enum DecorateSubTab: String, CaseIterable {
    case clothing = "의류"
    case template = "템플릿"
    case status = "상태"
}

struct ClothingItem: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String?
    let characterImageName: String
    var iconScale: CGFloat = 1.0
}

struct TemplateItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let bgImageName: String?
    let bgColor: Color
}

let appTableTemplates: [TemplateItem] = [
    TemplateItem(name: "기본 식탁", bgImageName: nil, bgColor: Color(red: 109/255, green: 99/255, blue: 76/255)),
    TemplateItem(name: "소프트 그린", bgImageName: nil, bgColor: Color(red: 126/255, green: 145/255, blue: 104/255)),
    TemplateItem(name: "따뜻한 핑크", bgImageName: nil, bgColor: Color(red: 219/255, green: 168/255, blue: 168/255)),
    TemplateItem(name: "스티치", bgImageName: "template_bg_1", bgColor: Color.appCardBg),
    TemplateItem(name: "체크 보드", bgImageName: "template_bg_2", bgColor: Color.appCardBg),
    TemplateItem(name: "가로 줄무늬", bgImageName: "template_bg_3", bgColor: Color.appCardBg),
    TemplateItem(name: "땡땡이", bgImageName: "template_bg_4", bgColor: Color.appCardBg),
    TemplateItem(name: "꽃무늬", bgImageName: "template_bg_5", bgColor: Color.appCardBg),
    TemplateItem(name: "나무 질감", bgImageName: "template_bg_6", bgColor: Color.appCardBg),
    TemplateItem(name: "세로 줄무늬", bgImageName: "template_bg_7", bgColor: Color.appCardBg),
    TemplateItem(name: "기본 배경", bgImageName: "template_bg_8", bgColor: Color.appCardBg),
    TemplateItem(name: "브라운 체크", bgImageName: "template_bg_9", bgColor: Color.appCardBg)
]

struct TableTemplateView: View {
    @AppStorage("kkini_selected_template_index") private var selectedTemplateIndex: Int = 0
    
    var body: some View {
        let template = (selectedTemplateIndex < appTableTemplates.count)
            ? appTableTemplates[selectedTemplateIndex]
            : appTableTemplates[0]
        
        ZStack {
            if let bgName = template.bgImageName, UIImage(named: bgName) != nil {
                Color.clear
                    .overlay(
                        Image(bgName)
                            .resizable()
                            .scaledToFill()
                    )
                    .clipped()
            } else {
                template.bgColor
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

struct CharacterCustomView: View {
    let myPost: MealPost?
    let otherFamilyMembers: [FamilyMember]
    var onBack: () -> Void
    
    @State private var selectedSubTab: DecorateSubTab = .clothing
    @AppStorage("kkini_selected_clothing_index") private var selectedClothingIndex: Int = -1
    @AppStorage("kkini_selected_template_index") private var selectedTemplateIndex: Int = 0
    @AppStorage("kkini_accumulated_meal_count") private var totalMealCount: Int = 0
    
    @State private var showAlbumInfoPopup: Bool = false
    @State private var isHappyReaction: Bool = false
    @State private var showHeartParticles: Bool = false
    @State private var tempHappyMessage: String? = nil
    
    let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    
    let clothingItems: [ClothingItem] = [
        ClothingItem(name: "핑크 후드", iconName: "cloth_icon_3d_1", characterImageName: "cloth_charc_3d_1"),
        ClothingItem(name: "몽끼 니트", iconName: "cloth_icon_3d_2", characterImageName: "cloth_charc_3d_2"),
        ClothingItem(name: "셔츠 조끼", iconName: "cloth_icon_3d_3", characterImageName: "cloth_charc_3d_3"),
        ClothingItem(name: "하트 나시", iconName: "cloth_icon_3d_4", characterImageName: "cloth_charc_3d_4"),
        ClothingItem(name: "핑크 멜빵", iconName: "cloth_icon_3d_5", characterImageName: "cloth_charc_3d_5"),
        ClothingItem(name: "핑크 스커트", iconName: "cloth_icon_3d_6", characterImageName: "cloth_charc_3d_6"),
        ClothingItem(name: "초록 반바지", iconName: "cloth_icon_3d_7", characterImageName: "cloth_charc_3d_7"),
        ClothingItem(name: "초록 단화", iconName: "cloth_icon_3d_8", characterImageName: "cloth_charc_3d_8"),
        ClothingItem(name: "갈색 운동화", iconName: "cloth_icon_3d_9", characterImageName: "cloth_charc_3d_9"),
        ClothingItem(name: "한복", iconName: "cloth_icon_3d_10", characterImageName: "cloth_charc_3d_10", iconScale: 1.35),
        ClothingItem(name: "산타클로스", iconName: "cloth_icon_3d_11", characterImageName: "cloth_charc_3d_11"),
        ClothingItem(name: "작업복", iconName: "cloth_icon_3d_12", characterImageName: "cloth_charc_3d_12", iconScale: 1.45)
    ]
    
    var currentCharacterImage: String {
        if isHappyReaction {
            return "character_3d_2"
        }
        guard selectedClothingIndex >= 0 && selectedClothingIndex < clothingItems.count else {
            return "character_3d_stand"
        }
        return clothingItems[selectedClothingIndex].characterImageName
    }
    
    var totalMembersCount: Int { otherFamilyMembers.count + 1 }
    var uploadedCount: Int {
        let myCount = (myPost != nil) ? 1 : 0
        let othersCount = otherFamilyMembers.filter { $0.post != nil }.count
        return myCount + othersCount
    }
    var hungerPercent: Int {
        guard totalMembersCount > 0 else { return 0 }
        return Int(round(Double(uploadedCount) / Double(totalMembersCount) * 100.0))
    }
    
    var dynamicBubbleMessage: String {
        if let happyText = tempHappyMessage {
            return happyText
        }
        let uploadedOthers = otherFamilyMembers.filter { $0.post != nil }
        if uploadedCount == totalMembersCount && totalMembersCount > 0 {
            return "오늘 우리 가족 식탁이 모두 완성되었어!"
        } else if let latestMember = uploadedOthers.last {
            return "최근에 \(latestMember.name)가 식사를 업로드 했어!"
        } else if myPost != nil {
            return "내가 방금 맛있는 식사를 업로드 했어!"
        } else {
            return "아직 오늘 식사가 안 올라왔어! 밥 먹었니?"
        }
    }
    
    private func triggerPetInteraction() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
            isHappyReaction = true
            showHeartParticles = true
            tempHappyMessage = "끼니가 너무 좋아해요! 헤헤 🥰💕"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showHeartParticles = false
                isHappyReaction = false
                tempHappyMessage = nil
            }
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                CommonHeaderBar(title: "꾸미기", onBack: onBack)
                
                ZStack {
                    Color.appBackground
                        .ignoresSafeArea(edges: .horizontal)
                    
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        
                        ZStack {
                            if showHeartParticles && selectedSubTab != .template {
                                HStack(spacing: 18) {
                                    Image(systemName: "heart.fill").foregroundColor(.pink).font(.system(size: 24)).offset(y: -40)
                                    Image(systemName: "heart.fill").foregroundColor(.red).font(.system(size: 30)).offset(y: -60)
                                    Image(systemName: "heart.fill").foregroundColor(.pink).font(.system(size: 22)).offset(y: -35)
                                }
                                .transition(.scale.combined(with: .opacity))
                                .zIndex(10)
                            }
                            
                            switch selectedSubTab {
                            case .clothing:
                                Image(currentCharacterImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 250)
                                    .scaleEffect(isHappyReaction ? 1.08 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isHappyReaction)
                                
                            case .template:
                                ZStack {
                                    TableTemplateView()
                                        .cornerRadius(16)
                                    
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.appActiveTab, style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                                }
                                .frame(width: 250, height: 250)
                                
                            case .status:
                                VStack(spacing: 4) {
                                    SpeechBubbleView(text: dynamicBubbleMessage)
                                        .padding(.trailing, 8)
                                    
                                    Image(isHappyReaction ? "character_3d" : "character_3d_2")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 195)
                                        .scaleEffect(isHappyReaction ? 1.08 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isHappyReaction)
                                }
                            }
                        }
                        .frame(height: 260)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedSubTab != .template {
                                triggerPetInteraction()
                            }
                        }
                        .gesture(
                            DragGesture(minimumDistance: 15)
                                .onEnded { _ in
                                    if selectedSubTab != .template {
                                        triggerPetInteraction()
                                    }
                                }
                        )
                        
                        Spacer(minLength: 0)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        ForEach(DecorateSubTab.allCases, id: \.self) { tab in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedSubTab = tab
                                }
                            }) {
                                Text(tab.rawValue)
                                    .font(.system(size: 14, weight: selectedSubTab == tab ? .bold : .medium))
                                    .foregroundColor(selectedSubTab == tab ? .white : Color.appTextBrown.opacity(0.8))
                                    .padding(.horizontal, 22)
                                    .padding(.vertical, 7)
                                    .background(
                                        selectedSubTab == tab
                                        ? Color(red: 185/255, green: 156/255, blue: 116/255)
                                        : Color.clear
                                    )
                                    .cornerRadius(18)
                            }
                        }
                    }
                    .padding(.top, 8)
                    
                    Group {
                        switch selectedSubTab {
                        case .clothing:
                            clothingGridPanel
                        case .template:
                            templateGridPanel
                        case .status:
                            statusControlPanel
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
                .frame(height: 300)
                .background(Color.appPanelBg)
            }
            
            if showAlbumInfoPopup {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAlbumInfoPopup = false
                        }
                    }
                
                albumInfoPopupCard
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                    .zIndex(100)
            }
        }
    }
    
    private var clothingGridPanel: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(clothingItems.indices, id: \.self) { idx in
                    let item = clothingItems[idx]
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if selectedClothingIndex == idx {
                                selectedClothingIndex = -1
                            } else {
                                selectedClothingIndex = idx
                            }
                        }
                    }) {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                            .frame(height: 72)
                            .overlay(
                                Group {
                                    if let icon = item.iconName, UIImage(named: icon) != nil {
                                        Image(icon)
                                            .resizable()
                                            .scaledToFit()
                                            .padding(6)
                                            .scaleEffect(item.iconScale)
                                    } else {
                                        Image("character_3d_stand")
                                            .resizable()
                                            .scaledToFit()
                                            .padding(6)
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.appActiveTab, lineWidth: selectedClothingIndex == idx ? 3 : 0)
                            )
                    }
                }
            }
            .padding(.top, 4)
        }
    }
    
    private var templateGridPanel: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(appTableTemplates.indices, id: \.self) { idx in
                    let template = appTableTemplates[idx]
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTemplateIndex = idx
                        }
                    }) {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(template.bgColor == .clear ? Color.white : template.bgColor)
                            .frame(height: 72)
                            .overlay(
                                Group {
                                    if let bgName = template.bgImageName, UIImage(named: bgName) != nil {
                                        Image(bgName)
                                            .resizable()
                                            .scaledToFill()
                                            .cornerRadius(14)
                                    } else {
                                        Text(template.name)
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    }
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.appActiveTab, lineWidth: selectedTemplateIndex == idx ? 3 : 0)
                            )
                    }
                }
            }
            .padding(.top, 4)
        }
    }
    
    private var statusControlPanel: some View {
        VStack(spacing: 8) {
            HStack(spacing: 14) {
                VStack(spacing: 10) {
                    Image(systemName: "cooktop.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 46)
                        .foregroundColor(Color.appTextBrown)
                    
                    HStack(spacing: 4) {
                        Text("배가").font(.system(size: 13, weight: .medium))
                        Text("\(hungerPercent)%").font(.system(size: 13, weight: .bold)).foregroundColor(Color.appActiveTab)
                        Text("찼어!").font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(Color.appTextBrown)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.appActiveTab.opacity(0.3)).frame(height: 7)
                            Capsule().fill(Color.appActiveTab)
                                .frame(width: geo.size.width * CGFloat(min(hungerPercent, 100)) / 100.0, height: 7)
                        }
                    }
                    .frame(height: 7)
                    .padding(.horizontal, 6)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(16)
                
                VStack(spacing: 10) {
                    Image("emoji4")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 48)
                        .scaleEffect(isHappyReaction ? 1.15 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isHappyReaction)
                    
                    Button(action: { triggerPetInteraction() }) {
                        Text(isHappyReaction ? "좋아해요! 🥰" : "놀아주기")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(isHappyReaction ? Color.pink : Color.appActiveTab)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(16)
            }
            .frame(height: 145)
            
            VStack(alignment: .leading, spacing: 3) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        showAlbumInfoPopup = true
                    }
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.appTextBrown.opacity(0.85))
                }
                
                HStack {
                    Text("\(totalMealCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.appTextBrown)
                    Spacer()
                    Text("300")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.appTextBrown.opacity(0.75))
                }
                
                GeometryReader { barGeo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white).frame(height: 7)
                        Capsule().fill(Color.appActiveTab)
                            .frame(
                                width: max(8, barGeo.size.width * CGFloat(min(totalMealCount, 300)) / 300.0),
                                height: 7
                            )
                    }
                }
                .frame(height: 7)
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)
        }
    }
    
    private var albumInfoPopupCard: some View {
        VStack(spacing: 0) {
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.easeInOut(duration: 0.2)) {
                    showAlbumInfoPopup = false
                }
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.appTextBrown)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle").font(.system(size: 16, weight: .bold))
                    Text("\(totalMealCount)끼 달성!").font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(Color.appTextBrown)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(red: 88/255, green: 74/255, blue: 50/255))
                        .frame(width: 82, height: 86)
                    
                    HStack(spacing: 6) {
                        VStack(spacing: 11) {
                            Circle().fill(Color(red: 255/255, green: 250/255, blue: 242/255)).frame(width: 7, height: 7)
                            Circle().fill(Color(red: 255/255, green: 250/255, blue: 242/255)).frame(width: 7, height: 7)
                            Circle().fill(Color(red: 255/255, green: 250/255, blue: 242/255)).frame(width: 7, height: 7)
                        }
                        .padding(.leading, -4)
                        
                        Image(systemName: "fork.knife")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.vertical, 4)
                
                Text("1년간 300회 이상 가족 식탁에 참여하고\n우리 가족의 식탁을 실물 앨범으로 만나보세요!")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.appTextBrown)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(red: 218/255, green: 196/255, blue: 158/255).opacity(0.8))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 290)
        .background(Color(red: 255/255, green: 250/255, blue: 242/255))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.18), radius: 14, y: 6)
    }
}

// MARK: - 말풍선 뷰 및 꼬리 모양
struct SpeechBubbleView: View {
    let text: String
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.appTextBrown)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(red: 214/255, green: 187/255, blue: 148/255))
                .cornerRadius(14)
            
            BubbleTailShape()
                .fill(Color(red: 214/255, green: 187/255, blue: 148/255))
                .frame(width: 12, height: 6)
                .padding(.trailing, 24)
        }
    }
}

struct BubbleTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width / 2, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - 상단 원숭이 꼬리 형상
struct MonkeyTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX + 2, y: 0))
        path.addLine(to: CGPoint(x: rect.midX + 2, y: rect.height * 0.55))
        path.addCurve(
            to: CGPoint(x: rect.midX - 10, y: rect.height * 0.9),
            control1: CGPoint(x: rect.midX + 2, y: rect.height * 0.85),
            control2: CGPoint(x: rect.midX - 10, y: rect.height * 0.85)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.height * 0.65),
            control1: CGPoint(x: rect.midX - 10, y: rect.height * 0.95),
            control2: CGPoint(x: rect.midX - 10, y: rect.height * 0.8)
        )
        return path
    }
}

// MARK: - 2. Dining Table Home View
struct DiningHomeView: View {
    @AppStorage("myFamilyId") private var myFamilyId: String = ""
    let myUserName: String
    @Binding var myPost: MealPost?
    @Binding var otherFamilyMembers: [FamilyMember]
    var onChangeName: () -> Void
    
    @AppStorage("kkini_accumulated_meal_count") private var totalMealCount: Int = 0
    
    @State private var showUploadSheet = false
    @State private var isRemoveMode: Bool = false
    @State private var memberPendingDelete: FamilyMember? = nil
    @State private var isInviteSheetPresented: Bool = false
    @State private var showCopyToast: Bool = false
    @State private var selectedMemberNameForPopup: String? = nil
    
    var totalCount: Int { otherFamilyMembers.count + 1 }
    private let cardHeight: CGFloat = 170
    
    private func toggleLike(for memberName: String) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let me = myUserName.isEmpty ? "나" : myUserName
        
        if let idx = otherFamilyMembers.firstIndex(where: { $0.name == memberName }),
           var post = otherFamilyMembers[idx].post {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.65)) {
                if post.likedBy.contains(me) {
                    post.likedBy.removeAll { $0 == me }
                } else {
                    post.likedBy.append(me)
                }
                otherFamilyMembers[idx].post = post
            }
        }
    }
    
    private func toggleLikeForMe() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let me = myUserName.isEmpty ? "나" : myUserName
        
        if var post = myPost {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.65)) {
                if post.likedBy.contains(me) {
                    post.likedBy.removeAll { $0 == me }
                } else {
                    post.likedBy.append(me)
                }
                myPost = post
            }
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                CommonHeaderBar(title: "식탁 업로드", onBack: nil)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Button(action: onChangeName) {
                                HStack(spacing: 4) {
                                    Text("내 기기: \(myUserName.isEmpty ? "미설정" : myUserName)")
                                        .font(.system(size: 13, weight: .semibold))
                                    Image(systemName: "pencil.line")
                                        .font(.system(size: 11))
                                }
                                .foregroundColor(Color.appActiveTab)
                            }
                            
                            Spacer()
                            
                            Text("\(totalCount)인 식탁")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.appHeader)
                                .cornerRadius(8)
                                .foregroundColor(Color.appTextBrown)
                        }
                        .padding(.top, 14)
                        
                        Group {
                            if totalCount <= 2 {
                                VStack(spacing: 12) {
                                    if !otherFamilyMembers.isEmpty {
                                        FamilySlotCard(
                                            member: otherFamilyMembers[0],
                                            currentUserName: myUserName,
                                            isRemoveMode: isRemoveMode,
                                            onTap: { selectedMemberNameForPopup = otherFamilyMembers[0].name },
                                            onLikeToggle: { toggleLike(for: otherFamilyMembers[0].name) },
                                            onDelete: { memberPendingDelete = otherFamilyMembers[0] },
                                            onInvite: { isInviteSheetPresented = true }
                                        )
                                        .frame(height: cardHeight)
                                    }
                                    
                                    MySlotCard(
                                        userName: myUserName,
                                        myPost: myPost,
                                        onTapUpload: { showUploadSheet = true },
                                        onLikeToggle: { toggleLikeForMe() }
                                    )
                                    .frame(height: cardHeight)
                                }
                            } else if totalCount == 3 {
                                VStack(spacing: 12) {
                                    HStack(spacing: 12) {
                                        FamilySlotCard(
                                            member: otherFamilyMembers[0],
                                            currentUserName: myUserName,
                                            isRemoveMode: isRemoveMode,
                                            onTap: { selectedMemberNameForPopup = otherFamilyMembers[0].name },
                                            onLikeToggle: { toggleLike(for: otherFamilyMembers[0].name) },
                                            onDelete: { memberPendingDelete = otherFamilyMembers[0] },
                                            onInvite: { isInviteSheetPresented = true }
                                        )
                                        .frame(height: cardHeight)
                                        
                                        if otherFamilyMembers.count > 1 {
                                            FamilySlotCard(
                                                member: otherFamilyMembers[1],
                                                currentUserName: myUserName,
                                                isRemoveMode: isRemoveMode,
                                                onTap: { selectedMemberNameForPopup = otherFamilyMembers[1].name },
                                                onLikeToggle: { toggleLike(for: otherFamilyMembers[1].name) },
                                                onDelete: { memberPendingDelete = otherFamilyMembers[1] },
                                                onInvite: { isInviteSheetPresented = true }
                                            )
                                            .frame(height: cardHeight)
                                        }
                                    }
                                    
                                    MySlotCard(
                                        userName: myUserName,
                                        myPost: myPost,
                                        onTapUpload: { showUploadSheet = true },
                                        onLikeToggle: { toggleLikeForMe() }
                                    )
                                    .frame(height: cardHeight)
                                }
                            } else {
                                let columns = [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ]
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(otherFamilyMembers) { member in
                                        FamilySlotCard(
                                            member: member,
                                            currentUserName: myUserName,
                                            isRemoveMode: isRemoveMode,
                                            onTap: { selectedMemberNameForPopup = member.name },
                                            onLikeToggle: { toggleLike(for: member.name) },
                                            onDelete: { memberPendingDelete = member },
                                            onInvite: { isInviteSheetPresented = true }
                                        )
                                        .frame(height: cardHeight)
                                    }
                                    
                                    MySlotCard(
                                        userName: myUserName,
                                        myPost: myPost,
                                        onTapUpload: { showUploadSheet = true },
                                        onLikeToggle: { toggleLikeForMe() }
                                    )
                                    .frame(height: cardHeight)
                                }
                            }
                        }
                        
                        HStack {
                            Button(action: {
                                withAnimation { isRemoveMode.toggle() }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: isRemoveMode ? "checkmark.circle.fill" : "minus.circle.fill")
                                    Text(isRemoveMode ? "완료" : "구성원 제외")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(Color.appActiveTab)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                let count = otherFamilyMembers.count + 2
                                let newName = "가족 \(count)"
                                FirebaseManager.shared.registerUser(familyId: myFamilyId, userName: newName)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("구성원 추가")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(Color.appActiveTab)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            if let targetName = selectedMemberNameForPopup,
               let member = otherFamilyMembers.first(where: { $0.name == targetName }),
               let post = member.post {
                MemberMealDetailPopupView(
                    memberName: member.name,
                    post: post,
                    currentUserName: myUserName,
                    onLikeToggle: { toggleLike(for: member.name) },
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            selectedMemberNameForPopup = nil
                        }
                    }
                )
                .zIndex(50)
                .transition(.opacity)
            }
            
            if let pending = memberPendingDelete {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { memberPendingDelete = nil }
                    .zIndex(20)
                
                VStack(spacing: 24) {
                    Text("“\(pending.name)을(를) 삭제하시겠습니까?”")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.appTextBrown)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .padding(.horizontal, 10)
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            FirebaseManager.shared.deleteMeal(familyId: myFamilyId, userName: pending.name)
                            memberPendingDelete = nil
                        }) {
                            Text("네")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.appTextBrown)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.sandBeige)
                                .cornerRadius(26)
                        }
                        
                        Button(action: { memberPendingDelete = nil }) {
                            Text("다시 생각할래요!")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.appTextBrown)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.sandBeige)
                                .cornerRadius(26)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
                .background(Color.modalBg)
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
                .frame(maxWidth: 320)
                .zIndex(25)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .sheet(isPresented: $isInviteSheetPresented) {
            InviteMemberBottomSheet(showCopyToast: $showCopyToast)
                .presentationDetents([.fraction(0.38)])
        }
        .fullScreenCover(isPresented: $showUploadSheet) {
            UploadFlowView(currentUserName: myUserName, initialPost: myPost) { savedPost in
                totalMealCount += 1
                self.myPost = savedPost
            }
        }
    }
}

// MARK: - 다른 가족 구성원 슬롯 카드
struct FamilySlotCard: View {
    let member: FamilyMember
    let currentUserName: String
    var isRemoveMode: Bool = false
    var onTap: () -> Void = {}
    var onLikeToggle: () -> Void = {}
    var onDelete: () -> Void = {}
    var onInvite: () -> Void = {}
    
    private var isLikedByMe: Bool {
        let me = currentUserName.isEmpty ? "나" : currentUserName
        return member.post?.likedBy.contains(me) ?? false
    }
    
    var body: some View {
        ZStack {
            if let post = member.post {
                Button(action: {
                    if !isRemoveMode {
                        onTap()
                    }
                }) {
                    ZStack {
                        if let img = post.image {
                            Color.clear
                                .overlay(
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                )
                                .clipped()
                        } else if let emoji = post.emojiName, !emoji.isEmpty {
                            TableTemplateView()
                            Image(emoji)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 70, height: 70)
                        } else {
                            TableTemplateView()
                            Image(systemName: "fork.knife.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Color.black.opacity(post.text.isEmpty ? 0.2 : 0.38)
                        
                        VStack {
                            HStack {
                                Text(member.name)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.6), radius: 3, y: 1)
                                    .padding(.top, 12)
                                    .padding(.leading, 12)
                                Spacer()
                            }
                            Spacer()
                        }
                        
                        if !post.text.isEmpty {
                            Text(post.text)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 16)
                                .shadow(color: .black.opacity(0.6), radius: 3, y: 1)
                        }
                        
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: onLikeToggle) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.black.opacity(0.2))
                                            .frame(width: 32, height: 32)
                                        
                                        Image(systemName: isLikedByMe ? "heart.fill" : "heart")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(isLikedByMe ? .red : .white)
                                            .scaleEffect(isLikedByMe ? 1.15 : 1.0)
                                    }
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .padding(10)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                ZStack {
                    TableTemplateView()
                    
                    VStack(spacing: 8) {
                        Button(action: onInvite) {
                            VStack(spacing: 6) {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white.opacity(0.8))
                                Text("+ 구성원 초대")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white.opacity(0.95))
                            }
                        }
                        Text("\(member.name) 기다리는 중")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            if isRemoveMode {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onDelete) {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.85))
                                    .frame(width: 24, height: 24)
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(8)
                    }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

// MARK: - 나(본인)의 자리 카드
struct MySlotCard: View {
    let userName: String
    let myPost: MealPost?
    let onTapUpload: () -> Void
    var onLikeToggle: () -> Void = {}
    
    private var isLikedByMe: Bool {
        let me = userName.isEmpty ? "나" : userName
        return myPost?.likedBy.contains(me) ?? false
    }
    
    var body: some View {
        ZStack {
            if let post = myPost {
                Button(action: onTapUpload) {
                    ZStack {
                        if let img = post.image {
                            Color.clear
                                .overlay(
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                )
                                .clipped()
                        } else if let emoji = post.emojiName, !emoji.isEmpty {
                            TableTemplateView()
                            Image(emoji)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 70, height: 70)
                        } else {
                            TableTemplateView()
                            Image(systemName: "camera.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Color.black.opacity(post.text.isEmpty ? 0.2 : 0.38)
                        
                        VStack {
                            HStack {
                                Text(userName.isEmpty ? "나" : userName)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.6), radius: 3, y: 1)
                                    .padding(.top, 12)
                                    .padding(.leading, 12)
                                Spacer()
                            }
                            Spacer()
                        }
                        
                        if !post.text.isEmpty {
                            Text(post.text)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 16)
                                .shadow(color: .black.opacity(0.6), radius: 3, y: 1)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onTapUpload) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color.appActiveTab)
                                .background(Circle().fill(Color.white))
                        }
                        .padding(8)
                    }
                    Spacer()
                }
            } else {
                ZStack {
                    TableTemplateView()
                    
                    Button(action: onTapUpload) {
                        VStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 40, weight: .regular))
                                .foregroundColor(.white.opacity(0.8))
                            Text("\(userName.isEmpty ? "나" : userName) (식탁 올리기)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.65))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

// MARK: - 구성원 식탁 클릭 시 팝업 뷰
struct MemberMealDetailPopupView: View {
    let memberName: String
    let post: MealPost
    let currentUserName: String
    var onLikeToggle: () -> Void
    var onDismiss: () -> Void
    
    private var hasText: Bool {
        !post.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var isLikedByMe: Bool {
        let me = currentUserName.isEmpty ? "나" : currentUserName
        return post.likedBy.contains(me)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
                .zIndex(0)
            
            VStack(spacing: 14) {
                if !hasText { Spacer() }
                
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.35))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .zIndex(10)
                
                ZStack(alignment: .bottomTrailing) {
                    if let img = post.image {
                        Color.clear
                            .overlay(
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                            )
                            .clipped()
                            .cornerRadius(16)
                    } else if let emoji = post.emojiName, !emoji.isEmpty {
                        Color.appCardBg
                            .cornerRadius(16)
                        Image(emoji)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .frame(maxWidth: .infinity, maxHeight: 310)
                    } else {
                        Color.appCardBg
                            .cornerRadius(16)
                        Image(systemName: "fork.knife.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .frame(maxWidth: .infinity, maxHeight: 310)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Button(action: onLikeToggle) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.25))
                                .frame(width: 38, height: 38)
                            
                            Image(systemName: isLikedByMe ? "heart.fill" : "heart")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(isLikedByMe ? .red : .white)
                                .scaleEffect(isLikedByMe ? 1.15 : 1.0)
                        }
                        .contentShape(Circle())
                    }
                    .padding(14)
                }
                .frame(height: hasText ? 310 : 340)
                .contentShape(RoundedRectangle(cornerRadius: 16))
                .zIndex(1)
                
                if hasText {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 254/255, green: 247/255, blue: 236/255))
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(memberName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.appTextBrown.opacity(0.85))
                                .padding(.top, 14)
                                .padding(.leading, 18)
                            
                            Rectangle()
                                .fill(Color.appTextBrown.opacity(0.18))
                                .frame(height: 1)
                                .padding(.horizontal, 16)
                                .padding(.top, 10)
                            
                            Spacer()
                            
                            Text(post.text)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color.appTextBrown)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 18)
                            
                            Spacer()
                        }
                    }
                    .frame(height: 150)
                    .zIndex(1)
                }
                
                if !hasText { Spacer() }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, hasText ? 30 : 0)
            .zIndex(2)
        }
    }
}

// MARK: - 구성원 초대 바텀 시트
struct InviteMemberBottomSheet: View {
    @Binding var showCopyToast: Bool
    @AppStorage("myFamilyId") private var myFamilyId: String = ""
    
    var body: some View {
        VStack(spacing: 18) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 4)
                .padding(.top, 10)
            
            Text("가족 구성원 초대하기")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color.appTextBrown)
            
            HStack(spacing: 24) {
                Button(action: {
                    UIPasteboard.general.string = "가족 식탁에 초대합니다! 초대 코드: [\(myFamilyId)]"
                }) {
                    VStack(spacing: 6) {
                        Circle()
                            .fill(Color(red: 254/255, green: 229/255, blue: 0/255))
                            .frame(width: 52, height: 52)
                            .overlay(
                                Image(systemName: "message.fill")
                                    .foregroundColor(Color(red: 58/255, green: 41/255, blue: 38/255))
                            )
                        Text("카카오톡")
                            .font(.system(size: 12))
                            .foregroundColor(Color.appTextBrown)
                    }
                }
                
                Button(action: {
                    UIPasteboard.general.string = "https://kkini.app/invite/\(myFamilyId)"
                    showCopyToast = true
                }) {
                    VStack(spacing: 6) {
                        Circle()
                            .fill(Color.appHeader)
                            .frame(width: 52, height: 52)
                            .overlay(
                                Image(systemName: "link")
                                    .foregroundColor(Color.appTextBrown)
                            )
                        Text("링크 복사")
                            .font(.system(size: 12))
                            .foregroundColor(Color.appTextBrown)
                    }
                }
            }
            
            HStack {
                Text("초대 코드: \(myFamilyId)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.appTextBrown)
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = myFamilyId
                    showCopyToast = true
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(Color.appActiveTab)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appBackground)
            .cornerRadius(12)
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .background(Color.white)
    }
}

// MARK: - 1. Chat Room View (+ 버튼 사진/카메라 & 점3개 이모티콘 2탭 구현)
enum ChatBottomDrawerType {
    case none
    case mediaPicker  // + 버튼: 카메라 및 최근 사진 3장
    case emojiPicker  // ... 버튼: 감정 이모지 & 최근 사용 2개 탭
}

enum EmojiTabType: String, CaseIterable {
    case emotion = "감정 이모지"
    case recent = "최근 사용"
}

// MARK: - 1. Chat Room View (AI 식사독려 자동생성 + 첫 말풍선 후 키보드 추천 즉시 연동)
struct ChatRoomView: View {
    @AppStorage("myFamilyId") private var myFamilyId: String = ""
    let myUserName: String
    let myPost: MealPost?
    let otherFamilyMembers: [FamilyMember]
    @Binding var messages: [ChatMessage]
    @Binding var isInputActive: Bool
    var onBack: () -> Void
    
    @State private var isTailPulledDown = false
    @State private var inputText = ""
    @FocusState private var isFieldFocused: Bool
    
    @State private var familyProfiles: [String: (image: UIImage?, avatarName: String)] = [:]
    
    // MARK: - 설정 탭 On/Off 연동
    @AppStorage("isAIChatSuggestEnabled") private var isAIChatSuggestEnabled: Bool = true
    
    // MARK: - 1. 하루 첫 대화 추천 (Chat.png 스타일)
    @State private var showInitialCard: Bool = true
    @State private var initialQuestions: [String] = []
    @State private var isInitialAILoading: Bool = false
    @State private var targetMemberName: String = "가족"
    @State private var targetMealTime: String = ""
    @State private var hasTargetMealPhoto: Bool = false
    
    // MARK: - 2. 대화 도중 키보드 위 추천 (가로 2개 캡슐 스타일)
    @State private var showMidChatSuggestions: Bool = false
    @State private var midChatQuestions: [String] = []
    @State private var lastProcessedMessageCount: Int = 0
    
    // MARK: - 하단 서랍 패널 상태
    @State private var activeDrawer: ChatBottomDrawerType = .none
    @State private var showCameraPicker: Bool = false
    @State private var capturedImage: UIImage? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var recentPhotos: [UIImage] = []
    
    var todayFormattedString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. MM. dd"
        return formatter.string(from: Date())
    }
    
    // 오늘 날짜로 주고받은 메시지가 1개 이상 있는지 체크
    var hasTodayChatStarted: Bool {
        let cleanToday = todayFormattedString.replacingOccurrences(of: " ", with: "")
        return messages.contains { msg in
            !msg.dateString.isEmpty && msg.dateString.replacingOccurrences(of: " ", with: "") == cleanToday
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    CommonHeaderBar(title: "가족 채팅", onBack: {
                        isFieldFocused = false
                        activeDrawer = .none
                        isInputActive = false
                        onBack()
                    })
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                            isTailPulledDown.toggle()
                        }
                    }) {
                        MonkeyTailShape()
                            .stroke(Color.appTextBrown, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 34, height: 38)
                            .padding(.top, -2)
                    }
                    .zIndex(3)
                    
                    // 채팅 스크롤 뷰
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 14) {
                                ForEach(Array(messages.enumerated()), id: \.element.id) { index, msg in
                                    let showDateDivider: Bool = {
                                        if index == 0 { return true }
                                        let prevDate = messages[index - 1].dateString
                                        let currDate = msg.dateString
                                        return !currDate.isEmpty && prevDate != currDate
                                    }()
                                    
                                    if showDateDivider && !msg.dateString.isEmpty {
                                        HStack {
                                            Rectangle().frame(height: 1).foregroundColor(Color.appTextBrown.opacity(0.3))
                                            Text(msg.dateString)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(Color.appTextBrown.opacity(0.8))
                                                .padding(.horizontal, 10)
                                            Rectangle().frame(height: 1).foregroundColor(Color.appTextBrown.opacity(0.3))
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                    }
                                    
                                    ChatBubbleRow(
                                        message: msg,
                                        senderProfile: familyProfiles[msg.senderName]
                                    )
                                    .id(msg.id)
                                }
                                
                                // MARK: - 하루의 첫 대화 시작용 추천 카드 (Chat.png 스타일)
                                if isAIChatSuggestEnabled && showInitialCard && !hasTodayChatStarted {
                                    if isInitialAILoading {
                                        HStack(spacing: 8) {
                                            ProgressView()
                                                .tint(Color.appTextBrown)
                                            Text(hasTargetMealPhoto ? "식탁 사진을 분석하여 질문을 생각하고 있어요..." : "AI가 첫 식사 안부 질문을 생각하고 있어요...")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color.appTextBrown)
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 14)
                                        .background(Color.chatBadgeBg.opacity(0.6))
                                        .cornerRadius(14)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                    } else if !initialQuestions.isEmpty {
                                        InitialAISuggestionCard(
                                            targetName: targetMemberName,
                                            hasTargetPhoto: hasTargetMealPhoto,
                                            questions: initialQuestions,
                                            timeString: targetMealTime,
                                            onSelect: { selectedQuestion in
                                                sendTextMessage(selectedQuestion, isFromInitialCard: true)
                                            }
                                        )
                                        .id("initialCardAnchor")
                                    }
                                }
                                
                                Color.clear
                                    .frame(height: 1)
                                    .id("bottomAnchor")
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                            .padding(.bottom, 10)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onTapGesture {
                            isFieldFocused = false
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeDrawer = .none
                            }
                        }
                        .onAppear {
                            scrollToBottom(proxy: proxy, animated: false)
                        }
                        .onChange(of: messages.count) { _, _ in
                            scrollToBottom(proxy: proxy, animated: true)
                        }
                        .onChange(of: activeDrawer) { _, drawer in
                            if drawer != .none {
                                scrollToBottom(proxy: proxy, animated: true)
                            }
                        }
                        .onChange(of: isFieldFocused) { _, focused in
                            if focused {
                                scrollToBottom(proxy: proxy, animated: true)
                            }
                        }
                    }
                    
                    // MARK: - 대화 도중 키보드 위에 뜨는 자동완성 말풍선
                    if isAIChatSuggestEnabled && hasTodayChatStarted && !midChatQuestions.isEmpty {
                        AISuggestionPanel(
                            questions: midChatQuestions,
                            onSelect: { selectedQuestion in
                                sendTextMessage(selectedQuestion)
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showMidChatSuggestions = false
                                }
                            }
                        )
                        .padding(.horizontal, 14)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    // 하단 입력바
                    ChatInputBar(
                        inputText: $inputText,
                        isFocused: $isFieldFocused,
                        activeDrawer: activeDrawer,
                        onTogglePlus: {
                            isFieldFocused = false
                            withAnimation(.easeInOut(duration: 0.25)) {
                                if activeDrawer == .mediaPicker {
                                    activeDrawer = .none
                                } else {
                                    activeDrawer = .mediaPicker
                                    loadRecentPhotos()
                                }
                            }
                        },
                        onToggleDots: {
                            isFieldFocused = false
                            withAnimation(.easeInOut(duration: 0.25)) {
                                if activeDrawer == .emojiPicker {
                                    activeDrawer = .none
                                } else {
                                    activeDrawer = .emojiPicker
                                }
                            }
                        },
                        onSend: {
                            let trimmed = inputText.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty {
                                sendTextMessage(trimmed)
                                inputText = ""
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showInitialCard = false
                                    showMidChatSuggestions = false
                                }
                            }
                        }
                    )
                    
                    // 하단 서랍 (사진 / 이모티콘)
                    if activeDrawer == .mediaPicker {
                        ChatMediaPickerDrawer(
                            recentPhotos: recentPhotos,
                            selectedPhotoItem: $selectedPhotoItem,
                            onCameraTap: { showCameraPicker = true },
                            onPhotoSelect: { image in
                                sendImageMessage(image)
                                withAnimation {
                                    showInitialCard = false
                                    activeDrawer = .none
                                }
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if activeDrawer == .emojiPicker {
                        ChatEmojiPickerDrawer(
                            onSelectEmoji: { emojiName in
                                sendEmojiMessage(emojiName)
                                withAnimation {
                                    showInitialCard = false
                                    activeDrawer = .none
                                }
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                
                // 원숭이 꼬리 드롭다운 식탁
                if isTailPulledDown {
                    VStack(spacing: 0) {
                        DiningDropSheet(
                            myUserName: myUserName,
                            myPost: myPost,
                            otherFamilyMembers: otherFamilyMembers
                        )
                        .frame(height: geometry.size.height * 0.65)
                        .background(Color.appHeader)
                        .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 6)
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                isTailPulledDown = false
                            }
                        }) {
                            VStack(spacing: 2) {
                                MonkeyTailShape()
                                    .stroke(Color.appTextBrown, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                    .frame(width: 34, height: 38)
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.appTextBrown)
                            }
                            .padding(6)
                        }
                        Spacer()
                    }
                    .transition(.move(edge: .top))
                    .zIndex(10)
                }
            }
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            CameraPickerView(selectedImage: $capturedImage)
                .ignoresSafeArea()
                .onChange(of: capturedImage) { _, newImg in
                    if let img = newImg {
                        sendImageMessage(img)
                        capturedImage = nil
                        activeDrawer = .none
                    }
                }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        sendImageMessage(uiImage)
                        activeDrawer = .none
                        selectedPhotoItem = nil
                    }
                }
            }
        }
        .onAppear {
                    lastProcessedMessageCount = messages.count
                    
                    FirebaseManager.shared.listenFamilyProfiles(familyId: myFamilyId) { profiles in
                        self.familyProfiles = profiles
                    }
                    
                    // ✅ 오늘 이미 대화가 오갔다면 키보드 위 추천 질문을 즉시 생성, 아니면 첫 말풍선 카드 생성
                    if hasTodayChatStarted {
                        showInitialCard = false
                        handleMidChatAIGeneration(newCount: messages.count, forceGenerate: true)
                    } else {
                        triggerInitialAIGeneration()
                    }
                }
        
        .onChange(of: isFieldFocused) { _, focused in
            if focused { activeDrawer = .none }
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isInputActive = focused || (activeDrawer != .none)
            }
        }
        .onChange(of: activeDrawer) { _, drawer in
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isInputActive = isFieldFocused || (drawer != .none)
            }
        }
        .onDisappear {
            isFieldFocused = false
            activeDrawer = .none
            isInputActive = false
        }
    }
    
    // MARK: - 맨 아래로 스크롤 이동 헬퍼
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if animated {
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo("bottomAnchor", anchor: .bottom)
                }
            } else {
                proxy.scrollTo("bottomAnchor", anchor: .bottom)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            if animated {
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo("bottomAnchor", anchor: .bottom)
                }
            } else {
                proxy.scrollTo("bottomAnchor", anchor: .bottom)
            }
        }
    }
    
    // MARK: - 1. 하루의 첫 대화 시작용 추천 생성 (AI 동적 생성)
    private func triggerInitialAIGeneration(force: Bool = false) {
        guard isAIChatSuggestEnabled else { return }
        
        // 오늘 이미 대화가 시작되었다면 첫 카드는 띄우지 않음
        if hasTodayChatStarted {
            showInitialCard = false
            return
        }
        
        if !force && !initialQuestions.isEmpty { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        self.targetMealTime = formatter.string(from: Date())
        
        if let targetMember = otherFamilyMembers.last(where: { $0.post != nil && $0.post?.image != nil }),
           let post = targetMember.post {
            // ✅ 다른 가족 구성원이 식탁 사진을 올린 경우 -> 사진 분석 기반 질문 AI 생성
            self.targetMemberName = targetMember.name
            self.hasTargetMealPhoto = true
            self.isInitialAILoading = true
            
            AIService.shared.generateQuestions(for: post.image, memo: post.text) { result in
                self.initialQuestions = result
                self.isInitialAILoading = false
            }
        } else {
            // ✅ 식탁에 아직 사진이 올라오지 않은 경우 -> 하드코딩 대신 AI에게 식사 독려/안부 질문을 생성하도록 요청
            self.targetMemberName = "가족"
            self.hasTargetMealPhoto = false
            self.isInitialAILoading = true
            
            let encouragementPrompt = "우리 가족 식탁에 아직 아무도 식사 사진을 올리지 않았어. 가족들에게 식사를 잘 챙겨 먹었는지 묻거나 오늘 뭐 먹을지, 식탁 사진을 올려달라고 따뜻하게 권유하는 안부 질문 3개를 17자 이내로 자연스럽게 추천해줘."
            
            AIService.shared.generateQuestions(for: nil, memo: encouragementPrompt) { result in
                if !result.isEmpty {
                    self.initialQuestions = result
                } else {
                    // API 일시 오류 대비 최소 백업 안전장치
                    self.initialQuestions = [
                        "오늘 다들 밥 챙겨 먹었어?",
                        "오늘 뭐 먹어? 식탁 올려줘!",
                        "오늘 맛있는 밥 챙겨 먹자~"
                    ]
                }
                self.isInitialAILoading = false
            }
        }
    }
    
    // MARK: - 대화 도중 키보드 위 추천 생성 함수 수정
    private func handleMidChatAIGeneration(newCount: Int, forceGenerate: Bool = false) {
        guard isAIChatSuggestEnabled else { return }
        
        let diff = newCount - lastProcessedMessageCount
        
        // forceGenerate(방 진입 시 또는 메시지 전송 직후)가 아닐 때의 최소 메시지 검사
        if !forceGenerate {
            guard hasTodayChatStarted else { return }
            guard diff >= 1 else { return }
        }
        
        lastProcessedMessageCount = newCount
        
        // 대화 내역이 있을 때 AI 추천 질문 요청
        if !messages.isEmpty {
            AIService.shared.generateQuestionsFromChat(recentMessages: messages) { result in
                if !result.isEmpty {
                    self.midChatQuestions = result
                } else {
                    // API 지연/오류 대비 기본 질문 채움
                    self.midChatQuestions = [
                        "다들 점심 챙겨 먹었어?",
                        "오늘 식탁 사진 기대돼!"
                    ]
                }
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.showMidChatSuggestions = true
                }
            }
        }
    }
    
    // MARK: - 메시지 전송 로직 (첫 말풍선 전송 직후 키보드 위 추천으로 즉각 전환)
    private func sendTextMessage(_ text: String, isFromInitialCard: Bool = false) {
        let sender = myUserName.isEmpty ? "가족" : myUserName
        FirebaseManager.shared.sendChatMessage(familyId: myFamilyId, senderName: sender, text: text)
        
        if isFromInitialCard || showInitialCard {
            withAnimation(.easeInOut(duration: 0.2)) {
                showInitialCard = false
            }
            // 첫 메시지 전송 후 0.3초 뒤 키보드 위 추천질문 즉각 생성 요청
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.handleMidChatAIGeneration(newCount: self.messages.count + 1, forceGenerate: true)
            }
        }
    }
    
    private func sendEmojiMessage(_ emojiName: String) {
        RecentEmojiManager.shared.addRecentEmoji(emojiName)
        let sender = myUserName.isEmpty ? "가족" : myUserName
        FirebaseManager.shared.sendChatMessage(familyId: myFamilyId, senderName: sender, text: "[emoji:\(emojiName)]")
    }
    
    // ⭕️ 사진 전송 로직
    private func sendImageMessage(_ image: UIImage) {
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        let timeStr = formatter.string(from: Date())
        
        let newMsg = ChatMessage(
            text: "사진",
            time: timeStr,
            senderName: myUserName.isEmpty ? "나" : myUserName,
            isFromMe: true,
            dateString: todayFormattedString,
            image: image,
            emojiName: nil
        )
        messages.append(newMsg)
        
        let sender = myUserName.isEmpty ? "가족" : myUserName
        FirebaseManager.shared.sendChatMessage(
            familyId: myFamilyId,
            senderName: sender,
            text: "사진을 공유했어요 📷",
            image: image
        )
    }
    
    private func loadRecentPhotos() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            guard status == .authorized || status == .limited else { return }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 3
            
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            let imageManager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = false
            requestOptions.deliveryMode = .highQualityFormat
            
            var loaded: [UIImage] = []
            let dispatchGroup = DispatchGroup()
            
            fetchResult.enumerateObjects { asset, _, _ in
                dispatchGroup.enter()
                let targetSize = CGSize(width: 300, height: 300)
                imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: requestOptions) { img, _ in
                    if let valid = img {
                        loaded.append(valid)
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.recentPhotos = loaded
            }
        }
    }
}

// MARK: - 하루 첫 대화 시작용 큰 추천 카드 (Chat.png 디자인: 3개 버튼)
struct InitialAISuggestionCard: View {
    var targetName: String = "가족"
    var hasTargetPhoto: Bool = true
    let questions: [String]
    var timeString: String = ""
    let onSelect: (String) -> Void
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            Spacer(minLength: 40)
            
            if !timeString.isEmpty {
                Text(timeString)
                    .font(.system(size: 11))
                    .foregroundColor(Color.appTextBrown.opacity(0.7))
                    .padding(.bottom, 2)
            }
            
            VStack(alignment: .trailing, spacing: 6) {
                // 상단 안내 뱃지 (사진 유무에 따라 문구 자동 대응)
                VStack(spacing: 0) {
                    Text(hasTargetPhoto ? "\(targetName)의 사진에 답장을 해보세요!" : "가족들에게 식사 안부를 전해보세요!")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.appTextBrown)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.chatBadgeBg)
                        .cornerRadius(14)
                    
                    BubbleTailShape()
                        .fill(Color.chatBadgeBg)
                        .frame(width: 10, height: 5)
                        .padding(.trailing, 20)
                }
                
                // 연녹색 박스 & 질문 버튼 목록 (최대 3개)
                VStack(spacing: 10) {
                    ForEach(Array(questions.prefix(3).enumerated()), id: \.offset) { _, question in
                        Button(action: { onSelect(question) }) {
                            Text(question)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.appTextBrown)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 12)
                                .background(Color.white)
                                .cornerRadius(20)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(14)
                .background(Color.chatSuggestBg)
                .cornerRadius(22)
            }
            .frame(maxWidth: 280)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

// MARK: - 채팅 입력 바
struct ChatInputBar: View {
    @Binding var inputText: String
    var isFocused: FocusState<Bool>.Binding
    var activeDrawer: ChatBottomDrawerType = .none
    var onTogglePlus: () -> Void = {}
    var onToggleDots: () -> Void = {}
    var onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Button(action: onTogglePlus) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(activeDrawer == .mediaPicker ? Color.sandBeige : Color.appActiveTab)
            }
            
            HStack {
                TextField("텍스트 입력", text: $inputText)
                    .focused(isFocused)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(20)
            
            Button(action: onSend) {
                Circle()
                    .fill(Color.appActiveTab)
                    .frame(width: 26, height: 26)
                    .overlay(
                        Image(systemName: "arrow.up")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            
            Button(action: onToggleDots) {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .font(.system(size: 20))
                    .foregroundColor(activeDrawer == .emojiPicker ? Color.sandBeige : Color.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.chatInputBarBg)
    }
}

// MARK: - 채팅 탭 + 버튼 서랍 (화면 너비 대응)
struct ChatMediaPickerDrawer: View {
    let recentPhotos: [UIImage]
    @Binding var selectedPhotoItem: PhotosPickerItem?
    var onCameraTap: () -> Void
    var onPhotoSelect: (UIImage) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("최근 사진")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.appTextBrown)
                
                Spacer()
                
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: 3) {
                        Text("More")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.appTextBrown)
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(Color.appActiveTab)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            
            GeometryReader { geo in
                let spacing: CGFloat = 8
                let availableWidth = geo.size.width
                let tileWidth = max(64, (availableWidth - (spacing * 3)) / 4)
                
                HStack(spacing: spacing) {
                    Button(action: onCameraTap) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .frame(width: tileWidth, height: tileWidth)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.appTextBrown.opacity(0.85))
                            )
                    }
                    
                    ForEach(0..<3, id: \.self) { idx in
                        if idx < recentPhotos.count {
                            Button(action: { onPhotoSelect(recentPhotos[idx]) }) {
                                Image(uiImage: recentPhotos[idx])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: tileWidth, height: tileWidth)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appCardBg.opacity(0.35))
                                .frame(width: tileWidth, height: tileWidth)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.white.opacity(0.6))
                                )
                        }
                    }
                }
            }
            .frame(height: 76)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.modalBg)
        .frame(maxWidth: .infinity)
        .clipped()
    }
}

// MARK: - 채팅 탭 ... 버튼 서랍 (감정 이모지 & 최근 사용)
struct ChatEmojiPickerDrawer: View {
    var onSelectEmoji: (String) -> Void
    
    @State private var selectedTab: EmojiTabType = .emotion
    @State private var recentEmojis: [String] = []
    
    let emojiList = (1...12).map { "emoji\($0)" }
    let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 4)
    
    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 28) {
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = .emotion }
                }) {
                    Text("감정 이모지")
                        .font(.system(size: 14, weight: selectedTab == .emotion ? .bold : .medium))
                        .foregroundColor(Color.appTextBrown)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 7)
                        .background(selectedTab == .emotion ? Color.sandBeige : Color.clear)
                        .cornerRadius(14)
                }
                
                Button(action: {
                    recentEmojis = RecentEmojiManager.shared.getRecentEmojis()
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = .recent }
                }) {
                    Text("최근 사용")
                        .font(.system(size: 14, weight: selectedTab == .recent ? .bold : .medium))
                        .foregroundColor(Color.appTextBrown)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 7)
                        .background(selectedTab == .recent ? Color.sandBeige : Color.clear)
                        .cornerRadius(14)
                }
                
                Spacer()
            }
            .padding(.top, 14)
            
            ZStack {
                if selectedTab == .emotion {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(emojiList, id: \.self) { icon in
                            Button(action: { onSelectEmoji(icon) }) {
                                Image(icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 52)
                            }
                        }
                    }
                } else {
                    if recentEmojis.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 26))
                                .foregroundColor(Color.appTextBrown.opacity(0.4))
                            Text("최근 사용한 감정 이모지가 없어요")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.appTextBrown.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity, minHeight: 140)
                    } else {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(recentEmojis, id: \.self) { icon in
                                Button(action: { onSelectEmoji(icon) }) {
                                    Image(icon)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 52)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(18)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(Color.modalBg)
        .onAppear {
            recentEmojis = RecentEmojiManager.shared.getRecentEmojis()
        }
    }
}

// MARK: - AI 추천 질문 말풍선 (대화 중 키보드 위 2개 가로 캡슐)
struct AISuggestionPanel: View {
    let questions: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(questions.prefix(2).enumerated()), id: \.offset) { _, question in
                Button(action: { onSelect(question) }) {
                    Text(question)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.appTextBrown)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .padding(.horizontal, 10)
                        .background(Color(red: 218/255, green: 196/255, blue: 158/255))
                        .cornerRadius(19)
                }
            }
        }
    }
}

// MARK: - 채팅 버블 행 (텍스트, 사진, 이모티콘 렌더링 완벽 지원)
struct ChatBubbleRow: View {
    let message: ChatMessage
    var senderProfile: (image: UIImage?, avatarName: String)? = nil
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromMe {
                Spacer()
                Text(message.time)
                    .font(.system(size: 11))
                    .foregroundColor(Color.appTextBrown.opacity(0.7))
                
                bubbleContent
            } else {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                    
                    if let profile = senderProfile {
                        if let customImg = profile.image {
                            Image(uiImage: customImg)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else if !profile.avatarName.isEmpty {
                            Image(profile.avatarName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        } else {
                            defaultAvatarView
                        }
                    } else {
                        defaultAvatarView
                    }
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    if !message.senderName.isEmpty {
                        Text(message.senderName)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.appTextBrown.opacity(0.7))
                            .padding(.leading, 4)
                    }
                    bubbleContent
                }
                
                Text(message.time)
                    .font(.system(size: 11))
                    .foregroundColor(Color.appTextBrown.opacity(0.7))
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var bubbleContent: some View {
        if let img = message.image {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: 190, maxHeight: 190)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        } else if let emoji = message.emojiName, UIImage(named: emoji) != nil {
            Image(emoji)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .padding(4)
        } else {
            Text(message.text)
                .font(.system(size: 14))
                .foregroundColor(Color.appTextBrown)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(18)
        }
    }
    
    private var defaultAvatarView: some View {
        Circle()
            .fill(Color.appHeader)
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: "face.smiling")
                    .foregroundColor(Color.appTextBrown)
            )
    }
}

// MARK: - 상단 원숭이 꼬리 드롭다운 식탁
struct DiningDropSheet: View {
    let myUserName: String
    let myPost: MealPost?
    let otherFamilyMembers: [FamilyMember]
    
    var totalCount: Int {
        otherFamilyMembers.count + 1
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("오늘의 가족 식탁")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.appTextBrown)
                Spacer()
                Text("\(totalCount)인 식탁")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(6)
                    .foregroundColor(Color.appTextBrown)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            ScrollView {
                VStack(spacing: 8) {
                    if totalCount <= 2 {
                        VStack(spacing: 8) {
                            if !otherFamilyMembers.isEmpty {
                                DropSheetSlotView(title: otherFamilyMembers[0].name, post: otherFamilyMembers[0].post)
                                    .frame(height: 120)
                            }
                            DropSheetSlotView(title: myUserName.isEmpty ? "나" : myUserName, post: myPost)
                                .frame(height: 120)
                        }
                    } else if totalCount == 3 {
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                DropSheetSlotView(title: otherFamilyMembers[0].name, post: otherFamilyMembers[0].post)
                                    .frame(height: 110)
                                if otherFamilyMembers.count > 1 {
                                    DropSheetSlotView(title: otherFamilyMembers[1].name, post: otherFamilyMembers[1].post)
                                        .frame(height: 110)
                                }
                            }
                            DropSheetSlotView(title: myUserName.isEmpty ? "나" : myUserName, post: myPost)
                                .frame(height: 110)
                        }
                    } else {
                        let columns = [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ]
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(otherFamilyMembers) { member in
                                DropSheetSlotView(title: member.name, post: member.post)
                                    .frame(height: 110)
                            }
                            DropSheetSlotView(title: myUserName.isEmpty ? "나" : myUserName, post: myPost)
                                .frame(height: 110)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }
}

struct DropSheetSlotView: View {
    let title: String
    let post: MealPost?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBg)
            
            if let post = post {
                VStack(spacing: 4) {
                    if let img = post.image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: 75)
                            .clipped()
                            .cornerRadius(8)
                    } else if let emoji = post.emojiName, !emoji.isEmpty {
                        Image(emoji)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 44)
                    } else {
                        Image(systemName: "fork.knife.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text("\(title): \(post.text)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 4)
                }
                .padding(6)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.5))
                    Text("\(title) 기다리는 중")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }
}

// MARK: - 3. Report Main Hub View
struct ReportMainView: View {
    @AppStorage("myFamilyId") private var myFamilyId: String = ""
    let myUserName: String
    let myPost: MealPost?
    let otherFamilyMembers: [FamilyMember]
    let chatLogs: [ChatMessage]
    var onBack: () -> Void

    @State private var showAllTables = false
    @State private var showNewspaperPopup = false
    @State private var navigateToNewspaperArchive = false
    @State private var latestArticle: NewspaperArticle? = nil
    @State private var isGeneratingNewspaper = false

    var todayPreviewImage: UIImage? {
        if let myImg = myPost?.image { return myImg }
        return otherFamilyMembers.compactMap { $0.post?.image }.first
    }

    private let cardWidth: CGFloat = 200
    private let cardHeight: CGFloat = 170
    private let subCardPeek: CGFloat = 35

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    CommonHeaderBar(title: "가족 기록", onBack: onBack)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("가족 기록")
                                .font(.system(size: 20, weight: .bold))
                                .padding(.top, 16)
                                .hidden()

                            // MARK: - 1. 식탁 리포트 섹션
                            VStack(alignment: .leading, spacing: 10) {
                                Text("식탁 리포트")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color.appTextBrown)

                                HStack(spacing: 16) {
                                    Button(action: { showAllTables = true }) {
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(Color(red: 175/255, green: 161/255, blue: 138/255))
                                                .frame(width: cardWidth + subCardPeek, height: cardHeight)

                                            ZStack {
                                                RoundedRectangle(cornerRadius: 14)
                                                    .fill(Color.appCardBg)

                                                if let preview = todayPreviewImage {
                                                    Color.clear
                                                        .overlay(
                                                            Image(uiImage: preview)
                                                                .resizable()
                                                                .scaledToFill()
                                                        )
                                                        .clipped()
                                                } else {
                                                    VStack(spacing: 6) {
                                                        Image(systemName: "fork.knife.circle.fill")
                                                            .font(.system(size: 36))
                                                            .foregroundColor(.white.opacity(0.75))
                                                        Text("오늘 식탁을 채워보세요")
                                                            .font(.system(size: 12, weight: .medium))
                                                            .foregroundColor(.white.opacity(0.8))
                                                    }
                                                }
                                            }
                                            .frame(width: cardWidth, height: cardHeight)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                            .shadow(color: Color.black.opacity(0.08), radius: 5, x: 2, y: 2)
                                        }
                                    }
                                    .buttonStyle(.plain)

                                    Spacer()

                                    Button(action: { showAllTables = true }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(Color.appActiveTab)
                                    }
                                }
                            }

                            // MARK: - 2. 끼니 신문 섹션
                            VStack(alignment: .leading, spacing: 10) {
                                Text("끼니 신문")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color.appTextBrown)

                                HStack(spacing: 16) {
                                    Button(action: { openOrGenerateNewspaper() }) {
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(Color.white.opacity(0.55))
                                                .frame(width: cardWidth + subCardPeek, height: cardHeight)

                                            ZStack {
                                                RoundedRectangle(cornerRadius: 14)
                                                    .fill(Color.white)
                                                    .shadow(color: Color.black.opacity(0.04), radius: 5, y: 2)

                                                if isGeneratingNewspaper {
                                                    VStack(spacing: 8) {
                                                        ProgressView().tint(Color.appTextBrown)
                                                        Text("AI 기자가 어제 식탁을\n분석하여 신문 발행 중...")
                                                            .font(.caption2)
                                                            .multilineTextAlignment(.center)
                                                            .foregroundColor(Color.appTextBrown.opacity(0.7))
                                                    }
                                                } else if let article = latestArticle {
                                                    VStack(alignment: .leading, spacing: 5) {
                                                        HStack {
                                                            Text("끼니 신문")
                                                                .font(.system(size: 12, weight: .bold))
                                                                .foregroundColor(Color.appTextBrown)
                                                            Spacer()
                                                            Text("제 \(article.issueNumber)호")
                                                                .font(.system(size: 9.5, weight: .medium))
                                                                .foregroundColor(Color.appTextBrown.opacity(0.6))
                                                        }
                                                        .padding(.horizontal, 10)
                                                        .padding(.top, 10)

                                                        Divider().padding(.horizontal, 10)

                                                        Text(article.mainTitle)
                                                            .font(.system(size: 10.5, weight: .heavy))
                                                            .foregroundColor(Color.appTextBrown)
                                                            .lineLimit(1)
                                                            .padding(.horizontal, 10)

                                                        HStack(spacing: 8) {
                                                            if let img = article.mainImage {
                                                                Image(uiImage: img)
                                                                    .resizable()
                                                                    .scaledToFill()
                                                                    .frame(width: 65, height: 60)
                                                                    .clipped()
                                                                    .cornerRadius(6)
                                                            } else {
                                                                RoundedRectangle(cornerRadius: 6)
                                                                    .fill(Color.appCardBg.opacity(0.15))
                                                                    .frame(width: 65, height: 60)
                                                                    .overlay(Image(systemName: "newspaper").foregroundColor(Color.appTextBrown.opacity(0.4)))
                                                            }

                                                            VStack(alignment: .leading, spacing: 2) {
                                                                Text(article.mainBoxTitle)
                                                                    .font(.system(size: 9, weight: .bold))
                                                                    .foregroundColor(Color.appTextBrown)
                                                                    .lineLimit(1)
                                                                Text(article.mainBoxContent)
                                                                    .font(.system(size: 7.5))
                                                                    .foregroundColor(Color.appTextBrown.opacity(0.7))
                                                                    .lineLimit(2)
                                                                Spacer()
                                                                Text("신문 보러가기 📰")
                                                                    .font(.system(size: 8, weight: .bold))
                                                                    .foregroundColor(Color.appActiveTab)
                                                            }
                                                            .frame(height: 60)
                                                        }
                                                        .padding(.horizontal, 10)
                                                        .padding(.bottom, 10)
                                                    }
                                                } else {
                                                    VStack(spacing: 6) {
                                                        Image(systemName: "newspaper.fill")
                                                            .font(.system(size: 30))
                                                            .foregroundColor(Color.appTextBrown.opacity(0.45))
                                                        Text("전날 식탁 바탕 브리핑")
                                                            .font(.caption2)
                                                            .foregroundColor(Color.appTextBrown.opacity(0.7))
                                                        Text("신문 발행하기 📰")
                                                            .font(.system(size: 10, weight: .bold))
                                                            .foregroundColor(Color.appActiveTab)
                                                    }
                                                }
                                            }
                                            .frame(width: cardWidth, height: cardHeight)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                        }
                                    }
                                    .buttonStyle(.plain)

                                    Spacer()

                                    Button(action: { openOrGenerateNewspaper() }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(Color.appActiveTab)
                                    }
                                }
                            }

                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationDestination(isPresented: $showAllTables) {
                ReportTableArchiveView(
                    myUserName: myUserName,
                    myPost: myPost,
                    otherFamilyMembers: otherFamilyMembers,
                    todayPreviewImage: todayPreviewImage,
                    chatLogs: chatLogs
                )
            }
            .navigationDestination(isPresented: $navigateToNewspaperArchive) {
                NewspaperArchiveMainView()
            }
            .overlay {
                if showNewspaperPopup, let article = latestArticle {
                    LatestNewspaperPopupView(
                        article: article,
                        onDismiss: { showNewspaperPopup = false },
                        onShowMore: {
                            showNewspaperPopup = false
                            navigateToNewspaperArchive = true
                        }
                    )
                }
            }
        }
        .onAppear {
            loadInitialNewspaperPreview()
        }
    }

    private func loadInitialNewspaperPreview() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayKey = formatter.string(from: yesterday)

        FirebaseManager.shared.fetchNewspaper(familyId: myFamilyId, dateString: yesterdayKey) { cachedDict in
            if let dict = cachedDict {
                self.latestArticle = NewspaperArticle.from(dict: dict, dateStr: yesterdayKey)
            }
        }
    }

    private func openOrGenerateNewspaper() {
        guard !isGeneratingNewspaper else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayKey = formatter.string(from: yesterday)

        FirebaseManager.shared.fetchNewspaper(familyId: myFamilyId, dateString: yesterdayKey) { cachedDict in
            if let dict = cachedDict {
                self.latestArticle = NewspaperArticle.from(dict: dict, dateStr: yesterdayKey)
                self.showNewspaperPopup = true
            } else {
                self.isGeneratingNewspaper = true

                FirebaseManager.shared.fetchArchivedMeals(familyId: myFamilyId, dateString: yesterdayKey) { mealDict in
                    var meals: [(userName: String, text: String, image: UIImage?)] = []
                    for (user, data) in mealDict {
                        if !data.text.isEmpty || data.image != nil {
                            meals.append((userName: user, text: data.text, image: data.image))
                        }
                    }

                    FirebaseManager.shared.fetchAllNewspapers(familyId: myFamilyId) { allList in
                        let nextIssueNumber = allList.count + 1

                        AIService.shared.generateNewspaperArticle(
                            yesterdayDateString: yesterdayKey,
                            issueNumber: nextIssueNumber,
                            familyMeals: meals
                        ) { generatedData in
                            var dataToSave = generatedData

                            if let mainImg = meals.compactMap({ $0.image }).first,
                               let jpeg = mainImg.jpegData(compressionQuality: 0.5) {
                                dataToSave["mainImageBase64"] = jpeg.base64EncodedString()
                            }
                            if meals.count > 1,
                               let subImg = meals.compactMap({ $0.image }).last,
                               let subJpeg = subImg.jpegData(compressionQuality: 0.5) {
                                dataToSave["subImageBase64"] = subJpeg.base64EncodedString()
                            }

                            FirebaseManager.shared.saveNewspaper(
                                familyId: myFamilyId,
                                dateString: yesterdayKey,
                                data: dataToSave
                            ) { _ in
                                self.isGeneratingNewspaper = false
                                self.latestArticle = NewspaperArticle.from(dict: dataToSave, dateStr: yesterdayKey)
                                self.showNewspaperPopup = true
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 3-1. 식탁 리포트 모아보기 (월별 가로 스크롤 & 전체 기록 노출)
struct ReportTableArchiveView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("myFamilyId") private var myFamilyId: String = ""
    
    let myUserName: String
    let myPost: MealPost?
    let otherFamilyMembers: [FamilyMember]
    let todayPreviewImage: UIImage?
    let chatLogs: [ChatMessage]
    
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedDailyReport: DailyReport? = nil
    @State private var reports: [DailyReport] = []
    @State private var reportPreviewImages: [String: UIImage] = [:]
    
    private let archiveCardWidth: CGFloat = 225
    private let archiveCardHeight: CGFloat = 240
    
    var reportsForSelectedYear: [DailyReport] {
        let yearPrefix = String(selectedYear)
        return reports.filter { $0.dateString.hasPrefix(yearPrefix) }
    }
    
    var distinctMonths: [String] {
        var months: [String] = []
        for r in reportsForSelectedYear {
            if !months.contains(r.monthString) {
                months.append(r.monthString)
            }
        }
        return months.sorted(by: >)
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CommonHeaderBar(title: "가족 기록", onBack: {
                    dismiss()
                })
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedYear -= 1
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color.appTextBrown)
                                    .padding(8)
                            }
                            
                            Text("\(String(selectedYear))")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundColor(Color.appTextBrown)
                                .padding(.horizontal, 10)
                            
                            Button(action: {
                                if selectedYear < currentYear {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedYear += 1
                                    }
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color.appTextBrown)
                                    .opacity(selectedYear >= currentYear ? 0.25 : 1.0)
                                    .padding(8)
                            }
                            .disabled(selectedYear >= currentYear)
                            
                            Spacer()
                        }
                        .padding(.top, 14)
                        .padding(.bottom, 6)
                        
                        if reportsForSelectedYear.isEmpty || distinctMonths.isEmpty {
                            emptyYearView
                        } else {
                            VStack(alignment: .leading, spacing: 24) {
                                ForEach(distinctMonths, id: \.self) { month in
                                    let monthReports = reportsForSelectedYear.filter { $0.monthString == month }
                                    
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(month)
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundColor(Color.appTextBrown)
                                            .padding(.horizontal, 20)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 12) {
                                                ForEach(monthReports) { report in
                                                    Button(action: {
                                                        selectedDailyReport = report
                                                    }) {
                                                        ZStack(alignment: .bottomLeading) {
                                                            RoundedRectangle(cornerRadius: 16)
                                                                .fill(Color.appCardBg)
                                                            
                                                            let previewImg = reportPreviewImages[report.dateString] ?? (report.isToday ? todayPreviewImage : nil)
                                                            
                                                            if let img = previewImg {
                                                                Color.clear
                                                                    .overlay(
                                                                        Image(uiImage: img)
                                                                            .resizable()
                                                                            .scaledToFill()
                                                                    )
                                                                    .clipped()
                                                            } else {
                                                                VStack(spacing: 8) {
                                                                    Image(systemName: "fork.knife.circle.fill")
                                                                        .font(.system(size: 40))
                                                                        .foregroundColor(.white.opacity(0.8))
                                                                    Text("\(report.dayString)일")
                                                                        .font(.system(size: 15, weight: .bold))
                                                                        .foregroundColor(.white)
                                                                }
                                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                            }
                                                            
                                                            Text(report.dateString)
                                                                .font(.system(size: 11, weight: .semibold))
                                                                .foregroundColor(.white)
                                                                .padding(.horizontal, 10)
                                                                .padding(.vertical, 6)
                                                                .background(Color.black.opacity(0.5))
                                                                .cornerRadius(8)
                                                                .padding(10)
                                                        }
                                                        .frame(width: archiveCardWidth, height: archiveCardHeight)
                                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                                        .shadow(color: Color.black.opacity(0.06), radius: 5, y: 2)
                                                    }
                                                    .buttonStyle(.plain)
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(item: $selectedDailyReport) { report in
            ReportDetailView(
                report: report,
                myUserName: myUserName,
                myPost: myPost,
                otherFamilyMembers: otherFamilyMembers
            )
        }
        .onAppear {
            loadReportsAndImages()
        }
    }
    
    private func loadReportsAndImages() {
        if reports.isEmpty {
            reports = DailyReport.createRecentReports(todayLogs: chatLogs)
        }
        
        for r in reports {
            FirebaseManager.shared.fetchArchivedMeals(familyId: myFamilyId, dateString: r.dateString) { mealDict in
                if let firstImg = mealDict.values.compactMap({ $0.image }).first {
                    DispatchQueue.main.async {
                        self.reportPreviewImages[r.dateString] = firstImg
                    }
                }
            }
        }
    }
    
    private var emptyYearView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("01")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.appTextBrown)
                .padding(.horizontal, 20)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appCardBg)
                            .frame(width: archiveCardWidth, height: archiveCardHeight)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.appCardBg)
                            
                            Text("기록된 식탁이 없습니다.")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(width: archiveCardWidth, height: archiveCardHeight)
                        .id("emptyCenterCard")
                        
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appCardBg)
                            .frame(width: archiveCardWidth, height: archiveCardHeight)
                    }
                    .padding(.horizontal, 20)
                }
                .onAppear {
                    proxy.scrollTo("emptyCenterCard", anchor: .center)
                }
                .onChange(of: selectedYear) { _, _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        proxy.scrollTo("emptyCenterCard", anchor: .center)
                    }
                }
            }
        }
        .padding(.bottom, 24)
    }
}

// MARK: - 3-2. 일별 상세 기록 View
struct ReportDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("myFamilyId") private var myFamilyId: String = ""
    
    let report: DailyReport
    let myUserName: String
    let myPost: MealPost?
    let otherFamilyMembers: [FamilyMember]
    
    @State private var archivedMeals: [String: (text: String, image: UIImage?, emoji: String?)] = [:]
    @State private var isLoading: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.appTextBrown)
                }
                Spacer()
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.appTextBrown)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.appHeader)
            
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text(report.dateString)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.appTextBrown)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    
                    VStack(spacing: 6) {
                        Text("가족들이 함께 완성한 식탁")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.appTextBrown)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ArchivedDiningSummaryTable(
                            reportDateString: report.dateString,
                            myUserName: myUserName,
                            myPost: myPost,
                            otherFamilyMembers: otherFamilyMembers,
                            archivedMeals: archivedMeals,
                            isToday: report.isToday
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Text(report.aiSummary)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.appTextBrown)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.reportAiBannerBg)
                    
                    HStack {
                        Rectangle().frame(height: 1).foregroundColor(Color.appTextBrown.opacity(0.4))
                        Text(report.dateString)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color.appTextBrown)
                            .padding(.horizontal, 8)
                        Rectangle().frame(height: 1).foregroundColor(Color.appTextBrown.opacity(0.4))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    
                    VStack(spacing: 14) {
                        ForEach(report.chatLogs) { log in
                            HStack(alignment: .bottom, spacing: 8) {
                                if log.isFromMe {
                                    Spacer()
                                    Text(log.time)
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.appTextBrown.opacity(0.7))
                                    
                                    bubbleContent(for: log)
                                } else {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 40, height: 40)
                                        .overlay(Image(systemName: "face.smiling").foregroundColor(Color.appTextBrown))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        if !log.senderName.isEmpty {
                                            Text(log.senderName)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(Color.appTextBrown.opacity(0.7))
                                                .padding(.leading, 4)
                                        }
                                        bubbleContent(for: log)
                                    }
                                    
                                    Text(log.time)
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.appTextBrown.opacity(0.7))
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            FirebaseManager.shared.fetchArchivedMeals(familyId: myFamilyId, dateString: report.dateString) { result in
                self.archivedMeals = result
                self.isLoading = false
            }
        }
    }
    
    @ViewBuilder
    private func bubbleContent(for log: ChatMessage) -> some View {
        if let img = log.image {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: 160, maxHeight: 160)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        } else {
            Text(log.text)
                .font(.system(size: 14))
                .foregroundColor(Color.appTextBrown)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.chatSuggestBg)
                .cornerRadius(18)
        }
    }
}

struct ArchivedDiningSummaryTable: View {
    let reportDateString: String
    let myUserName: String
    let myPost: MealPost?
    let otherFamilyMembers: [FamilyMember]
    let archivedMeals: [String: (text: String, image: UIImage?, emoji: String?)]
    let isToday: Bool
    
    var allMemberNames: [String] {
        var names: [String] = []
        for m in otherFamilyMembers {
            if !names.contains(m.name) { names.append(m.name) }
        }
        let me = myUserName.isEmpty ? "나" : myUserName
        if !names.contains(me) { names.append(me) }
        for k in archivedMeals.keys {
            if !names.contains(k) && k != "나" { names.append(k) }
        }
        return names.sorted()
    }
    
    func getMeal(for memberName: String) -> MealPost? {
        if let data = archivedMeals[memberName] {
            let hasContent = (data.image != nil) || (data.emoji != nil && !data.emoji!.isEmpty) || !data.text.isEmpty
            if hasContent {
                return MealPost(image: data.image, emojiName: data.emoji, text: data.text)
            }
        }
        if isToday {
            if memberName == myUserName || (memberName == "나" && myUserName.isEmpty) {
                return myPost
            }
            if let m = otherFamilyMembers.first(where: { $0.name == memberName }) {
                return m.post
            }
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if allMemberNames.count <= 2 {
                HStack(spacing: 8) {
                    ForEach(allMemberNames, id: \.self) { name in
                        DropSheetSlotView(title: name, post: getMeal(for: name))
                    }
                }
                .frame(height: 150)
            } else if allMemberNames.count == 3 {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        DropSheetSlotView(title: allMemberNames[0], post: getMeal(for: allMemberNames[0]))
                            .frame(height: 110)
                        DropSheetSlotView(title: allMemberNames[1], post: getMeal(for: allMemberNames[1]))
                            .frame(height: 110)
                    }
                    if allMemberNames.count > 2 {
                        DropSheetSlotView(title: allMemberNames[2], post: getMeal(for: allMemberNames[2]))
                            .frame(height: 110)
                    }
                }
            } else {
                let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(allMemberNames, id: \.self) { name in
                        DropSheetSlotView(title: name, post: getMeal(for: name))
                            .frame(height: 110)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.appPanelBg)
        .cornerRadius(16)
    }
}

// MARK: - 4. Upload Flow View (식탁 업로드 창 - [감정 이모지], [최근 사용] 2개 탭)
struct UploadFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("myFamilyId") private var myFamilyId: String = ""
    let currentUserName: String
    var initialPost: MealPost? = nil
    var onSave: (MealPost) -> Void
    
    @State private var uploadedImage: UIImage? = nil
    @State private var selectedEmoji: String? = nil
    @State private var inputText: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showEmojiDetailView = false
    @State private var showCameraPicker = false
    @State private var isUploading = false
    
    @State private var emojiModalTab: EmojiTabType = .emotion
    @State private var recentEmojis: [String] = []
    
    let emojiList = (1...12).map { "emoji\($0)" }
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    
    init(currentUserName: String, initialPost: MealPost? = nil, onSave: @escaping (MealPost) -> Void) {
        self.currentUserName = currentUserName
        self.initialPost = initialPost
        self.onSave = onSave
        _uploadedImage = State(initialValue: initialPost?.image)
        _selectedEmoji = State(initialValue: initialPost?.emojiName)
        _inputText = State(initialValue: initialPost?.text ?? "")
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        if showEmojiDetailView {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showEmojiDetailView = false
                            }
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.appTextBrown)
                    }
                    Spacer()
                    
                    if uploadedImage != nil || selectedEmoji != nil {
                        Button(isUploading ? "저장 중..." : "완료") {
                            guard !isUploading else { return }
                            isUploading = true
                            
                            FirebaseManager.shared.uploadMeal(
                                familyId: myFamilyId,
                                userName: currentUserName,
                                text: inputText,
                                image: uploadedImage,
                                emoji: selectedEmoji
                            ) { success in
                                isUploading = false
                                if success {
                                    onSave(MealPost(image: uploadedImage, emojiName: selectedEmoji, text: inputText))
                                    dismiss()
                                }
                            }
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.appActiveTab)
                        .disabled(isUploading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.appHeader)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(initialPost == nil ? "식탁 업로드" : "식탁 수정하기")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.appTextBrown)
                            .padding(.top, 14)
                        
                        HStack(spacing: 0) {
                            ZStack {
                                Color.appCardBg
                                if let img = uploadedImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .clipped()
                                } else if let emoji = selectedEmoji {
                                    Image(emoji)
                                        .resizable()
                                        .scaledToFit()
                                        .padding(14)
                                } else {
                                    Text("선택 없음")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            
                            ZStack(alignment: .topLeading) {
                                Color.white
                                TextField("텍스트 입력", text: $inputText, axis: .vertical)
                                    .padding(14)
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .frame(height: 160)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("갤러리")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color.appTextBrown)
                                Spacer()
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    HStack(spacing: 3) {
                                        Text("More")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Color.appTextBrown)
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color.appActiveTab)
                                    }
                                }
                            }
                            
                            HStack(spacing: 10) {
                                Button(action: { showCameraPicker = true }) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white)
                                        .frame(height: 70)
                                        .overlay(
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 22))
                                                .foregroundColor(Color.appTextBrown)
                                        )
                                }
                                
                                ForEach(1..<4) { _ in
                                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.appCardBg.opacity(0.4))
                                            .frame(height: 70)
                                            .overlay(Image(systemName: "photo").foregroundColor(.white.opacity(0.8)))
                                    }
                                }
                            }
                        }
                        .padding(14)
                        .background(Color.appPanelBg.opacity(0.7))
                        .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("이모지 선택")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color.appTextBrown)
                                Spacer()
                                Button(action: {
                                    recentEmojis = RecentEmojiManager.shared.getRecentEmojis()
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        showEmojiDetailView = true
                                    }
                                }) {
                                    HStack(spacing: 3) {
                                        Text("More")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Color.appTextBrown)
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color.appActiveTab)
                                    }
                                }
                            }
                            
                            HStack(spacing: 12) {
                                ForEach(emojiList.prefix(4), id: \.self) { icon in
                                    Button(action: {
                                        selectedEmoji = icon
                                        uploadedImage = nil
                                        RecentEmojiManager.shared.addRecentEmoji(icon)
                                    }) {
                                        Circle()
                                            .fill(Color.white.opacity(0.8))
                                            .frame(height: 60)
                                            .overlay(
                                                Image(icon)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .padding(8)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(14)
                        .background(Color.appPanelBg.opacity(0.7))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            if showEmojiDetailView {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showEmojiDetailView = false
                        }
                    }
                    .zIndex(90)
                
                VStack(spacing: 16) {
                    HStack(spacing: 28) {
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) { emojiModalTab = .emotion }
                        }) {
                            Text("감정 이모지")
                                .font(.system(size: 14, weight: emojiModalTab == .emotion ? .bold : .medium))
                                .foregroundColor(Color.appTextBrown)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 7)
                                .background(emojiModalTab == .emotion ? Color.appHeader : Color.clear)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            recentEmojis = RecentEmojiManager.shared.getRecentEmojis()
                            withAnimation(.easeInOut(duration: 0.2)) { emojiModalTab = .recent }
                        }) {
                            Text("최근 사용")
                                .font(.system(size: 14, weight: emojiModalTab == .recent ? .bold : .medium))
                                .foregroundColor(Color.appTextBrown)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 7)
                                .background(emojiModalTab == .recent ? Color.appHeader : Color.clear)
                                .cornerRadius(12)
                        }
                        Spacer()
                    }
                    
                    if emojiModalTab == .emotion {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(emojiList, id: \.self) { icon in
                                Button(action: {
                                    selectedEmoji = icon
                                    uploadedImage = nil
                                    RecentEmojiManager.shared.addRecentEmoji(icon)
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showEmojiDetailView = false
                                    }
                                }) {
                                    Circle()
                                        .fill(Color.white.opacity(0.9))
                                        .frame(height: 64)
                                        .overlay(
                                            Image(icon)
                                                .resizable()
                                                .scaledToFit()
                                                .padding(8)
                                        )
                                }
                            }
                        }
                    } else {
                        if recentEmojis.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 26))
                                    .foregroundColor(Color.appTextBrown.opacity(0.4))
                                Text("최근 사용한 감정 이모지가 없어요")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.appTextBrown.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity, minHeight: 140)
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(recentEmojis, id: \.self) { icon in
                                    Button(action: {
                                        selectedEmoji = icon
                                        uploadedImage = nil
                                        RecentEmojiManager.shared.addRecentEmoji(icon)
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showEmojiDetailView = false
                                        }
                                    }) {
                                        Circle()
                                            .fill(Color.white.opacity(0.9))
                                            .frame(height: 64)
                                            .overlay(
                                                Image(icon)
                                                    .resizable()
                                                    .scaledToFit()
                                                .padding(8)
                                            )
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color.appPanelBg)
                .cornerRadius(24, corners: [.topLeft, .topRight])
                .shadow(color: Color.black.opacity(0.2), radius: 12, y: -4)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            CameraPickerView(selectedImage: $uploadedImage)
                .ignoresSafeArea()
                .onChange(of: uploadedImage) { _, newImage in
                    if newImage != nil {
                        self.selectedEmoji = nil
                    }
                }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.uploadedImage = uiImage
                        self.selectedEmoji = nil
                    }
                }
            }
        }
    }
}

// MARK: - 화면 너비 유틸
struct UIScreenBounds {
    static var width: CGFloat {
        #if canImport(UIKit)
        return (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.bounds.width ?? 390
        #else
        return 390
        #endif
    }
}

// MARK: - 공통 헤더 컴포넌트
struct CommonHeaderBar: View {
    var title: String = ""
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
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.clear)
                    .frame(width: 30, height: 30, alignment: .leading)
            }
            
            Spacer()
            
            if !title.isEmpty {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.appTextBrown)
            }
            
            Spacer()
            
            Image(systemName: "ellipsis")
                .rotationEffect(.degrees(90))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.appTextBrown)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.appHeader)
    }
}

// MARK: - Custom Bottom Navigation Bar
struct CustomBottomBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            Spacer()
            TabBarItem(
                iconName: "characteremojitab",
                isCustomAsset: true,
                isSelected: selectedTab == 0
            ) { selectedTab = 0 }
            Spacer()
            TabBarItem(iconName: "bubble.left.and.bubble.right.fill", isSelected: selectedTab == 1) { selectedTab = 1 }
            Spacer()
            TabBarItem(iconName: "fork.knife", isSelected: selectedTab == 2) { selectedTab = 2 }
            Spacer()
            TabBarItem(iconName: "book.pages.fill", isSelected: selectedTab == 3) { selectedTab = 3 }
            Spacer()
            TabBarItem(iconName: "gearshape.fill", isSelected: selectedTab == 4) { selectedTab = 4 }
            Spacer()
        }
        .frame(height: 64)
        .background(Color.appBackground)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.black.opacity(0.05)), alignment: .top)
    }
}

struct TabBarItem: View {
    let iconName: String
    var isCustomAsset: Bool = false
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.appActiveTab : Color.clear)
                    .frame(width: 44, height: 44)
                
                if isCustomAsset {
                    Image(iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .opacity(isSelected ? 1.0 : 0.6)
                } else {
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .white : Color.appTextBrown.opacity(0.6))
                }
            }
        }
    }
}

// MARK: - CornerRadius Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - 시스템 카메라 연동 래퍼
struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPickerView

        init(_ parent: CameraPickerView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ContentView()
}
