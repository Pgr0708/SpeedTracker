//
//  GlassMorphismCard.swift
//  SpeedTracker
//
//  Reusable glass card component (works in dark and light mode)
//

import SwiftUI

struct GlassMorphismCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = AppConstants.Design.cornerRadiusL
    var padding: CGFloat = AppConstants.Design.paddingL
    
    init(
        cornerRadius: CGFloat = AppConstants.Design.cornerRadiusL,
        padding: CGFloat = AppConstants.Design.paddingL,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Base glass layer
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                        .opacity(0.4)
                    
                    // Gradient overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 20,
                x: 0,
                y: 10
            )
    }
}

// Preview
#Preview {
    ZStack {
        AppConstants.Colors.backgroundGradient
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            GlassMorphismCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Speed")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("125")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(AppConstants.Colors.electricBlue)
                    
                    Text("km/h")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
    }
}
