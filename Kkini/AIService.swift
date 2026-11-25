import UIKit

class AIService {
    static let shared = AIService()
    private init() {}
    
    // 발급받은 Google AI Studio 무료 등급 API 키
    private let apiKey = "YOUR_GEMINI_API_KEY"
    
    // ✅ 콘솔의 ListModels에서 실제 존재함이 확인된 모델 리스트 (과부하 시 즉시 순차 우회)
    private let availableModels = [
        "gemini-3.5-flash-lite",
        "gemini-3.1-flash-lite",
        "gemini-3.7-flash",
        "gemini-3.6-flash",
        "gemini-3.5-flash",
        "gemini-3.8-flash"
    ]
    
    // MARK: - 0. 사용자 설정 말투(Tone) 지침 추출 헬퍼
    private func getToneInstruction() -> String {
        let tone = UserDefaults.standard.string(forKey: "aiQuestionTone") ?? "friendly"
        switch tone {
        case "playful":
            return "말투 스타일: 유쾌하고 장난기 넘치는 가족 티키타카 반말 구어체. (예: '나 한입만 남겨줘!', '벌써 다 먹은 거야?')"
        case "polite":
            return "말투 스타일: 차분하고 예의 바른 다정한 존댓말 구어체. (예: '맛있게 드셨나요?', '바쁘셔도 꼭 챙겨 드세요')"
        default:
            return "말투 스타일: 다정하고 따뜻한 가족 반말 구어체. (예: '직접 만든 거야? 맛나겠다', '밥 꼭꼭 씹어 먹어')"
        }
    }
    
    // MARK: - 1. 하루의 첫 대화용: 식탁 사진 및 메모 기반 멀티모달 추천 질문 생성 (Chat.png 스타일 3문장)
    func generateQuestions(for image: UIImage?, memo: String, completion: @escaping ([String]) -> Void) {
        executeGenerateQuestions(for: image, memo: memo, modelIndex: 0, completion: completion)
    }
    
