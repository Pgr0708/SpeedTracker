//
//  GlassMorphismCard.swift
//  SpeedTracker
//
//  Reusable liquid glass card component
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
                        .opacity(0.3)
                    
                    // Gradient overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05)
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
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .shadow(
                color: AppConstants.Colors.electricBlue.opacity(0.1),
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
                        .font(.headingMedium)
                        .foregroundColor(AppConstants.Colors.textPrimary)
                    
                    Text("125")
                        .font(.displayLarge)
                        .foregroundColor(AppConstants.Colors.electricBlue)
                    
                    Text("km/h")
                        .font(.bodyLarge)
                        .foregroundColor(AppConstants.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            GlassMorphismCard(cornerRadius: 16, padding: 16) {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .foregroundColor(AppConstants.Colors.limeGreen)
                    
                    VStack(alignment: .leading) {
                        Text("GPS Active")
                            .font(.bodyLarge)
                            .foregroundColor(AppConstants.Colors.textPrimary)
                        Text("Accuracy: High")
                            .font(.caption)
                            .foregroundColor(AppConstants.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
    }
}
