//
//  MesiteroRootView.swift
//  MeshiTero
//
//  Created by 岩﨑蝶々 on 2026/05/26.
//

import SwiftUI

struct MesiteroRootView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        if appState.currentUser == nil {
            AuthView()
        } else {
            MainTabView()
        }
    }
}

#Preview {
    MesiteroRootView()
        .environment(AppState())
}
