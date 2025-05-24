//
//  MainTabView.swift
//  Habita
//
//  Created by Hubert on 19/05/2025.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @Namespace private var animationNamespace
    @GestureState private var dragOffset: CGFloat = 0
    
    let tabs = [
        (view: AnyView(HomeView()), icon: "house", label: "Home"),
        (view: AnyView(SummaryView()), icon: "chart.bar", label: "Stats"),
        (view: AnyView(SettingsView()), icon: "gear", label: "Settings")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(0..<tabs.count, id: \.self) { index in
                    tabs[index].view
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(x: positionOffset(for: index))
                        .animation(.interactiveSpring(), value: selectedTab)
                        .animation(.interactiveSpring(), value: dragOffset)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tabs[index].icon)
                                .symbolVariant(selectedTab == index ? .fill : .none)
                                .font(.system(size: 22))
                                .foregroundColor(selectedTab == index ? .yellow : .gray)
                            
                            Text(tabs[index].label)
                                .font(.system(size: 10, weight: selectedTab == index ? .bold : .medium))
                                .foregroundColor(selectedTab == index ? .yellow : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .background(Color(.systemBackground))
        }
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    let canSwipeLeft = (selectedTab < tabs.count - 1)
                    let canSwipeRight = (selectedTab > 0)
                    
                    let translation = value.translation.width
                    
                    if (translation < 0 && !canSwipeLeft) || (translation > 0 && !canSwipeRight) {
                        state = 0
                    } else {
                        state = translation
                    }
                }
                .onEnded { value in
                    let threshold: CGFloat = 100
                    let translation = value.translation.width
                    
                    let canSwipeLeft = (selectedTab < tabs.count - 1)
                    let canSwipeRight = (selectedTab > 0)
                    
                    if translation > threshold && canSwipeRight {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab -= 1
                        }
                    } else if translation < -threshold && canSwipeLeft {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab += 1
                        }
                    }
                }
        )
    }
    
    private func positionOffset(for index: Int) -> CGFloat {
        let offset = CGFloat(index - selectedTab) * UIScreen.main.bounds.width
        return offset + dragOffset
    }
}
