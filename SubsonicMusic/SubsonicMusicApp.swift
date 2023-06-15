//
//  SubsonicMusicApp.swift
//  SubsonicMusic
//
//  Created by Arna13 on 13/6/23.
//

import SwiftUI

@main
struct SubsonicMusicApp: App {    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(PlaylistsViewModel())
                .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
        }
    }
}
