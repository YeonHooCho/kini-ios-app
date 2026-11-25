import SwiftUI

struct JoinFamilyFlowView: View {
    var onBackToRoot: () -> Void                                   // 온보딩 첫 화면으로 나가기
    var onComplete: (_ familyId: String, _ nickname: String) -> Void // 최종 참여 완료 후 메인 식탁 진입

    @State private var currentStep: Int = 1 // 1: 코드 입력, 2: 프로필 생성, 3: 참여 완료

    // Step 1: 초대 코드 입력 상태
    @State private var inputFamilyCode: String = ""
    @State private var isValidatingCode: Bool = false
    @State private var codeErrorMessage: String? = nil

    // Step 2: 참여자 프로필 정보
    @State private var inputNickname: String = ""
    @State private var inputBirthday: String = ""
    @State private var inputRelation: String = ""
    @State private var inputPhone: String = ""
    @State private var isSmsSent: Bool = false // UT용 안내 토글

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
                // MARK: - 상단 고정 헤더 & 3단계 진행 바
                topHeaderAndProgressBar

                // MARK: - 단계별 화면 전환
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        switch currentStep {
                        case 1:
                            step1CodeInputView
                        case 2:
                            step2ProfileView
                        case 3:
                            step3CompletedView
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
        }
    }

    // MARK: - 상단 헤더 & 3단계 프로그레스 바
    private var topHeaderAndProgressBar: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("가족 식탁 참여하기")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(textDarkBrown)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(progressGreen.opacity(0.3))
                            .frame(height: 3)

                        Rectangle()
                            .fill(progressGreen)
                            .frame(width: geo.size.width * CGFloat(currentStep) / 3.0, height: 3)
                    }
                }
                .frame(height: 3)

                HStack {
                    if currentStep == 1 {
                        Text("구성원 초대")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textDarkBrown.opacity(0.8))
                        Spacer()
                    } else if currentStep == 2 {
                        Spacer()
                        Text("프로필 생성")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textDarkBrown.opacity(0.8))
                        Spacer()
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

    // MARK: - [Step 1] onboarding_식탁참여.png (초대 코드 입력)
    private var step1CodeInputView: some View {
        VStack(spacing: 28) {
            Text("가족의 초대 코드를 입력해주세요!")
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(textDarkBrown)
                .padding(.top, 36)

            // 초대 코드 입력 캡슐 박스
            HStack(spacing: 8) {
                Text("초대 코드:")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(textDarkBrown)

                TextField("6자리 코드 입력", text: $inputFamilyCode)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(textDarkBrown)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)

                Button(action: pasteFromClipboard) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 18))
                        .foregroundColor(textDarkBrown.opacity(0.8))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)

            // 오류 메시지 표시
            if let error = codeErrorMessage {
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red.opacity(0.85))
            }

            Spacer().frame(height: 120)

            // 하단 버튼 바 (우측 다음 단계만 배치)
            HStack {
                Spacer()
                stepNavButton(
                    title: isValidatingCode ? "확인 중..." : "다음 단계",
                    isPrevious: false,
                    isDisabled: inputFamilyCode.trimmingCharacters(in: .whitespaces).isEmpty || isValidatingCode
                ) {
                    validateAndProceed()
                }
            }
        }
    }

    // MARK: - [Step 2] onboarding_참여프로필설정.png (프로필 생성)
    private var step2ProfileView: some View {
        VStack(alignment: .leading, spacing: 22) {
            // 1. 닉네임 + 툴팁
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("닉네임")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(textDarkBrown)

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

            // 4. 휴대폰 번호 (UT용 간소화)
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

            // 하단 버튼 바 (이전 단계 & 다음 단계)
            HStack {
                stepNavButton(title: "이전 단계", isPrevious: true) {
                    currentStep = 1
                }
                Spacer()
                stepNavButton(
                    title: "다음 단계",
                    isPrevious: false,
                    isDisabled: inputNickname.trimmingCharacters(in: .whitespaces).isEmpty
                ) {
                    currentStep = 3
                }
            }
            .padding(.top, 20)
        }
    }

    // MARK: - [Step 3] onboarding_참여완료.png (참여 완료)
    private var step3CompletedView: some View {
        VStack(spacing: 28) {
            Spacer().frame(height: 50)

            Text("참여 준비가 완료되었습니다!")
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(textDarkBrown)
                .multilineTextAlignment(.center)

            // 끼니 시작하기 메인 버튼
            Button(action: finishJoiningProcess) {
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
                    currentStep = 2
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

    private func pasteFromClipboard() {
        if let clip = UIPasteboard.general.string {
            // 초대 링크나 접두사가 붙어있을 경우 순수 코드만 추출
            let cleaned = clip
                .replacingOccurrences(of: "https://kkini.app/invite/", with: "")
                .replacingOccurrences(of: "초대 코드:", with: "")
                .replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            inputFamilyCode = cleaned.uppercased()
        }
    }

    private func validateAndProceed() {
        let code = inputFamilyCode.trimmingCharacters(in: .whitespaces).uppercased()
        guard !code.isEmpty else { return }

        isValidatingCode = true
        codeErrorMessage = nil

        FirebaseManager.shared.validateFamilyCode(familyId: code) { exists in
            isValidatingCode = false
            if exists {
                currentStep = 2
            } else {
                codeErrorMessage = "존재하지 않는 가족 코드입니다. 다시 확인해주세요."
            }
        }
    }

    private func finishJoiningProcess() {
        let finalCode = inputFamilyCode.trimmingCharacters(in: .whitespaces).uppercased()
        let finalNickname = inputNickname.trimmingCharacters(in: .whitespaces)

        // Firebase에 해당 가족의 새 구성원으로 등록
        FirebaseManager.shared.registerUser(familyId: finalCode, userName: finalNickname) { _ in
            onComplete(finalCode, finalNickname)
        }
    }
}
