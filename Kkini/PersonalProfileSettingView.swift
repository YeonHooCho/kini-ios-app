import SwiftUI
import PhotosUI

// MARK: - 개인 설정 화면 (기본 프로필 10종 연동)
struct PersonalProfileSettingView: View {
    @Environment(\.dismiss) private var dismiss
    var onBack: (() -> Void)? = nil
    
    @AppStorage("myFamilyId") private var myFamilyId: String = ""
    @AppStorage("kkini_my_user_name") private var myUserName: String = ""
    @AppStorage("user_profile_avatar_name") private var savedAvatarName: String = "profile_face_1"
    @AppStorage("user_profile_image_base64") private var savedProfileImageBase64: String = ""
    
    @State private var currentImage: UIImage? = nil
    @State private var currentAvatarName: String? = nil
    
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showCameraPicker: Bool = false
    @State private var capturedCameraImage: UIImage? = nil
    @State private var recentGalleryImages: [UIImage] = []
    
    @State private var showMoreFacesSheet: Bool = false
    
    let quickFaceList: [String] = [
        "profile_face_1",
        "profile_face_2",
        "profile_face_3",
        "profile_face_4"
    ]
    
    let userEmail: String = "123@gmail.com"

    var body: some View {
        VStack(spacing: 0) {
            CommonHeaderBar(title: "개인 설정", onBack: {
                if let onBack = onBack {
                    onBack()
                } else {
                    dismiss()
                }
            })
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    
                    // MARK: - 1. 현재 적용된 프로필 사진 영역
                    VStack(alignment: .leading, spacing: 14) {
                        Text("프로필 사진")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.appTextBrown)
                            .padding(.horizontal, 4)
                        
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 130, height: 130)
                                    .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
                                
                                if let img = currentImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 130, height: 130)
                                        .clipShape(Circle())
                                } else if let avatar = currentAvatarName, !avatar.isEmpty {
                                    Image(avatar)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(Color.appTextBrown.opacity(0.3))
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // MARK: - 2. 갤러리 섹션
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("갤러리")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.appTextBrown)
                            
                            Spacer()
                            
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                HStack(spacing: 4) {
                                    Text("More")
                                        .font(.system(size: 13, weight: .medium))
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 15))
                                }
                                .foregroundColor(Color.appActiveTab)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                showCameraPicker = true
                            }) {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(red: 254/255, green: 242/255, blue: 228/255))
                                    .frame(width: 72, height: 72)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 26))
                                            .foregroundColor(Color.appTextBrown.opacity(0.7))
                                    )
                            }
                            
                            ForEach(recentGalleryImages.prefix(3), id: \.self) { img in
                                Button(action: {
                                    applyProfileImage(img)
                                }) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 72, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(currentImage == img ? Color.appActiveTab : Color.clear, lineWidth: 2.5)
                                        )
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                    
                    // MARK: - 3. 기본 이미지 카드 섹션
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("기본 이미지")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.appTextBrown)
                            
                            Spacer()
                            
                            Button(action: {
                                showMoreFacesSheet = true
                            }) {
                                HStack(spacing: 4) {
                                    Text("More")
                                        .font(.system(size: 13, weight: .medium))
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 15))
                                }
                                .foregroundColor(Color.appActiveTab)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            ForEach(quickFaceList, id: \.self) { avatar in
                                Button(action: {
                                    applyDefaultAvatar(avatar)
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(red: 254/255, green: 247/255, blue: 238/255))
                                            .frame(width: 72, height: 72)
                                        
                                        Image(avatar)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 54, height: 54)
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(currentAvatarName == avatar ? Color.appActiveTab : Color.clear, lineWidth: 2.5)
                                    )
                                }
                            }
                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                    
                    // MARK: - 4. 계정 변경 카드
                    VStack(alignment: .leading, spacing: 10) {
                        Text("계정 변경")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.appTextBrown)
                            .padding(.horizontal, 4)
                        
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
                                Text("연동된 계정")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color.appTextBrown)
                                Text(userEmail)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.appTextBrown.opacity(0.65))
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 3) {
                                Text("계정 변경")
                                    .font(.system(size: 13, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(Color.appTextBrown.opacity(0.8))
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
            }
        }
        .background(Color.appBackground)
        .onAppear {
            loadSavedProfile()
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            CameraPickerView(selectedImage: $capturedCameraImage)
                .ignoresSafeArea()
                .onChange(of: capturedCameraImage) { _, newImg in
                    if let newImg = newImg {
                        applyProfileImage(newImg)
                        if !recentGalleryImages.contains(newImg) {
                            recentGalleryImages.insert(newImg, at: 0)
                        }
                    }
                }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem = newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        applyProfileImage(uiImage)
                        if !recentGalleryImages.contains(uiImage) {
                            recentGalleryImages.insert(uiImage, at: 0)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showMoreFacesSheet) {
            AllFacesPickerSheet(
                selectedFaceName: currentAvatarName ?? "profile_face_1",
                onSelect: { selectedFace in
                    applyDefaultAvatar(selectedFace)
                    showMoreFacesSheet = false
                }
            )
            .presentationDetents([.fraction(0.55)])
        }
    }
    
    private func loadSavedProfile() {
        if !savedProfileImageBase64.isEmpty,
           let data = Data(base64Encoded: savedProfileImageBase64),
           let img = UIImage(data: data) {
            self.currentImage = img
            self.currentAvatarName = nil
            self.recentGalleryImages = [img]
        } else if !savedAvatarName.isEmpty {
            self.currentAvatarName = savedAvatarName
            self.currentImage = nil
        } else {
            self.currentAvatarName = "profile_face_1"
            self.currentImage = nil
        }
    }
    
    private func applyProfileImage(_ img: UIImage) {
        self.currentImage = img
        self.currentAvatarName = nil
        
        if let jpeg = img.jpegData(compressionQuality: 0.5) {
            self.savedProfileImageBase64 = jpeg.base64EncodedString()
            self.savedAvatarName = ""
        }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        FirebaseManager.shared.updateUserProfile(
            familyId: myFamilyId,
            userName: myUserName,
            image: img,
            avatarName: nil
        )
    }
    
    private func applyDefaultAvatar(_ avatar: String) {
        self.currentAvatarName = avatar
        self.currentImage = nil
        
        self.savedAvatarName = avatar
        self.savedProfileImageBase64 = ""
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        FirebaseManager.shared.updateUserProfile(
            familyId: myFamilyId,
            userName: myUserName,
            image: nil,
            avatarName: avatar
        )
    }
}

