import SwiftUI

// MARK: - 신문 기사 데이터 모델 (Base64 사진 영구 복원 추가)
struct NewspaperArticle: Identifiable, Hashable {
    var id: String { dateString }
    var issueNumber: Int
    var dateString: String       // "2026. 10. 15"
    var year: Int
    var month: String           // "10"
    
    // 메인 기사
    var mainTag: String
    var mainTitle: String
    var mainSubtitle: String
    var mainImage: UIImage?
    var mainBoxTitle: String
    var mainBoxContent: String
    var mainComment: String
    
    // 서브 기사
    var subTitle: String
    var subKeyword: String
    var subImage: UIImage?
    var subBoxTitle: String
    var subBoxContent: String
    var subComment: String
    
    // 캐릭터 성장 박스
    var characterDays: Int
    var characterMessage: String
    
    // Firestore Dictionary 변환 헬퍼 (Base64 이미지 복원)
    static func from(dict: [String: Any], dateStr: String) -> NewspaperArticle {
        let issue = dict["issueNumber"] as? Int ?? 1
        let comps = dateStr.split(separator: ".")
        let y = Int(comps.first?.trimmingCharacters(in: .whitespaces) ?? "2026") ?? 2026
        let m = comps.count > 1 ? String(comps[1].trimmingCharacters(in: .whitespaces)) : "01"
        
        // 메인 이미지 Base64 복원
        var mImage: UIImage? = nil
        if let base64 = dict["mainImageBase64"] as? String, !base64.isEmpty,
           let data = Data(base64Encoded: base64) {
            mImage = UIImage(data: data)
        }
        
        // 서브 이미지 Base64 복원
        var sImage: UIImage? = nil
        if let subBase64 = dict["subImageBase64"] as? String, !subBase64.isEmpty,
           let data = Data(base64Encoded: subBase64) {
            sImage = UIImage(data: data)
        }
        
        return NewspaperArticle(
            issueNumber: issue,
            dateString: dateStr,
            year: y,
            month: m,
            mainTag: dict["mainTag"] as? String ?? "[특종] 우리 가족",
            mainTitle: dict["mainTitle"] as? String ?? "여행 첫 끼니로 고기국수 선택!",
            mainSubtitle: dict["mainSubtitle"] as? String ?? "도착 30분만에 고기국수집으로 향한 사연은?",
            mainImage: mImage,
            mainBoxTitle: dict["mainBoxTitle"] as? String ?? "제주 레전드 맛집 발견!",
            mainBoxContent: dict["mainBoxContent"] as? String ?? "온 가족이 함께 모여 따뜻하고 든든한 한 끼를 나눴습니다.",
            mainComment: dict["mainComment"] as? String ?? "다 같이 먹으니 정말 꿀맛이야!",
            subTitle: dict["subTitle"] as? String ?? "우리 아빠는 요즘 무엇을 먹을까?",
            subKeyword: dict["subKeyword"] as? String ?? "디저트에 빠진 아부지",
            subImage: sImage,
            subBoxTitle: dict["subBoxTitle"] as? String ?? "아이스크림에 빠져버렸다!",
            subBoxContent: dict["subBoxContent"] as? String ?? "식사 후 달콤한 디저트의 유혹을 참지 못했다.",
            subComment: dict["subComment"] as? String ?? "달달하니 오늘 하루 피로가 다 풀리네~",
            characterDays: dict["characterDays"] as? Int ?? 3,
            characterMessage: dict["characterMessage"] as? String ?? "3일 연속 배부르게 끼니를 잘 챙겨주고 있어요!"
        )
    }
}

