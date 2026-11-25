import SwiftUI

struct SplashView: View {
    // 뷰가 처음 생성될 때 두 이미지 중 하나를 랜덤으로 선택해 고정
    @State private var selectedImageName: String = ["splash_image_1", "splash_image_2"].randomElement() ?? "splash_image"
    
    // 배경 크림색을 일치시켜 다양한 기기 비율에서도 여백 없이 매끄럽게 처리
    private let splashBgColor = Color(red: 254/255, green: 247/255, blue: 236/255)
    
    var body: some View {
        ZStack {
            splashBgColor
                .ignoresSafeArea()
            
            Image(selectedImageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    SplashView()
}