// MARK: - 10종 기본 얼굴 선택 바텀 시트
struct AllFacesPickerSheet: View {
    let selectedFaceName: String
    var onSelect: (String) -> Void
    
    let femaleFaces = ["profile_face_1", "profile_face_2", "profile_face_3", "profile_face_4"]
    let maleFaces   = ["profile_face_5", "profile_face_6", "profile_face_7", "profile_face_8"]
    let seniorFaces = ["profile_face_9", "profile_face_10"]
    
    let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 4)
    
    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
            
            Text("기본 프로필 선택")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color.appTextBrown)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    faceGrid(femaleFaces)
                    Divider().padding(.horizontal, 8)
                    faceGrid(maleFaces)
                    Divider().padding(.horizontal, 8)
                    
                    HStack(spacing: 14) {
                        ForEach(seniorFaces, id: \.self) { face in
                            faceButton(face)
                                .frame(width: (UIScreen.main.bounds.width - 64) / 4)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .background(Color.white)
    }
    
    private func faceGrid(_ faces: [String]) -> some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(faces, id: \.self) { face in
                faceButton(face)
            }
        }
    }
    
    private func faceButton(_ face: String) -> some View {
        Button(action: {
            onSelect(face)
        }) {
            ZStack {
                Circle()
                    .fill(Color(red: 254/255, green: 247/255, blue: 236/255))
                    .frame(height: 64)
                Image(face)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
            }
            .overlay(
                Circle()
                    .stroke(Color.appActiveTab, lineWidth: selectedFaceName == face ? 3 : 0)
            )
        }
    }
}