// MARK: - 1. 끼니 신문 낱장 컴포넌트 (Newspaper.png 1:1 컴팩트 비율)
struct NewspaperSheetCardView: View {
    let article: NewspaperArticle
    var onClose: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 우측 X 닫기 버튼
            if let onClose = onClose {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.appTextBrown.opacity(0.75))
                            .padding(6)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)
            }
            
            // 신문 헤더 (이중선)
            VStack(spacing: 3) {
                VStack(spacing: 1.5) {
                    Rectangle().frame(height: 1.5).foregroundColor(Color.appTextBrown.opacity(0.65))
                    Rectangle().frame(height: 1).foregroundColor(Color.appTextBrown.opacity(0.65))
                }
                
                HStack(alignment: .bottom) {
                    Spacer()
                    Text("끼니 신문")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color.appTextBrown)
                        .tracking(2)
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("제 \(article.issueNumber) 호")
                            .font(.system(size: 9.5, weight: .semibold))
                        Text(article.dateString)
                            .font(.system(size: 8.5))
                    }
                    .foregroundColor(Color.appTextBrown.opacity(0.7))
                }
                .padding(.horizontal, 4)
                
                Rectangle().frame(height: 1).foregroundColor(Color.appTextBrown.opacity(0.65))
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
            
            // 신문 본문 (공백 없이 밀도 있게 배치)
            VStack(spacing: 8) {
                // 1) 상단 메인 기사 박스
                VStack(alignment: .leading, spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(article.mainTag)
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(Color.appTextBrown.opacity(0.85))
                            Text(article.mainTitle)
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundColor(Color.appTextBrown)
                                .lineLimit(1)
                        }
                        Text(article.mainSubtitle)
                            .font(.system(size: 9.5))
                            .foregroundColor(Color.appTextBrown.opacity(0.65))
                            .lineLimit(1)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        // 메인 식탁 사진
                        Group {
                            if let img = article.mainImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.appCardBg.opacity(0.2))
                                    .overlay(
                                        Image(systemName: "fork.knife")
                                            .font(.system(size: 22))
                                            .foregroundColor(Color.appTextBrown.opacity(0.4))
                                    )
                            }
                        }
                        .frame(width: 115, height: 110)
                        .clipped()
                        .cornerRadius(8)
                        
                        // 기사 본문 요약 박스
                        VStack(alignment: .leading, spacing: 3) {
                            Text(article.mainBoxTitle)
                                .font(.system(size: 10.5, weight: .bold))
                                .foregroundColor(Color.appTextBrown)
                                .lineLimit(1)
                            
                            Text(article.mainBoxContent)
                                .font(.system(size: 9))
                                .foregroundColor(Color.appTextBrown.opacity(0.75))
                                .lineSpacing(2)
                                .lineLimit(4)
                            
                            Spacer(minLength: 2)
                            
                            // 한마디 코멘트 박스
                            VStack(spacing: 1) {
                                Text("가족의 한마디:")
                                    .font(.system(size: 6.5))
                                    .foregroundColor(.white.opacity(0.85))
                                Text("“\(article.mainComment)”")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 3.5)
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 185/255, green: 156/255, blue: 116/255))
                            .cornerRadius(5)
                        }
                        .padding(7)
                        .frame(height: 110)
                        .background(Color(red: 236/255, green: 224/255, blue: 204/255))
                        .cornerRadius(8)
                    }
                }
                .padding(10)
                .background(Color(red: 254/255, green: 247/255, blue: 238/255))
                .cornerRadius(10)
                
                // 2) 하단 서브 기사 & 캐릭터 박스 (1:1 비율 맞춤)
                HStack(alignment: .top, spacing: 8) {
                    // 좌측: 아빠/가족 서브 기사
                    VStack(alignment: .leading, spacing: 4) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(article.subTitle)
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(Color.appTextBrown.opacity(0.8))
                                .lineLimit(1)
                            Text(":\(article.subKeyword)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.appActiveTab)
                                .lineLimit(1)
                        }
                        
                        HStack(spacing: 6) {
                            Group {
                                if let subImg = article.subImage {
                                    Image(uiImage: subImg)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.appCardBg.opacity(0.2))
                                        .overlay(
                                            Image(systemName: "cup.and.saucer.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color.appTextBrown.opacity(0.4))
                                        )
                                }
                            }
                            .frame(width: 50, height: 60)
                            .clipped()
                            .cornerRadius(6)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(article.subBoxTitle)
                                    .font(.system(size: 8.5, weight: .bold))
                                    .foregroundColor(Color.appTextBrown)
                                    .lineLimit(1)
                                Text(article.subBoxContent)
                                    .font(.system(size: 7.5))
                                    .foregroundColor(Color.appTextBrown.opacity(0.75))
                                    .lineLimit(2)
                                
                                Spacer(minLength: 1)
                                
                                Text("“\(article.subComment)”")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color(red: 185/255, green: 156/255, blue: 116/255))
                                    .cornerRadius(3)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(height: 110)
                    .background(Color(red: 254/255, green: 247/255, blue: 238/255))
                    .cornerRadius(10)
                    
                    // 우측: 쑥쑥 자라고 있는 끼니 캐릭터 박스
                    VStack(alignment: .leading, spacing: 3) {
                        Text("쑥쑥 자라고 있는 끼니!")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.appTextBrown)
                        
                        Text(article.characterMessage)
                            .font(.system(size: 7.5))
                            .foregroundColor(Color.appTextBrown.opacity(0.7))
                            .lineLimit(1)
                        
                        Spacer()
                        
                        HStack {
                            Spacer()
                            Image("character_3d")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 65)
                            Spacer()
                        }
                    }
                    .padding(8)
                    .frame(width: 125, height: 110)
                    .background(Color(red: 254/255, green: 247/255, blue: 238/255))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.12), radius: 8, y: 3)
    }
}

