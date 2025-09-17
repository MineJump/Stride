import SwiftUI

struct LoadingView: View {
    @State private var x: CGFloat = -120
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                Image(systemName: "shoe")
                    .font(.system(size: 48, weight: .regular))
                    .offset(x: x, y: 0)
                    .onAppear {
                        let width = geo.size.width
                        x = -width/2
                        animate = true
                        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                            x = width/2
                        }
                    }
            }
        }
        .accessibilityLabel(Text("Loading"))
    }
}
