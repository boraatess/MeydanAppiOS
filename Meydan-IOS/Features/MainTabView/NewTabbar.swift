//
//  NewTabbar.swift
//  Meydan-IOS
//
//  Created by bora ateş on 16.04.2026.
//

import Foundation
/*
 
 // 2. Özel TabBar'ımız
            ZStack(alignment: .topLeading) {
                // Katman 1: Arka Plan
                (Color.white)
                    .clipShape(TabBarShape(xAxis: xAxis))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -5)
                
                // Katman 2: İkonlar
                HStack(spacing: 0) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Button {
                            withAnimation(tabAnimation) {
                                selectedTab = tab
                            }
                        } label: {
                            Image(tab.rawValue)
                                .resizable().renderingMode(.template)
                                .scaledToFit().frame(width: 24, height: 24)
                            // Seçili ikon, alttaki baloncukta çizildiği için burada gizlenir.
                                .foregroundColor(selectedTab == tab ? .clear : .secondary)
                                .frame(maxWidth: .infinity)
                                .overlay(
                                    // Butonun orta noktasını yakalamak için
                                    GeometryReader { proxy in
                                        let midX = proxy.frame(in: .named("TabBar")).midX
                                        Color.clear
                                            .onAppear {
                                                tabPositions[tab] = midX
                                            }
                                            .onChange(of: selectedTab) { newValue in
                                                if tab == newValue {
                                                    xAxis = midX
                                                }
                                            }
                                    }
                                )
                        }
                    }
                }
                // İkonların üzerinden bırakılan boşluk.
                .padding(.top, 8)
                
                // Katman 3: Animasyonlu Baloncuk ve Seçili İkon
                Circle()
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(selectedTab.rawValue)
                            .resizable().renderingMode(.template)
                            .scaledToFit().frame(width: 24, height: 24)
                            .foregroundColor(.black)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -5)
                    .position(x: xAxis)
                    .offset(y: 0)
                    .animation(tabAnimation, value: selectedTab)
                
            }
            .frame(height: 55)
            .coordinateSpace(name: "TabBar")
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    if let homePosition = tabPositions[.home] {
                        xAxis = homePosition
                    }
                }
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
 
 */