// MARK: - 2. Newspaper.png 스플래시 팝업
struct LatestNewspaperPopupView: View {
    let article: NewspaperArticle
    var onDismiss: () -> Void
    var onShowMore: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            VStack(spacing: 10) {
                // 상단 도착 안내 말풍선
                VStack(spacing: 0) {
                    Text("“제 \(article.issueNumber)호 끼니 신문이 도착했어요!”")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(Color.appTextBrown)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.sandBeige)
                        .cornerRadius(14)
                    
                    BubbleTailShape()
                        .fill(Color.sandBeige)
                        .frame(width: 12, height: 6)
                }
                
                // 1:1 컴팩트 신문 카드
                NewspaperSheetCardView(article: article, onClose: onDismiss)
                    .padding(.horizontal, 22)
                
                // 하단 우측 "+ 신문 더보기"
                HStack {
                    Spacer()
                    Button(action: onShowMore) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 15))
                            Text("신문 더보기")
                                .font(.system(size: 13.5, weight: .bold))
                        }
                        .foregroundColor(Color.appActiveTab)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 13)
                        .background(Color.white)
                        .cornerRadius(18)
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    }
                    .padding(.trailing, 24)
                }
            }
        }
    }
}

// MARK: - 3. Newspaper1.png: 연도별/월별 가로 스크롤 신문 모아보기 화면
struct NewspaperArchiveMainView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("myFamilyId") private var myFamilyId: String = ""
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var allArticles: [NewspaperArticle] = []
    @State private var selectedArticleForDetail: NewspaperArticle? = nil
    
    // 월별 그룹핑
    var availableMonths: [String] {
        let yearArticles = allArticles.filter { $0.year == selectedYear }
        let months = Set(yearArticles.map { $0.month })
        return months.sorted(by: >)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CommonHeaderBar(title: "끼니 신문", onBack: {
                dismiss()
            })
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    
                    // 연도 네비게이션 (< 2026 >)
                    HStack {
                        Spacer()
                        Button(action: { selectedYear -= 1 }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .bold))
                        }
                        Text("\(String(selectedYear))")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal, 14)
                        Button(action: { selectedYear += 1 }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 15, weight: .bold))
                        }
                        Spacer()
                    }
                    .foregroundColor(Color.appTextBrown)
                    .padding(.top, 14)
                    
                    // 월별 가로 스크롤 섹션
                    if availableMonths.isEmpty {
                        VStack(spacing: 10) {
                            Spacer(minLength: 60)
                            Image(systemName: "newspaper")
                                .font(.system(size: 40))
                                .foregroundColor(Color.appTextBrown.opacity(0.3))
                            Text("발행된 신문이 아직 없습니다.")
                                .font(.system(size: 14))
                                .foregroundColor(Color.appTextBrown.opacity(0.6))
                            Spacer(minLength: 60)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(availableMonths, id: \.self) { month in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(month)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color.appTextBrown)
                                    .padding(.horizontal, 22)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        let monthItems = allArticles.filter { $0.year == selectedYear && $0.month == month }
                                        ForEach(monthItems) { item in
                                            Button(action: {
                                                selectedArticleForDetail = item
                                            }) {
                                                NewspaperSheetCardView(article: item, onClose: nil)
                                                    .frame(width: 290, height: 380)
                                                    .scaleEffect(0.82)
                                                    .frame(width: 245, height: 320)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal, 22)
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .background(Color.appBackground)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            loadAllNewspapers()
        }
        // 과거 신문 터치 시 상세 팝업
        .overlay {
            if let detail = selectedArticleForDetail {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                        .onTapGesture { selectedArticleForDetail = nil }
                    
                    VStack(spacing: 10) {
                        HStack {
                            Text(detail.dateString)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: { selectedArticleForDetail = nil }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        NewspaperSheetCardView(article: detail, onClose: nil)
                            .padding(.horizontal, 18)
                    }
                }
            }
        }
    }
    
    private func loadAllNewspapers() {
        FirebaseManager.shared.fetchAllNewspapers(familyId: myFamilyId) { list in
            if !list.isEmpty {
                self.allArticles = list.compactMap { dict in
                    guard let dateStr = dict["dateString"] as? String else { return nil }
                    return NewspaperArticle.from(dict: dict, dateStr: dateStr)
                }
            } else {
                // 저장된 신문이 없을 경우 보여줄 기본 예시 신문들
                self.allArticles = [
                    NewspaperArticle.from(dict: ["issueNumber": 2, "mainTitle": "여행 첫 끼니로 고기국수 선택!"], dateStr: "2026. 01. 02"),
                    NewspaperArticle.from(dict: ["issueNumber": 1, "mainTitle": "새해 첫날 떡국으로 활기찬 시작!"], dateStr: "2026. 01. 01"),
                    NewspaperArticle.from(dict: ["issueNumber": 12, "mainTitle": "전주 콩나물국밥 선택!"], dateStr: "2026. 02. 02")
                ]
            }
        }
    }
}
