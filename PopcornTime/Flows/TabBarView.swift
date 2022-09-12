//
//  TabBarView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 19.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI

struct CurrentTabKey: EnvironmentKey {
    static var defaultValue: TabBarView.Selection = .movies
}
extension EnvironmentValues {
    var currentTab: TabBarView.Selection {
        get { self[CurrentTabKey.self] }
        set { self[CurrentTabKey.self] = newValue }
    }
}

struct TabBarView: View {
    enum Selection: Int {
        case movies = 0, shows, watchlist, search, downloads, settings
    }
    @State var selectedTab = Selection.movies
    #if os(macOS)
    @Environment(\.popToRoot) var popToRoot
    @State var isVisible = false
    #endif
    
    @StateObject var searchModel = SearchViewModel()
    
    var body: some View {
        #if os(iOS) || os(tvOS)
        TabView(selection: $selectedTab) {
            MoviesView()
                .tabItem {
                    #if os(iOS)
                    Image("Movies On").renderingMode(.template)
                    #endif
                    Text("Movies")
                }
                .tag(Selection.movies)
            ShowsView()
                .tabItem {
                    #if os(iOS)
                    Image("Shows On").renderingMode(.template)
                    #endif
                    Text("Shows")
                }
                .tag(Selection.shows)
            WatchlistView()
                .tabItem {
                    #if os(iOS)
                    Image("Watchlist On").renderingMode(.template)
                    #endif
                    Text("Watchlist")
                }
                .tag(Selection.watchlist)
                .hideIfCompactSize()
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    #if os(iOS)
                    Text("Search")
                    #endif
                }
                .tag(Selection.search)
            DownloadsView()
                .tabItem {
                    #if os(iOS)
                    Image(systemName: "square.and.arrow.down")
                    #endif
                    Text("Downloads")
                }
                .tag(Selection.downloads)
            #if os(tvOS) || os(iOS)
            SettingsView()
                .tabItem {
                    #if os(iOS)
                    Image("Settings On").renderingMode(.template)
                    #endif
                    Text("Settings")
                }
                .tag(Selection.settings)
            #endif
            
        }
        .environment(\.currentTab, selectedTab)
        .ignoresSafeArea()
        #elseif os(macOS)
        ZStack {
            MoviesView()
                .hide(selectedTab != .movies)
            ShowsView()
                .hide(selectedTab != .shows)
            WatchlistView()
                .hide(selectedTab != .watchlist)
            SearchView(viewModel: searchModel)
                .hide(selectedTab != .search)
            DownloadsView()
                .hide(selectedTab != .downloads)
            if isVisible {
                EmptyView()
                    .searchable(text: $searchModel.search)
            }
        }
        .onChange(of: searchModel.search, perform: { newValue in
            selectedTab = .search
        })
        .onAppear(perform: {
            isVisible = true
        })
        .onDisappear(perform: {
            isVisible = false
        })
        .environment(\.currentTab, selectedTab)
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                Picker("", selection: .init(get: {
                    selectedTab
                }, set: { newValue in
                    selectedTab = newValue
                    popToRoot()
                })) {
                    Text("Movies").tag(Selection.movies)
                    Text("Shows").tag(Selection.shows)
                    Text("Watchlist").tag(Selection.watchlist)
                    Text("Downloads").tag(Selection.downloads)
//                     Image(systemName: "magnifyingglass").tag(Selection.search)
                }
                .pickerStyle(SegmentedPickerStyle())

            }
            
            ToolbarItem(placement: .principal) {
                Spacer()
            }
        })
        #endif
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}
