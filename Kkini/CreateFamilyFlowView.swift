import SwiftUI

struct CreateFamilyFlowView: View {
    var onBackToRoot: () -> Void                                   // 온보딩 첫 화면으로 나가기
    var onComplete: (_ familyId: String, _ nickname: String) -> Void // 최종 완료 후 메인 식탁 진입

    @State private var currentStep: Int = 1 // 1: 프로필, 2: 사용목적, 3: 초대, 4: 완료

    // Step 1: 프로필 입력값
    @State private var inputNickname: String = ""
    @State private var inputBirthday: String = ""
    @State private var inputRelation: String = ""
    @State private var inputPhone: String = ""
    @State private var isSmsSent: Bool = false // UT용 안내 토글

    // Step 2: 사용 목적 (16개 키워드 중 3개 이상 선택)
    @State private var selectedPurposes: Set<String> = []
    let purposeKeywords: [[String]] = [
        ["친밀감", "유대감", "애착", "소속감"],
        ["소통", "대화", "연결", "교류"],
        ["공감", "이해", "관심", "배려"],
        ["신뢰", "애정", "안정감", "편안함"]
    ]

    // Step 3: 발급된 6자리 가족 코드
    @State private var generatedFamilyCode: String = ""
    @State private var isCreatingRoom: Bool = false
    @State private var showCopyToast: Bool = false

    // 디자인 테마 컬러
    private let appBg = Color(red: 254/255, green: 247/255, blue: 236/255)
    private let textDarkBrown = Color(red: 84/255, green: 68/255, blue: 44/255)
    private let primaryBrown = Color(red: 163/255, green: 132/255, blue: 82/255)
    private let stepBtnBg = Color(red: 206/255, green: 184/255, blue: 150/255)
    private let inputBg = Color(red: 252/255, green: 249/255, blue: 244/255)
    private let progressGreen = Color(red: 147/255, green: 174/255, blue: 122/255)

