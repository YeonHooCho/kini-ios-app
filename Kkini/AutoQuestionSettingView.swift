import SwiftUI

// MARK: - AI 자동 추천 질문 상세 설정 화면
struct AutoQuestionSettingView: View {
    var onBack: () -> Void
    
    // 💡 메인 토글 연동 (@AppStorage)
    @AppStorage("isAIChatSuggestEnabled") private var isAIChatSuggestEnabled: Bool = true
    
    // 💡 AI 질문 말투 스타일 (1: 다정한 가족 말투, 2: 유쾌한 장난 말투, 3: 정중한 예의 말투)
    @AppStorage("aiQuestionTone") private var aiQuestionTone: String = "friendly"
    
    // 💡 질문 분석 범위 (true: 식사 사진 + 최근 채팅 대화 종합, false: 식사 사진만)
    @AppStorage("aiIncludeChatContext") private var aiIncludeChatContext: Bool = true

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
                    Text("자동 질문 설정")
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
                        
                        // MARK: - 1. AI 추천 활성화 마스터 스위치
                        VStack(alignment: .leading, spacing: 10) {
                            Text("기능 활성화")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.appTextBrown.opacity(0.8))
                                .padding(.horizontal, 4)
                            
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(Color(red: 254/255, green: 242/255, blue: 228/255))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "lightbulb")
                                            .font(.system(size: 20))
                                            .foregroundColor(Color.appTextBrown)
                                    )
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("AI 추천 질문 표시")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(Color.appTextBrown)
                                    Text("채팅방 입력창 위에 대화 추천 말풍선 표시")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.appTextBrown.opacity(0.65))
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $isAIChatSuggestEnabled)
                                    .labelsHidden()
                                    .tint(Color.appActiveTab)
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                        }
                        
                        // MARK: - 2. AI 말투 스타일 (단일 선택)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("추천 질문 말투 스타일")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.appTextBrown.opacity(0.8))
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                toneOptionRow(
                                    key: "friendly",
                                    title: "다정하고 따뜻한 말투",
                                    desc: "가족 간의 따뜻한 안부와 공감을 건네는 기본 말투",
                                    isLast: false
                                )
                                
                                toneOptionRow(
                                    key: "playful",
                                    title: "유쾌하고 장난스러운 말투",
                                    desc: "한입만 찬스, 가벼운 장난 등 위트 있는 가족 티키타카 말투",
                                    isLast: false
                                )
                                
                                toneOptionRow(
                                    key: "polite",
                                    title: "정중하고 차분한 말투",
                                    desc: "예의 바른 존댓말과 정갈한 어조로 건네는 질문",
                                    isLast: true
                                )
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                        }
                        .opacity(isAIChatSuggestEnabled ? 1.0 : 0.45)
                        .disabled(!isAIChatSuggestEnabled)
                        
                        // MARK: - 3. 질문 생성 분석 범위
                        VStack(alignment: .leading, spacing: 10) {
                            Text("분석 데이터 범위")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.appTextBrown.opacity(0.8))
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                HStack(spacing: 14) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("최근 가족 대화 맥락 반영")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(Color.appTextBrown)
                                        Text("식탁 사진뿐만 아니라 최근 채팅 대화 내용까지 고려해 질문을 추천합니다.")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.appTextBrown.opacity(0.65))
                                            .lineSpacing(2)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $aiIncludeChatContext)
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
                        .opacity(isAIChatSuggestEnabled ? 1.0 : 0.45)
                        .disabled(!isAIChatSuggestEnabled)
                        
                        // 하단 정보 안내
                        Text("• 추천 질문은 채팅창 하단 입력창 바로 위에 17자 이내의 말풍선 2개로 표시됩니다.")
                            .font(.system(size: 12))
                            .foregroundColor(Color.appTextBrown.opacity(0.6))
                            .padding(.horizontal, 8)
                            .lineSpacing(4)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
        }
    }
    
    // 말투 선택 라디오 행 컴포넌트
    private func toneOptionRow(key: String, title: String, desc: String, isLast: Bool) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                aiQuestionTone = key
            }
        }) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.appTextBrown)
                        Text(desc)
                            .font(.system(size: 12))
                            .foregroundColor(Color.appTextBrown.opacity(0.65))
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(aiQuestionTone == key ? Color.appActiveTab : Color.appTextBrown.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)
                        
                        if aiQuestionTone == key {
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