    private func executeGenerateQuestions(for image: UIImage?, memo: String, modelIndex: Int, completion: @escaping ([String]) -> Void) {
        let currentModel = availableModels[min(modelIndex, availableModels.count - 1)]
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(currentModel):generateContent") else {
            completion(fallbackQuestions(memo: memo))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        
        let prompt = """
        너는 가족 간의 따뜻한 식사 소통을 돕는 앱 '끼니'의 센스 넘치는 AI야.
        가족 구성원이 올린 식사 사진과 메모: "\(!memo.isEmpty ? memo : "식사 사진만 올림")"

        [판별 및 분석 지침]
        1. [시각 요소 분석]: 사진 속 음식의 종류(국/찌개, 볶음밥, 면, 고기, 디저트 등), 식기 형태(뚝배기, 집 그릇, 배달 용기, 텀블러 등), 색감과 분위기를 콕 집어서 언급할 것.
        2. [상황 감지]: 사용자가 '굶음, 커피만 마심, 늦잠, 다이어트, 야근, 공부' 등의 메모를 적었거나 음료 사진만 있다면 절대 "맛있겠다/든든하네"라고 하지 말고, 다정한 걱정과 진심 어린 응원을 건넬 것.
        3. [상투적 표현 금지]: "우와 맛있겠다!", "든든하게 먹었네!" 같은 뻔하고 판에 박힌 문장을 지양하고, 실제 가족이 사진을 보고 건넬 법한 생생한 말투를 쓸 것.
        4. [3문장 구성 원칙]: 사용자가 답장으로 선택할 수 있도록 서로 다른 3가지 관점의 질문이나 반응 문장을 작성할 것. (예: 식당 위치 묻기, 식사 메뉴 칭찬/걱정, 내 저녁 메뉴 다짐 등)
        5. [선택된 말투 지침 반영]:
        \(getToneInstruction())

        [출력 규칙]
        - 번호(1., 2., 3.), 특수문자(-, •), 따옴표(" ")를 절대 붙이지 말 것.
        - 정확히 3줄(줄바꿈 구분)만 출력할 것.
        """
        
        var parts: [[String: Any]] = [["text": prompt]]
        
        if let image = image,
           let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 800, height: 800)),
           let imageData = resizedImage.jpegData(compressionQuality: 0.6) {
            let base64String = imageData.base64EncodedString()
            parts.append([
                "inlineData": [
                    "mimeType": "image/jpeg",
                    "data": base64String
                ]
            ])
        }
        
        let requestBody: [String: Any] = [
            "contents": [
                ["parts": parts]
            ],
            "generationConfig": [
                "temperature": 0.85,
                "maxOutputTokens": 300
            ]
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(fallbackQuestions(memo: memo))
            return
        }
        
        request.httpBody = httpBody
        
        print("🚀 Gemini 식탁 첫 질문 API 호출 시작 (시도 \(modelIndex + 1), 모델: \(currentModel)): \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Gemini API 통신 에러: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(self.fallbackQuestions(memo: memo)) }
                return
            }
            
            guard let data = data else {
                print("❌ Gemini API 응답 데이터 없음")
                DispatchQueue.main.async { completion(self.fallbackQuestions(memo: memo)) }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               (httpResponse.statusCode == 503 || httpResponse.statusCode == 429 || httpResponse.statusCode == 404),
               modelIndex + 1 < self.availableModels.count {
                let nextModel = self.availableModels[modelIndex + 1]
                print("⏳ \(currentModel) 상태(\(httpResponse.statusCode)) -> '\(nextModel)' 모델로 즉시 전환하여 재요청합니다!")
                self.executeGenerateQuestions(for: image, memo: memo, modelIndex: modelIndex + 1, completion: completion)
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let resParts = content["parts"] as? [[String: Any]],
               let text = resParts.first?["text"] as? String {
                
                let lines = text.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .map { $0.replacingOccurrences(of: "^[0-9]+[.\\)]\\s*", with: "", options: .regularExpression) }
                    .map { $0.replacingOccurrences(of: "^[-*•]\\s*", with: "", options: .regularExpression) }
                    .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"\'")) }
                    .filter { !$0.isEmpty }
                
                let finalQuestions: [String]
                if lines.count >= 3 {
                    finalQuestions = Array(lines.prefix(3))
                } else if !lines.isEmpty {
                    var combined = lines
                    for fallback in self.fallbackQuestions(memo: memo) {
                        if combined.count >= 3 { break }
                        if !combined.contains(fallback) { combined.append(fallback) }
                    }
                    finalQuestions = combined
                } else {
                    finalQuestions = self.fallbackQuestions(memo: memo)
                }
                
                DispatchQueue.main.async {
                    completion(finalQuestions)
                }
            } else {
                DispatchQueue.main.async {
                    completion(self.fallbackQuestions(memo: memo))
                }
            }
        }.resume()
    }
    
    // MARK: - 2. 대화 도중(첫 대화 이후): 맥락 기반 키보드 위 자동 추천 (17자 이내 2문장)
    func generateQuestionsFromChat(recentMessages: [ChatMessage], completion: @escaping ([String]) -> Void) {
        executeGenerateQuestionsFromChat(recentMessages: recentMessages, modelIndex: 0, completion: completion)
    }
    
    private func executeGenerateQuestionsFromChat(recentMessages: [ChatMessage], modelIndex: Int, completion: @escaping ([String]) -> Void) {
        let currentModel = availableModels[min(modelIndex, availableModels.count - 1)]
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(currentModel):generateContent") else {
            completion(self.fallbackChatQuestions())
            return
        }
        
        let chatContext = recentMessages.suffix(5).map { "\($0.senderName): \($0.text)" }.joined(separator: "\n")
        
        let prompt = """
        너는 가족 간의 대화를 이어주는 앱 '끼니'의 AI야.
        아래는 가족 채팅방의 최근 대화 내용이야:
        ---
        \(chatContext)
        ---
        가족들이 이 대화를 끊기지 않고 자연스럽게 이어갈 수 있도록, 다음에 보낼만한 센스 있는 추천 질문이나 리액션 2가지를 만들어줘.
        
        [조건]
        1. 공백(띄어쓰기) 포함 반드시 17자 이내로 작성할 것. (말풍선 크기 제한)
        2. 번호, 특수문자, 따옴표 없이 오직 2개의 문장만 줄바꿈(\\n)으로 구분할 것.
        3. 아래 지정된 말투 스타일을 엄격히 적용할 것:
        \(getToneInstruction())
        """
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        
        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "temperature": 0.8,
                "maxOutputTokens": 200
            ]
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(self.fallbackChatQuestions())
            return
        }
        request.httpBody = httpBody
        
        print("🚀 Gemini 대화 도중 키보드 추천 API 호출 시작 (시도 \(modelIndex + 1), 모델: \(currentModel)): \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion(self.fallbackChatQuestions()) }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               (httpResponse.statusCode == 503 || httpResponse.statusCode == 429 || httpResponse.statusCode == 404),
               modelIndex + 1 < self.availableModels.count {
                let nextModel = self.availableModels[modelIndex + 1]
                print("⏳ 채팅 AI \(currentModel) 상태(\(httpResponse.statusCode)) -> '\(nextModel)' 모델로 즉시 전환하여 재요청합니다!")
                self.executeGenerateQuestionsFromChat(recentMessages: recentMessages, modelIndex: modelIndex + 1, completion: completion)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let content = firstCandidate["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let text = parts.first?["text"] as? String {
                    
                    let lines = text.components(separatedBy: .newlines)
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .map { $0.replacingOccurrences(of: "^[0-9]+[.\\)]\\s*", with: "", options: .regularExpression) }
                        .map { $0.replacingOccurrences(of: "^[-*•]\\s*", with: "", options: .regularExpression) }
                        .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"\'")) }
                        .filter { !$0.isEmpty }
                    
                    let questions = lines.count >= 2 ? Array(lines.prefix(2)) : self.fallbackChatQuestions()
                    DispatchQueue.main.async { completion(questions) }
                } else {
                    DispatchQueue.main.async { completion(self.fallbackChatQuestions()) }
                }
            } catch {
                DispatchQueue.main.async { completion(self.fallbackChatQuestions()) }
            }
        }.resume()
    }
    
    // MARK: - 3. 전날 식탁 사진 및 메모 기반 '끼니 신문' JSON 자동 생성
    func generateNewspaperArticle(
        yesterdayDateString: String,
        issueNumber: Int,
        familyMeals: [(userName: String, text: String, image: UIImage?)],
        completion: @escaping ([String: Any]) -> Void
    ) {
        executeGenerateNewspaperArticle(
            yesterdayDateString: yesterdayDateString,
            issueNumber: issueNumber,
            familyMeals: familyMeals,
            modelIndex: 0,
            completion: completion
        )
    }
    
    private func executeGenerateNewspaperArticle(
        yesterdayDateString: String,
        issueNumber: Int,
        familyMeals: [(userName: String, text: String, image: UIImage?)],
        modelIndex: Int,
        completion: @escaping ([String: Any]) -> Void
    ) {
        guard !familyMeals.isEmpty else {
            completion(fallbackNewspaper(dateString: yesterdayDateString, issueNumber: issueNumber))
            return
        }
        
        let currentModel = availableModels[min(modelIndex, availableModels.count - 1)]
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(currentModel):generateContent") else {
            completion(fallbackNewspaper(dateString: yesterdayDateString, issueNumber: issueNumber))
            return
        }
        
        var mealsContext = ""
        for m in familyMeals {
            mealsContext += "- \(m.userName): \(m.text.isEmpty ? "사진 업로드함" : m.text)\n"
        }
        
        let prompt = """
        당신은 따뜻하고 유쾌한 가족 신문 '끼니 신문'을 발행하는 전문 AI 기자입니다.
        어제 가족들이 함께 나눈 식사 기록을 바탕으로 신문 기사를 작성해주세요.
        
        [가족 식사 기록]
        \(mealsContext)
        
        [작성 규칙]
        1. 메인 기사(main): 가장 인상 깊은 구성원의 식사를 헤드라인으로 다룰 것.
        2. 서브 기사(sub): 다른 구성원의 식사나 디저트, 상황을 다룰 것.
        3. 캐릭터 메시지(characterMessage): 가족들의 식사 습관을 칭찬하고 응원하는 원숭이 캐릭터 '끼니'의 다정한 한마디.
        4. 반드시 마크다운(```json) 없이 순수 JSON 객체 형태로만 응답할 것:
        {
          "mainTag": "[특종] 구성원이름",
          "mainTitle": "헤드라인 제목 (예: 여행 첫 끼니로 고기국수 선택!)",
          "mainSubtitle": "부제목 (예: 도착 30분만에 고기국수집으로 향한 사연은?)",
          "mainBoxTitle": "메인 기사 소제목 (예: 제주 레전드 맛집 발견!)",
          "mainBoxContent": "기사 요약 3문장 이내",
          "mainComment": "가족의 재치있는 한마디 (예: 우리 가족 다같이 또 가자!)",
          "subTitle": "우리 가족의 식탁 이모저모",
          "subKeyword": "음식이나 상황 키워드",
          "subBoxTitle": "서브 기사 소제목",
          "subBoxContent": "서브 기사 본문 2문장 이내",
          "subComment": "서브 구성원의 한마디",
          "characterMessage": "3일 연속 배부르게 끼니를 잘 챙겨주고 있어요!"
        }
        """
        
        var parts: [[String: Any]] = [["text": prompt]]
        
        if let firstImage = familyMeals.compactMap({ $0.image }).first,
           let resized = resizeImage(image: firstImage, targetSize: CGSize(width: 800, height: 800)),
           let imgData = resized.jpegData(compressionQuality: 0.6) {
            parts.append([
                "inlineData": [
                    "mimeType": "image/jpeg",
                    "data": imgData.base64EncodedString()
                ]
            ])
        }
        
        let requestBody: [String: Any] = [
            "contents": [["parts": parts]],
            "generationConfig": [
                "temperature": 0.8,
                "maxOutputTokens": 600
            ]
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(fallbackNewspaper(dateString: yesterdayDateString, issueNumber: issueNumber))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = httpBody
        
        print("📰 Gemini 신문 자동 생성 API 호출 (시도 \(modelIndex + 1), 모델: \(currentModel))")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion(self.fallbackNewspaper(dateString: yesterdayDateString, issueNumber: issueNumber)) }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               (httpResponse.statusCode == 503 || httpResponse.statusCode == 429 || httpResponse.statusCode == 404),
               modelIndex + 1 < self.availableModels.count {
                self.executeGenerateNewspaperArticle(
                    yesterdayDateString: yesterdayDateString,
                    issueNumber: issueNumber,
                    familyMeals: familyMeals,
                    modelIndex: modelIndex + 1,
                    completion: completion
                )
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let resParts = content["parts"] as? [[String: Any]],
               let text = resParts.first?["text"] as? String {
                
                let cleanJSON = text
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let jsonData = cleanJSON.data(using: .utf8),
                   var parsedDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    parsedDict["issueNumber"] = issueNumber
                    parsedDict["dateString"] = yesterdayDateString
                    DispatchQueue.main.async { completion(parsedDict) }
                    return
                }
            }
            
            DispatchQueue.main.async {
                completion(self.fallbackNewspaper(dateString: yesterdayDateString, issueNumber: issueNumber))
            }
        }.resume()
    }
    
    // MARK: - 네트워크 에러 시 기본 예시 신문 데이터 Fallback
    private func fallbackNewspaper(dateString: String, issueNumber: Int) -> [String: Any] {
        return [
            "issueNumber": issueNumber,
            "dateString": dateString,
            "mainTag": "[특종] 우리 가족",
            "mainTitle": "정성 가득한 집밥으로 완성한 오늘의 따뜻한 식탁!",
            "mainSubtitle": "가족들이 함께 모여 든든하게 비워낸 맛있는 한 끼",
            "mainBoxTitle": "소박하지만 든든한 가족 밥상",
            "mainBoxContent": "어제 우리 가족은 서로를 응원하며 따뜻한 밥상을 함께 채웠습니다. 바쁜 하루 속에서도 끼니를 잊지 않고 챙긴 훈훈한 하루였습니다.",
            "mainComment": "다 같이 챙겨 먹으니 밥맛이 두 배로 좋네!",
            "subTitle": "우리 가족의 식탁 이모저모",
            "subKeyword": "달콤한 디저트 타임",
            "subBoxTitle": "식사 후 달콤한 휴식",
            "subBoxContent": "식사 후 커피와 달콤한 간식을 즐기며 일상의 피로를 날려버렸습니다.",
            "subComment": "달달한 게 들어가니 기분이 최고야~",
            "characterDays": 3,
            "characterMessage": "가족들과 함께 건강하게 끼니를 잘 챙겨주고 있어요!"
        ]
    }
    
    // MARK: - 하루 첫 대화용 기본 질문 (Chat.png 문구 3개 완벽 일치)
    private func fallbackQuestions(memo: String) -> [String] {
        let tone = UserDefaults.standard.string(forKey: "aiQuestionTone") ?? "friendly"
        if tone == "polite" {
            return [
                "식사 맛있게 드셨나요?",
                "정말 든든하게 잘 챙겨 드셨네요!",
                "오늘 하루도 건강하고 따뜻하게 보내세요."
            ]
        } else if tone == "playful" {
            return [
                "헐 여기 어디야? 나도 가고싶어!",
                "내 몫은 안 남겨둔 거야?",
                "나도 저녁에는 맛있는 거 먹을래!"
            ]
        }
        
        if memo.contains("못") || memo.contains("안") || memo.contains("굶") || memo.contains("공부") || memo.contains("커피") {
            return [
                "바빠도 끼니 꼭 챙겨 먹어야 해!",
                "속 쓰릴 텐데 간단히 뭐라도 챙겨 먹어",
                "오늘 많이 바쁘구나 힘내!"
            ]
        }
        return [
            "헐 여기 어디야? 나도 가고싶어!",
            "푸짐하게 잘 챙겨먹었는데?",
            "나도 저녁에는 푸짐하게 먹을거야."
        ]
    }
    
    // MARK: - 대화 진행 중 키보드 위 17자 이내 기본 질문 (스크린샷 일치)
    private func fallbackChatQuestions() -> [String] {
        let tone = UserDefaults.standard.string(forKey: "aiQuestionTone") ?? "friendly"
        if tone == "polite" {
            return [
                "식사는 잘 챙겨 드셨나요?",
                "따뜻한 하루 보내세요"
            ]
        } else if tone == "playful" {
            return [
                "다들 점심 챙겨 먹었어?",
                "오늘 식탁 사진 기대돼!"
            ]
        }
        return [
            "다들 점심 챙겨 먹었어?",
            "오늘 식탁 사진 기대돼!"
        ]
    }
    
    // MARK: - 이미지 리사이즈 헬퍼
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let factor = min(widthRatio, heightRatio)
        guard factor < 1.0 else { return image }
        
        let newSize = CGSize(width: size.width * factor, height: size.height * factor)
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
