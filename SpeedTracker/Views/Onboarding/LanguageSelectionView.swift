//
//  LanguageSelectionView.swift
//  SpeedTracker
//
//  First screen - language picker
//

import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var theme: ThemeManager
    @AppStorage(AppConstants.UserDefaultsKeys.hasSelectedLanguage) private var hasSelectedLanguage = false
    @AppStorage(AppConstants.UserDefaultsKeys.preferredLanguage) private var preferredLanguage = "en"
    @State private var selectedLanguage: AppConstants.SupportedLanguage = .english
    @State private var appeared = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            // Background
            theme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Title
                VStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 50, weight: .light))
                        .foregroundStyle(theme.primaryGradient)
                        .padding(.top, 60)
                    
                    Text("Choose Language")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                    
                    Text("Select your preferred language")
                        .font(.system(size: 16))
                        .foregroundColor(theme.textSecondary)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -20)
                .padding(.bottom, 30)
                
                // Language Grid
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(AppConstants.SupportedLanguage.allCases, id: \.rawValue) { lang in
                            LanguageCard(
                                language: lang,
                                isSelected: selectedLanguage == lang,
                                theme: theme
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedLanguage = lang
                                }
                                HapticManager.shared.selection()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                .opacity(appeared ? 1 : 0)
                
                Spacer()
                
                // Continue button
                AnimatedButton("Continue", icon: "arrow.right", variant: .primary) {
                    preferredLanguage = selectedLanguage.rawValue
                    // Wire iOS bundle localization — takes effect on next launch
                    UserDefaults.standard.set([selectedLanguage.rawValue], forKey: "AppleLanguages")
                    UserDefaults.standard.synchronize()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        hasSelectedLanguage = true
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
            }
        }
        .onAppear {
            // Detect system language
            let systemLang = Locale.preferredLanguages.first ?? "en"
            for lang in AppConstants.SupportedLanguage.allCases {
                if systemLang.hasPrefix(lang.rawValue) {
                    selectedLanguage = lang
                    break
                }
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct LanguageCard: View {
    let language: AppConstants.SupportedLanguage
    let isSelected: Bool
    let theme: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(language.flagEmoji)
                    .font(.system(size: 24))
                
                Text(language.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : theme.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? AnyShapeStyle(theme.primaryGradient) : AnyShapeStyle(theme.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isSelected ? AnyShapeStyle(Color.clear) : AnyShapeStyle(theme.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1)),
                        lineWidth: 1
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    LanguageSelectionView()
        .environmentObject(ThemeManager.shared)
}
