import SwiftUI
import FirebaseFirestore

// MARK: - Firestore 실시간 채팅 데이터 모델
struct FirebaseChatMessage: Identifiable {
    let id: String
    let senderName: String
    let text: String
    let time: String
    let dateString: String // 예: "2026. 10. 08"
    var imageBase64: String? = nil // 👈 채팅 사진 데이터 (Base64)
}

class FirebaseManager {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    // MARK: - 1. 사용자 등록 (온보딩 이름 입력 시 해당 가족 식탁에 빈 슬롯 생성 + users 컬렉션 FCM 토큰 등록)
    func registerUser(familyId: String, userName: String, completion: ((Bool) -> Void)? = nil) {
        let trimmedFamily = familyId.trimmingCharacters(in: .whitespaces)
        let trimmedUser = userName.trimmingCharacters(in: .whitespaces)
        guard !trimmedFamily.isEmpty, !trimmedUser.isEmpty, trimmedUser != "나" else { return }
        
        // 앱 실행 및 유저 등록 시 users 컬렉션에 FCM 토큰 즉시 동기화
        if let savedToken = UserDefaults.standard.string(forKey: "kkini_fcm_token"), !savedToken.isEmpty {
            updateFCMToken(familyId: trimmedFamily, userName: trimmedUser, token: savedToken)
        } else {
            db.collection("families").document(trimmedFamily)
                .collection("users").document(trimmedUser)
                .setData([
                    "userName": trimmedUser,
                    "updatedAt": FieldValue.serverTimestamp()
                ], merge: true)
        }
        
        let docRef = db.collection("families").document(trimmedFamily)
            .collection("todayMeals").document(trimmedUser)
        
        docRef.getDocument { doc, _ in
            if let doc = doc, doc.exists {
                completion?(true)
            } else {
                let data: [String: Any] = [
                    "userName": trimmedUser,
                    "text": "",
                    "imageBase64": "",
                    "emojiName": "",
                    "timestamp": FieldValue.serverTimestamp()
                ]
                docRef.setData(data) { err in
                    completion?(err == nil)
                }
            }
        }
    }
    
