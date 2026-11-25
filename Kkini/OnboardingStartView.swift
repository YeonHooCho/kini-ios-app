import SwiftUI

struct OnboardingStartView: View {
    var onSelectCreate: () -> Void  // 가족 식탁 생성하기 클릭 시
    var onSelectJoin: () -> Void    // 가족 식탁 참여하기 클릭 시

    // 온보딩 전용 브라운 & 툴팁 컬러
    private let primaryBrown = Color(red: 163/255, green: 132/255, blue: 82/255)
    private let tooltipBg = Color(red: 215/255, green: 196/255, blue: 162/255)
    private let textDarkBrown = Color(red: 84/255, green: 68/255, blue: 44/255)

    var body: some View {
        ZStack {
            // 배경 컬러
            Color(red: 254/255, green: 247/255, blue: 236/255)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // MARK: - 1. 타이틀 & 서브 슬로건
                VStack(spacing: 14) {
                    Text("KINI: 끼니")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundColor(textDarkBrown)
                        .tracking(0.5)

                    Text("“한 끼가 한 마디가 되고, 하루가 되고, 관계가 됩니다.”")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(textDarkBrown.opacity(0.85))
                        .multilineTextAlignment(.center)
                }

                Spacer()
                    .frame(height: 72)

                // MARK: - 2. 생성 / 참여 버튼 영역
                VStack(spacing: 16) {
                    // 1) 가족 식탁 생성하기
                    Button(action: onSelectCreate) {
                        Text("가족 식탁 생성하기")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(primaryBrown)
                            .clipShape(Capsule())
                    }

                    // 2) 가족 식탁 참여하기
                    Button(action: onSelectJoin) {
                        Text("가족 식탁 참여하기")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(primaryBrown)
                            .clipShape(Capsule())
                    }

                    // 3) 참여하기 하단 툴팁 말풍선
                    VStack(spacing: 0) {
                        // 위쪽 꼭짓점 꼬리
                        UpwardPointerTriangle()
                            .fill(tooltipBg)
                            .frame(width: 14, height: 7)

                        // 툴팁 캡슐 뱃지
                        Text("이미 생성된 가족 식탁이 있어요!")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(textDarkBrown.opacity(0.9))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(tooltipBg)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }
}

// MARK: - 툴팁 상단 꼬리 셰이프
struct UpwardPointerTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    OnboardingStartView(
        onSelectCreate: { print("식탁 생성 클릭") },
        onSelectJoin: { print("식탁 참여 클릭") }
    )
}
