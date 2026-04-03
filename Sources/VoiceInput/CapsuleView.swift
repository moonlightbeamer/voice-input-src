import SwiftUI
import Combine

class WindowModel: ObservableObject {
    @Published var text: String = ""
    @Published var isRefining: Bool = false
    @Published var isAnimatingIn: Bool = false
    
    // We don't necessarily need exact text width unless we bound the capsule manually.
    // SwiftUI HStack naturally bounds to its contents.
}

struct WaveformView: View {
    @ObservedObject var audioEngine: AudioEngine
    let weights: [Float] = [0.5, 0.8, 1.0, 0.75, 0.55]
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.primary.opacity(0.8))
                    .frame(width: 5, height: barHeight(for: index))
                    .animation(.linear(duration: 0.05), value: audioEngine.rmsValue)
            }
        }
        .frame(width: 44, height: 32)
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 4.0
        let maxHeight: CGFloat = 28.0
        
        let jitter = Float.random(in: -0.04...0.04)
        let weight = weights[index] + jitter
        
        let level = max(0.0, min(1.0, audioEngine.rmsValue))
        let height = baseHeight + CGFloat(level * weight) * maxHeight
        
        return height
    }
}

struct CapsuleView: View {
    @ObservedObject var model: WindowModel
    @ObservedObject var audioEngine: AudioEngine
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                WaveformView(audioEngine: audioEngine)
                    .padding(.leading, 12)
                
                let displayText = model.isRefining ? "Refining..." : (model.text.isEmpty ? "Listening..." : model.text)
                
                Text(displayText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .padding(.trailing, 20)
                    .padding(.leading, 4)
                    .animation(nil, value: displayText)
            }
            .frame(height: 56)
            // Using min/max constraints for the elastic effect
            .frame(minWidth: 160, maxWidth: 560)
            .background(
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(model.isAnimatingIn ? 1.0 : 0.8)
            .opacity(model.isAnimatingIn ? 1.0 : 0.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: model.text)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: model.isAnimatingIn)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