    // MARK: - 2. 식사 게시글 업로드 (당일 식탁 + 날짜별 아카이브에 동시 저장)
    func uploadMeal(familyId: String, userName: String, text: String, image: UIImage?, emoji: String?, completion: @escaping (Bool) -> Void) {
        let trimmedFamily = familyId.trimmingCharacters(in: .whitespaces)
        guard !trimmedFamily.isEmpty else { completion(false); return }
        
        var base64String = ""
        
        // 사진 600px 리사이즈 및 JPEG 압축 (1MB 한도 보호)
        if let img = image {
            let resized = resizeImage(image: img, targetSize: CGSize(width: 600, height: 600))
            if let jpegData = resized.jpegData(compressionQuality: 0.5) {
                base64String = jpegData.base64EncodedString()
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        let todayKey = formatter.string(from: Date())
        
        let data: [String: Any] = [
            "userName": userName,
            "text": text,
            "imageBase64": base64String,
            "emojiName": emoji ?? "",
            "dateString": todayKey,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        let batch = db.batch()
        
        // 1) 당일 활성 식탁 저장
        let todayRef = db.collection("families").document(trimmedFamily)
            .collection("todayMeals").document(userName)
        batch.setData(data, forDocument: todayRef)
        
        // 2) 날짜별 영구 보관소(아카이브) 저장 -> 리포트 탭 영구 보존용
        let archiveRef = db.collection("families").document(trimmedFamily)
            .collection("dailyArchives").document(todayKey)
            .collection("meals").document(userName)
        batch.setData(data, forDocument: archiveRef)
        
        batch.commit { error in
            completion(error == nil)
        }
    }
    
    // MARK: - 3. 구성원 제외 (해당 가족 DB에서 삭제 -> 같은 가족 기기에서 실시간 제거)
    func deleteMeal(familyId: String, userName: String, completion: ((Bool) -> Void)? = nil) {
        let trimmedFamily = familyId.trimmingCharacters(in: .whitespaces)
        guard !trimmedFamily.isEmpty else { return }
        
        db.collection("families").document(trimmedFamily)
            .collection("todayMeals").document(userName).delete { error in
                completion?(error == nil)
            }
    }
    
    // MARK: - 4. 이전 테스트 "나" 데이터 영구 청소
    func cleanLegacyDummyData(familyId: String) {
        let trimmedFamily = familyId.trimmingCharacters(in: .whitespaces)
        guard !trimmedFamily.isEmpty else { return }
        
        db.collection("families").document(trimmedFamily)
            .collection("todayMeals").document("나").delete()
    }
    
    // MARK: - 5. 실시간 당일 식탁 동기화 리스너 (당일 업로드 데이터만 노출)
    func listenTodayMeals(familyId: String, completion: @escaping ([String: (text: String, image: UIImage?, emoji: String?)]) -> Void) {
        let trimmedFamily = familyId.trimmingCharacters(in: .whitespaces)
        guard !trimmedFamily.isEmpty else { return }
        
        db.collection("families").document(trimmedFamily)
            .collection("todayMeals").addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                var result: [String: (text: String, image: UIImage?, emoji: String?)] = [:]
                let calendar = Calendar.current
                
                for doc in documents {
                    let name = doc.documentID
                    if name == "나" {
                        self?.cleanLegacyDummyData(familyId: trimmedFamily)
                        continue
                    }
                    
                    let data = doc.data()
                    
                    // 자정 기준 오늘 업로드된 사진인지 확인
                    var isUploadedToday = false
                    if let timestamp = data["timestamp"] as? Timestamp {
                        let uploadDate = timestamp.dateValue()
                        isUploadedToday = calendar.isDateInToday(uploadDate)
                    }
                    
                    // 오늘 업로드된 식사가 아니면 당일 식탁 화면에서는 빈 슬롯 처리
                    if !isUploadedToday {
                        result[name] = (text: "", image: nil, emoji: nil)
                        continue
                    }
                    
                    let text = data["text"] as? String ?? ""
                    let emoji = data["emojiName"] as? String
                    let base64 = data["imageBase64"] as? String ?? ""
                    
                    var image: UIImage? = nil
                    if !base64.isEmpty, let imgData = Data(base64Encoded: base64) {
                        image = UIImage(data: imgData)
                    }
                    
                    result[name] = (text: text, image: image, emoji: emoji)
                }
                completion(result)
            }
    }
    
    // MARK: - 6. 리포트용 특정 날짜 식탁 불러오기 (과거 사진 복구 Fallback 포함)
    func fetchArchivedMeals(familyId: String, dateString: String, completion: @escaping ([String: (text: String, image: UIImage?, emoji: String?)]) -> Void) {
        let trimmedFamily = familyId.trimmingCharacters(in: .whitespaces)
        guard !trimmedFamily.isEmpty else { completion([:]); return }
        
        let cleanDate = dateString.replacingOccurrences(of: " ", with: "").trimmingCharacters(in: .whitespaces)
        
        let archiveRef = db.collection("families").document(trimmedFamily)
            .collection("dailyArchives").document(cleanDate)
            .collection("meals")
            
        archiveRef.getDocuments { [weak self] snapshot, error in
            if let documents = snapshot?.documents, !documents.isEmpty {
                var result: [String: (text: String, image: UIImage?, emoji: String?)] = [:]
                for doc in documents {
                    let name = doc.documentID
                    let data = doc.data()
                    let text = data["text"] as? String ?? ""
                    let emoji = data["emojiName"] as? String
                    let base64 = data["imageBase64"] as? String ?? ""
                    
                    var image: UIImage? = nil
                    if !base64.isEmpty, let imgData = Data(base64Encoded: base64) {
                        image = UIImage(data: imgData)
                    }
                    result[name] = (text: text, image: image, emoji: emoji)
                }
                completion(result)
            } else {
                // 아카이브에 아직 보관되지 않은 이전 식탁 사진은 todayMeals의 타임스탬프로 복구
                self?.recoverFromTodayMeals(familyId: trimmedFamily, targetDate: cleanDate, completion: completion)
            }
        }
    }
    
    private func recoverFromTodayMeals(familyId: String, targetDate: String, completion: @escaping ([String: (text: String, image: UIImage?, emoji: String?)]) -> Void) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        
        db.collection("families").document(familyId)
            .collection("todayMeals").getDocuments { snapshot, _ in
                guard let docs = snapshot?.documents else { completion([:]); return }
                var result: [String: (text: String, image: UIImage?, emoji: String?)] = [:]
                
                for doc in docs {
                    let name = doc.documentID
                    let data = doc.data()
                    if let ts = data["timestamp"] as? Timestamp {
                        let docDate = formatter.string(from: ts.dateValue())
                        if docDate == targetDate {
                            let text = data["text"] as? String ?? ""
                            let emoji = data["emojiName"] as? String
                            let base64 = data["imageBase64"] as? String ?? ""
                            var image: UIImage? = nil
                            if !base64.isEmpty, let imgData = Data(base64Encoded: base64) {
                                image = UIImage(data: imgData)
                            }
                            result[name] = (text: text, image: image, emoji: emoji)
                        }
                    }
                }
                completion(result)
            }
    }
    
    // MARK: - 7. 실시간 가족 채팅 전송 (날짜 dateString 및 사진 Base64 지원)
    func sendChatMessage(
        familyId: String,
        senderName: String,
        text: String,
        image: UIImage? = nil,
        imageBase64: String? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {
        let trimmedFamily = familyId.trimmingCharacters(in: .whitespaces)
        guard !trimmedFamily.isEmpty else { return }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "a h:mm"
        timeFormatter.locale = Locale(identifier: "ko_KR")
        let timeStr = timeFormatter.string(from: Date())
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy. MM. dd"
        let dateStr = dateFormatter.string(from: Date())
        
        var data: [String: Any] = [
            "senderName": senderName,
            "text": text,
            "time": timeStr,
            "dateString": dateStr, // 전송 시점의 날짜 저장
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // 사진이 전달된 경우 600px 리사이즈 후 압축하여 Base64로 저장
        if let img = image {
            let resized = resizeImage(image: img, targetSize: CGSize(width: 600, height: 600))
            if let jpegData = resized.jpegData(compressionQuality: 0.5) {
                data["imageBase64"] = jpegData.base64EncodedString()
            }
        } else if let b64 = imageBase64, !b64.isEmpty {
            data["imageBase64"] = b64
        }
        
        db.collection("families").document(trimmedFamily)
            .collection("chatMessages").addDocument(data: data) { error in
                completion?(error == nil)
            }
    }
    
    // MARK: - 8. 실시간 가족 채팅 수신 리스너 (날짜 dateString 및 사진 Base64 파싱)
    func listenChatMessages(familyId: String, completion: @escaping ([FirebaseChatMessage]) -> Void) {
        let trimmedFamily = familyId.trimmingCharacters(in: .whitespaces)
        guard !trimmedFamily.isEmpty else { return }
        
        db.collection("families").document(trimmedFamily)
            .collection("chatMessages")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                var result: [FirebaseChatMessage] = []
                for doc in documents {
                    let data = doc.data()
                    let id = doc.documentID
                    let sender = data["senderName"] as? String ?? "가족"
                    let text = data["text"] as? String ?? ""
                    let time = data["time"] as? String ?? ""
                    let imageBase64 = data["imageBase64"] as? String
                    
                    // dateString이 없는 과거 메시지는 createdAt 타임스탬프로 보정
                    var dateStr = data["dateString"] as? String ?? ""
                    if dateStr.isEmpty, let ts = data["createdAt"] as? Timestamp {
                        let df = DateFormatter()
                        df.dateFormat = "yyyy. MM. dd"
                        dateStr = df.string(from: ts.dateValue())
                    }
                    if dateStr.isEmpty {
                        let df = DateFormatter()
                        df.dateFormat = "yyyy. MM. dd"
                        dateStr = df.string(from: Date())
                    }
                    
                    result.append(FirebaseChatMessage(
                        id: id,
                        senderName: sender,
                        text: text,
                        time: time,
                        dateString: dateStr,
                        imageBase64: imageBase64
                    ))
                }
                completion(result)
            }
    }
    
    // MARK: - 9. 이미지 리사이즈 유틸리티 (Firestore 1MB 한도 보호)
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        if ratio >= 1.0 { return image }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? image
    }
    
    // MARK: - 10. 6자리 고유 가족 코드 생성 및 방 개설
    func generateRandomFamilyCode() -> String {
        let allowedChars = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
        return String((0..<6).map { _ in allowedChars.randomElement()! })
    }
    
    func createNewFamily(creatorName: String, purposes: [String] = [], completion: @escaping (String?) -> Void) {
        let trimmedUser = creatorName.trimmingCharacters(in: .whitespaces)
        guard !trimmedUser.isEmpty else { completion(nil); return }
        
        let candidateCode = generateRandomFamilyCode()
        let familyRef = db.collection("families").document(candidateCode)
        
        familyRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { completion(nil); return }
            
            if let snapshot = snapshot, snapshot.exists {
                self.createNewFamily(creatorName: trimmedUser, purposes: purposes, completion: completion)
            } else {
                let initialData: [String: Any] = [
                    "createdAt": FieldValue.serverTimestamp(),
                    "createdBy": trimmedUser,
                    "purposes": purposes
                ]
                
                familyRef.setData(initialData) { err in
                    if err == nil {
                        self.registerUser(familyId: candidateCode, userName: trimmedUser) { _ in
                            completion(candidateCode)
                        }
                    } else {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    // MARK: - 11. 초대 코드로 참여 시 방 존재 여부 검증
    func validateFamilyCode(familyId: String, completion: @escaping (Bool) -> Void) {
        let trimmedCode = familyId.trimmingCharacters(in: .whitespaces).uppercased()
        guard !trimmedCode.isEmpty else { completion(false); return }
        
        db.collection("families").document(trimmedCode).getDocument { snapshot, error in
            if let snapshot = snapshot, snapshot.exists {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    // MARK: - 12. 푸시 알림용 기기 FCM 토큰 등록/갱신
    func updateFCMToken(familyId: String? = nil, userName: String? = nil, token: String) {
        let rawFamily = familyId
            ?? UserDefaults.standard.string(forKey: "kkini_family_id")
            ?? UserDefaults.standard.string(forKey: "myFamilyId")
            ?? ""
        let rawUser = userName
            ?? UserDefaults.standard.string(forKey: "kkini_my_user_name")
            ?? UserDefaults.standard.string(forKey: "myUserName")
            ?? ""
        
        let trimmedFamily = rawFamily.trimmingCharacters(in: .whitespaces)
        let trimmedUser = rawUser.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedFamily.isEmpty, !trimmedUser.isEmpty, trimmedUser != "나" else {
            print("⚠️ 아직 가족코드나 이름이 설정되지 않아 FCM 토큰 DB 저장을 보류합니다.")
            return
        }
        
        db.collection("families").document(trimmedFamily)
            .collection("users").document(trimmedUser)
            .setData([
                "userName": trimmedUser,
                "fcmToken": token,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true) { error in
                if let error = error {
                    print("❌ FCM 토큰 저장 실패: \(error.localizedDescription)")
                } else {
                    print("✅ Firestore [families/\(trimmedFamily)/users/\(trimmedUser)]에 FCM 토큰 저장 완료!")
                }
            }
    }
    
    // MARK: - 13. 사용자 프로필(사진 / 기본 아바타) Firestore 저장 & 갱신
    func updateUserProfile(familyId: String, userName: String, image: UIImage?, avatarName: String?, completion: ((Bool) -> Void)? = nil) {
        let trimmedFamily = familyId.trimmingCharacters(in: .whitespaces)
        let trimmedUser = userName.trimmingCharacters(in: .whitespaces)
        guard !trimmedFamily.isEmpty, !trimmedUser.isEmpty else { completion?(false); return }
        
        var base64String = ""
        if let img = image {
            let resized = resizeImage(image: img, targetSize: CGSize(width: 400, height: 400))
            if let jpegData = resized.jpegData(compressionQuality: 0.6) {
                base64String = jpegData.base64EncodedString()
            }
        }
        
        var data: [String: Any] = [
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if !base64String.isEmpty {
            data["profileImageBase64"] = base64String
            data["avatarName"] = ""
        } else if let avatar = avatarName, !avatar.isEmpty {
            data["avatarName"] = avatar
            data["profileImageBase64"] = ""
        }
        
        db.collection("families").document(trimmedFamily)
            .collection("users").document(trimmedUser)
            .setData(data, merge: true) { error in
                if let error = error {
                    print("❌ 프로필 Firestore 업데이트 실패: \(error.localizedDescription)")
                } else {
                    print("✅ 프로필 Firestore 업데이트 성공: \(trimmedUser)")
                }
                completion?(error == nil)
            }
    }
    
    // MARK: - 14. 가족 구성원 프로필(사진 / 아바타) 실시간 구독
    func listenFamilyProfiles(familyId: String, completion: @escaping ([String: (image: UIImage?, avatarName: String)]) -> Void) {
        let trimmedFamily = familyId.trimmingCharacters(in: .whitespaces)
        guard !trimmedFamily.isEmpty else { return }
        
        db.collection("families").document(trimmedFamily)
            .collection("users")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                var profileDict: [String: (image: UIImage?, avatarName: String)] = [:]
                for doc in documents {
                    let userName = doc.documentID
                    let data = doc.data()
                    
                    let avatar = data["avatarName"] as? String ?? ""
                    let base64 = data["profileImageBase64"] as? String ?? ""
                    
                    var userImage: UIImage? = nil
                    if !base64.isEmpty, let imgData = Data(base64Encoded: base64) {
                        userImage = UIImage(data: imgData)
                    }
                    
                    profileDict[userName] = (image: userImage, avatarName: avatar)
                }
                completion(profileDict)
            }
    }
    
    // MARK: - 15. 끼니 신문 Firestore 저장 및 로드
    func saveNewspaper(familyId: String, dateString: String, data: [String: Any], completion: ((Bool) -> Void)? = nil) {
        let trimmedFamily = familyId.trimmingCharacters(in: .whitespaces)
        guard !trimmedFamily.isEmpty else { completion?(false); return }
        
        let cleanDate = dateString.replacingOccurrences(of: " ", with: "").trimmingCharacters(in: .whitespaces)
        
        db.collection("families").document(trimmedFamily)
            .collection("newspapers").document(cleanDate)
            .setData(data, merge: true) { err in
                if let err = err {
                    print("❌ 끼니 신문 저장 실패: \(err.localizedDescription)")
                } else {
                    print("✅ 끼니 신문 저장 성공 [\(cleanDate)]")
                }
                completion?(err == nil)
            }
    }
    
    func fetchNewspaper(familyId: String, dateString: String, completion: @escaping ([String: Any]?) -> Void) {
        let trimmedFamily = familyId.trimmingCharacters(in: .whitespaces)
        guard !trimmedFamily.isEmpty else { completion(nil); return }
        
        let cleanDate = dateString.replacingOccurrences(of: " ", with: "").trimmingCharacters(in: .whitespaces)
        
        db.collection("families").document(trimmedFamily)
            .collection("newspapers").document(cleanDate)
            .getDocument { snapshot, _ in
                if let snapshot = snapshot, snapshot.exists {
                    completion(snapshot.data())
                } else {
                    completion(nil)
                }
            }
    }
    
    func fetchAllNewspapers(familyId: String, completion: @escaping ([[String: Any]]) -> Void) {
        let trimmedFamily = familyId.trimmingCharacters(in: .whitespaces)
        guard !trimmedFamily.isEmpty else { completion([]); return }
        
        db.collection("families").document(trimmedFamily)
            .collection("newspapers")
            .order(by: "dateString", descending: true)
            .getDocuments { snapshot, _ in
                let list = snapshot?.documents.compactMap { $0.data() } ?? []
                completion(list)
            }
    }
}
