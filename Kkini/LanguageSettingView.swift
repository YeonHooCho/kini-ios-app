import SwiftUI

// MARK: - 언어 설정 상세 화면
struct LanguageSettingView: View {
    var onBack: () -> Void
    
    // 💡 선택된 언어 키 영구 저장 (기본값: "ko")
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ko"

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
                    Text("언어 설정")
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
                        
                        Text("지원 언어")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.appTextBrown.opacity(0.8))
                            .padding(.top, 16)
                            .padding(.horizontal, 4)
                        
                        // 언어 선택 라디오 카드
                        VStack(spacing: 0) {
                            languageOptionRow(
                                code: "ko",
                                title: "한국어",
                                subtitle: "Korean",
                                isLast: false
                            )
                            
                            languageOptionRow(
                                code: "en",
                                title: "English",
                                subtitle: "영어",
                                isLast: false
                            )
                            
                            languageOptionRow(
                                code: "system",
                                title: "시스템 기본값",
                                subtitle: "기기 설정 언어 따름",
                                isLast: true
                            )
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                        
                        // 하단 안내 문구
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• 언어를 변경하면 앱의 메뉴 텍스트 및 기본 안내 문구가 해당 언어로 적용됩니다.")
                            Text("• AI 생성 질문과 끼니 신문은 가족들이 작성한 언어 문맥을 유지하여 생성됩니다.")
                        }
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
    
    // 언어 선택 라디오 행
    private func languageOptionRow(code: String, title: String, subtitle: String, isLast: Bool) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedLanguage = code
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.appTextBrown)
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(Color.appTextBrown.opacity(0.65))
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(selectedLanguage == code ? Color.appActiveTab : Color.appTextBrown.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)
                        
                        if selectedLanguage == code {
                            Circle()
                                .fill(Color.appActiveTab)
                                .frame(width: 10, height: 10)
                        }
                    }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                
                if !isLast {
                    Divider()
                        .background(Color.appTextBrown.opacity(0.12))
                        .padding(.horizontal, 16)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