    var body: some View {
        ZStack {
            appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - 상단 고정 헤더 & 4단계 진행 바
                topHeaderAndProgressBar

                // MARK: - 단계별 화면 전환
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        switch currentStep {
                        case 1:
                            step1ProfileView
                        case 2:
                            step2PurposeView
                        case 3:
                            step3InviteView
                        case 4:
                            step4CompletedView
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 30)
                }

                Spacer(minLength: 0)

                // MARK: - 하단 좌측 뒤로가기 화살표
                HStack {
                    Button(action: handleBackNavigation) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(textDarkBrown)
                            .padding(14)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            // 복사 완료 토스트
            if showCopyToast {
                VStack {
                    Spacer()
                    Text("초대 코드가 복사되었습니다.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.75))
                        .clipShape(Capsule())
                        .padding(.bottom, 80)
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            // 기본 코드 사전 발급
            if generatedFamilyCode.isEmpty {
                generatedFamilyCode = FirebaseManager.shared.generateRandomFamilyCode()
            }
        }
    }

    // MARK: - 상단 헤더 & 프로그레스 바
    private var topHeaderAndProgressBar: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("가족 식탁 생성하기")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(textDarkBrown)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            // 진행 바 & 레이블
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(progressGreen.opacity(0.3))
                            .frame(height: 3)

                        Rectangle()
                            .fill(progressGreen)
                            .frame(width: geo.size.width * CGFloat(currentStep) / 4.0, height: 3)
                    }
                }
                .frame(height: 3)

                // 단계 텍스트 위치 동적 표시
                HStack {
                    if currentStep == 1 {
                        Text("프로필 생성")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textDarkBrown.opacity(0.8))
                        Spacer()
                    } else if currentStep == 2 {
                        Spacer()
                        Text("사용 목적")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textDarkBrown.opacity(0.8))
                        Spacer()
                    } else if currentStep == 3 {
                        Spacer()
                        Text("구성원 초대")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textDarkBrown.opacity(0.8))
                            .padding(.trailing, 40)
                    } else {
                        Spacer()
                        Text("시작하기")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textDarkBrown.opacity(0.8))
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - [Step 1] onboarding_식탁생성.png (프로필 생성)
    private var step1ProfileView: some View {
        VStack(alignment: .leading, spacing: 22) {
            // 1. 닉네임 + 툴팁
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("닉네임")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(textDarkBrown)

                    // 말풍선 툴팁
                    HStack(spacing: 0) {
                        LeftPointerTriangle()
                            .fill(stepBtnBg)
                            .frame(width: 6, height: 10)
                        Text("가족끼리 부르는 애칭도 좋아요!")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(textDarkBrown)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(stepBtnBg)
                            .cornerRadius(10)
                    }
                }

                TextField("", text: $inputNickname)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(inputBg)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06), lineWidth: 1))
            }

            // 2. 생일
            VStack(alignment: .leading, spacing: 8) {
                Text("생일")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(textDarkBrown)

                TextField("생년월일 8자리", text: $inputBirthday)
                    .keyboardType(.numberPad)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(inputBg)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06), lineWidth: 1))
            }

            // 3. 가족과의 관계
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("가족과의 관계")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(textDarkBrown)
                    Text("ex) 장남, 막내딸, 아버지...")
                        .font(.system(size: 12))
                        .foregroundColor(textDarkBrown.opacity(0.6))
                }

                TextField("", text: $inputRelation)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(inputBg)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06), lineWidth: 1))
            }

            // 4. 휴대폰 번호 (UT용: 인증번호 절차 없이 패스)
            VStack(alignment: .leading, spacing: 8) {
                Text("휴대폰 번호")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(textDarkBrown)

                HStack(spacing: 10) {
                    TextField("", text: $inputPhone)
                        .keyboardType(.phonePad)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(inputBg)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06), lineWidth: 1))

                    Button(action: { isSmsSent = true }) {
                        Text(isSmsSent ? "인증 완료" : "인증번호 받기")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textDarkBrown.opacity(0.7))
                            .padding(.horizontal, 14)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06), lineWidth: 1))
                    }
                }
            }

            // 하단 버튼 바
            HStack {
                stepNavButton(title: "이전 단계", isPrevious: true) {
                    onBackToRoot()
                }
                Spacer()
                stepNavButton(title: "다음 단계", isPrevious: false, isDisabled: inputNickname.trimmingCharacters(in: .whitespaces).isEmpty) {
                    currentStep = 2
                }
            }
            .padding(.top, 20)
        }
    }

    // MARK: - [Step 2] onboarding_생성세부.png (사용 목적 16개 선택)
    private var step2PurposeView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("가족과의 관계, 가장 얻고 싶은 것은?")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(textDarkBrown)

                Text("3가지 이상 선택해주세요")
                    .font(.system(size: 13))
                    .foregroundColor(textDarkBrown.opacity(0.8))
            }
            .padding(.top, 10)

            // 4x4 원형 그리드
            VStack(spacing: 16) {
                ForEach(purposeKeywords, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { item in
                            let isSelected = selectedPurposes.contains(item)
                            Button(action: {
                                if isSelected {
                                    selectedPurposes.remove(item)
                                } else {
                                    selectedPurposes.insert(item)
                                }
                            }) {
                                Text(item)
                                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : textDarkBrown)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 72)
                                    .background(isSelected ? progressGreen : Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(isSelected ? 0.08 : 0.03), radius: 4, y: 2)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 10)

            // 하단 버튼 바 (3개 이상 선택 시 '다음 단계' 활성화)
            HStack {
                stepNavButton(title: "이전 단계", isPrevious: true) {
                    currentStep = 1
                }
                Spacer()
                stepNavButton(
                    title: isCreatingRoom ? "방 생성 중..." : "다음 단계",
                    isPrevious: false,
                    isDisabled: selectedPurposes.count < 3 || isCreatingRoom
                ) {
                    createFirebaseRoomAndProceed()
                }
            }
            .padding(.top, 10)
        }
    }

    // MARK: - [Step 3] onboarding_생성초대.png (코드 생성 및 공유)
    private var step3InviteView: some View {
        VStack(spacing: 36) {
            Text("함께 참여하고싶은 가족을 초대해주세요!")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(textDarkBrown)
                .padding(.top, 30)

            // 초대 코드 표시 박스
            HStack {
                Text("초대 코드: \(generatedFamilyCode)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(textDarkBrown)

                Spacer()

                Button(action: {
                    UIPasteboard.general.string = generatedFamilyCode
                    triggerCopyToast()
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 18))
                        .foregroundColor(textDarkBrown.opacity(0.8))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)

            // 카카오톡 & 링크 공유 버튼
            HStack(spacing: 30) {
                // 카카오톡 버튼
                Button(action: {
                    UIPasteboard.general.string = "가족 식탁에 초대합니다! 초대 코드: [\(generatedFamilyCode)]"
                    triggerCopyToast()
                }) {
                    Circle()
                        .fill(stepBtnBg)
                        .frame(width: 66, height: 66)
                        .overlay(
                            Text("TALK")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.yellow)
                                .padding(8)
                                .background(Circle().fill(Color.black))
                        )
                }

                // 링크 복사 버튼
                Button(action: {
                    UIPasteboard.general.string = "https://kkini.app/invite/\(generatedFamilyCode)"
                    triggerCopyToast()
                }) {
                    Circle()
                        .fill(stepBtnBg)
                        .frame(width: 66, height: 66)
                        .overlay(
                            Image(systemName: "paperclip")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(textDarkBrown)
                        )
                }
            }
            .padding(.top, 10)

            Spacer().frame(height: 40)

            // 하단 버튼 바
            HStack {
                stepNavButton(title: "이전 단계", isPrevious: true) {
                    currentStep = 2
                }
                Spacer()
                stepNavButton(title: "다음 단계", isPrevious: false) {
                    currentStep = 4
                }
            }
        }
    }

    // MARK: - [Step 4] onboarding_생성완료.png (생성 완료)
    private var step4CompletedView: some View {
        VStack(spacing: 28) {
            Spacer().frame(height: 50)

            Text("가족 식탁이 생성이 완료되었습니다!")
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(textDarkBrown)
                .multilineTextAlignment(.center)

            // 끼니 시작하기 메인 버튼
            Button(action: {
                let finalName = inputNickname.trimmingCharacters(in: .whitespaces)
                onComplete(generatedFamilyCode, finalName)
            }) {
                Text("끼니 시작하기")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(primaryBrown)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 8)

            Spacer().frame(height: 80)

            // 하단 이전 단계 버튼
            HStack {
                stepNavButton(title: "이전 단계", isPrevious: true) {
                    currentStep = 3
                }
                Spacer()
            }
        }
    }

    // MARK: - Helper UI & 로직
    private func stepNavButton(title: String, isPrevious: Bool, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isPrevious { Image(systemName: "arrow.left").font(.system(size: 11, weight: .bold)) }
                Text(title).font(.system(size: 13, weight: .bold))
                if !isPrevious { Image(systemName: "arrow.right").font(.system(size: 11, weight: .bold)) }
            }
            .foregroundColor(textDarkBrown.opacity(isDisabled ? 0.35 : 0.85))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(stepBtnBg.opacity(isDisabled ? 0.45 : 1.0))
            .cornerRadius(10)
        }
        .disabled(isDisabled)
    }

    private func handleBackNavigation() {
        if currentStep > 1 {
            currentStep -= 1
        } else {
            onBackToRoot()
        }
    }

    private func createFirebaseRoomAndProceed() {
        isCreatingRoom = true
        let trimmedUser = inputNickname.trimmingCharacters(in: .whitespaces)

        // 고른 목적 키워드 3개 이상 배열을 Firestore 방 생성 시 전달
        FirebaseManager.shared.createNewFamily(
            creatorName: trimmedUser,
            purposes: Array(selectedPurposes)
        ) { newCode in
            isCreatingRoom = false
            if let newCode = newCode {
                self.generatedFamilyCode = newCode
            }
            self.currentStep = 3
        }
    }

    private func triggerCopyToast() {
        withAnimation { showCopyToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { showCopyToast = false }
        }
    }
}

// 툴팁용 왼쪽 삼각형 셰이프
struct LeftPointerTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
