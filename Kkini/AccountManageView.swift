import SwiftUI

// MARK: - 계정 관리 상세 화면 (가족 정보 카드 + 그룹 나가기 + 회원 탈퇴)
struct AccountManagementView: View {
    var onBack: () -> Void
    
    // 💡 온보딩에서 저장한 실제 닉네임 키("kkini_my_user_name") 및 가족 코드 연동
    @AppStorage("myFamilyId") private var myFamilyId: String = ""
    @AppStorage("kkini_my_user_name") private var kkiniUserName: String = ""
    @AppStorage("myUserName") private var legacyUserName: String = ""
    
    @State private var showLeaveFamilyAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showCopyToast = false
    
    // 유효한 닉네임 추출 (공백 제거 후 표시)
    private var displayUserName: String {
        let cleanKkini = kkiniUserName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanKkini.isEmpty { return cleanKkini }
        let cleanLegacy = legacyUserName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanLegacy.isEmpty { return cleanLegacy }
        return "이름 없음"
    }
    
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
                    Text("계정 관리")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color.appTextBrown)
                    Spacer()
                    Spacer().frame(width: 30)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.appHeader)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        
                        // MARK: - 1. 현재 가족 정보 카드
                        VStack(alignment: .leading, spacing: 12) {
                            Text("현재 참여 중인 가족")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.appTextBrown.opacity(0.8))
                            
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("가족 초대 코드")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.appTextBrown.opacity(0.6))
                                        Text(myFamilyId.isEmpty ? "미연동" : myFamilyId)
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(Color.appTextBrown)
                                            .tracking(2)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: copyFamilyCode) {
                                        HStack(spacing: 5) {
                                            Image(systemName: "doc.on.doc")
                                                .font(.system(size: 12))
                                            Text("코드 복사")
                                                .font(.system(size: 13, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.appActiveTab)
                                        .clipShape(Capsule())
                                    }
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("내 기기 프로필")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color.appTextBrown.opacity(0.7))
                                    Spacer()
                                    // 온보딩에서 등록한 실제 닉네임 노출
                                    Text(displayUserName)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(Color.appTextBrown)
                                }
                            }
                            .padding(18)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                        }
                        
                        // MARK: - 2. 가족 그룹 나가기
                        VStack(alignment: .leading, spacing: 12) {
                            Text("가족 그룹 관리")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.appTextBrown.opacity(0.8))
                            
                            Button(action: { showLeaveFamilyAlert = true }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("가족 그룹 나가기")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(Color.appTextBrown)
                                        Text("현재 식탁에서 분리되며 다른 가족 코드로 참여할 수 있습니다.")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.appTextBrown.opacity(0.6))
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color.appTextBrown.opacity(0.4))
                                }
                                .padding(18)
                                .background(Color.white)
                                .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // MARK: - 3. 회원 탈퇴 (Color.accountDeleteRed 적용)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("계정 데이터")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.appTextBrown.opacity(0.8))
                            
                            Button(action: { showDeleteAccountAlert = true }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("회원 탈퇴")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(Color.accountDeleteRed)
                                        Text("닉네임, 업로드한 식탁 사진 등 모든 로컬 데이터가 영구 삭제됩니다.")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.accountDeleteRed.opacity(0.85))
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer()
                                    Image(systemName: "trash")
                                        .font(.system(size: 15))
                                        .foregroundColor(Color.accountDeleteRed)
                                }
                                .padding(18)
                                .background(Color.white)
                                .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            
            // 코드 복사 토스트 팝업
            if showCopyToast {
                VStack {
                    Spacer()
                    Text("가족 코드가 클립보드에 복사되었습니다.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.75))
                        .clipShape(Capsule())
                        .padding(.bottom, 30)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(10)
            }
        }
        .alert("가족 그룹 나가기", isPresented: $showLeaveFamilyAlert) {
            Button("취소", role: .cancel) { }
            Button("나가기", role: .destructive) {
                leaveFamilyGroup()
            }
        } message: {
            Text("정말 현재 가족 그룹에서 나가시겠습니까? 식탁에서 본인의 자리가 비워집니다.")
        }
        .alert("회원 탈퇴", isPresented: $showDeleteAccountAlert) {
            Button("취소", role: .cancel) { }
            Button("탈퇴하기", role: .destructive) {
                deleteAccountCompletely()
            }
        } message: {
            Text("탈퇴 시 모든 식탁 데이터와 프로필 정보가 초기화되며 복구할 수 없습니다.")
        }
    }
    
    private func copyFamilyCode() {
        guard !myFamilyId.isEmpty else { return }
        UIPasteboard.general.string = myFamilyId
        withAnimation { showCopyToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { showCopyToast = false }
        }
    }
    
    private func leaveFamilyGroup() {
        let currentFamily = myFamilyId.trimmingCharacters(in: .whitespaces)
        let currentUser = displayUserName
        if !currentFamily.isEmpty && !currentUser.isEmpty && currentUser != "이름 없음" {
            FirebaseManager.shared.deleteMeal(familyId: currentFamily, userName: currentUser)
        }
        myFamilyId = ""
        onBack()
    }
    
    private func deleteAccountCompletely() {
        let currentFamily = myFamilyId.trimmingCharacters(in: .whitespaces)
        let currentUser = displayUserName
        if !currentFamily.isEmpty && !currentUser.isEmpty && currentUser != "이름 없음" {
            FirebaseManager.shared.deleteMeal(familyId: currentFamily, userName: currentUser)
        }
        myFamilyId = ""
        kkiniUserName = ""
        legacyUserName = ""
        onBack()
    }
}
