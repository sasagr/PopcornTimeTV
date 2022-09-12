//
//  SearchView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 19.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornKit

struct SearchView: View, CharacterHeadshotLoader {
    struct Theme {
        let itemWidth: CGFloat = value(tvOS: 240, macOS: 160)
        let personWidth: CGFloat  = value(tvOS: 220, macOS: 150)
        var horizontalPadding: CGFloat { value(tvOS: 40, macOS: 40, compactSize: 10) }
    }
    let theme = Theme()
    
    @StateObject var viewModel = SearchViewModel()
    
    var body: some View {
        VStack {
            searchView
            errorView
            if viewModel.isLoading {
                ProgressView()
            }
            switch viewModel.selection {
            case .movies:
                moviesSection
            case .shows:
                showsSection
            case .people:
                peopleSection
            }
            Spacer()
        }
        #if os(iOS) || os(tvOS)
        .searchable(text: $viewModel.search)
        #endif
        #if os(iOS)
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    @ViewBuilder
    var searchView: some View {
        #if os(iOS)
        VStack {
            SearchBarView(text: $viewModel.search)
            pickerView
            .pickerStyle(.segmented)
        }
        .padding([.top, .leading, .trailing])
        .padding(.horizontal, theme.horizontalPadding)
        #elseif os(tvOS)
        pickerView
        #elseif os(macOS)
        pickerView
            .pickerStyle(.segmented)
            .frame(maxWidth: 200)
            .padding()
        #endif
    }
    
    @ViewBuilder
    var pickerView: some View {
        Picker("", selection: $viewModel.selection) {
             Text("Movies").tag(SearchViewModel.SearchType.movies)
             Text("Shows").tag(SearchViewModel.SearchType.shows)
             Text("People").tag(SearchViewModel.SearchType.people)
        }
    }
    
    @ViewBuilder
    var moviesSection: some View {
        if viewModel.movies.isEmpty && !viewModel.isLoading {
            emptyView
        } else {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 40) {
                    ForEach(viewModel.movies, id: \.self) { movie in
                        NavigationLink(
                            destination: MovieDetailsView(viewModel: MovieDetailsViewModel(movie: movie)),
                            label: {
                                MovieView(movie: movie)
                                    .frame(width:theme.itemWidth)
                            })
                            .buttonStyle(PlainNavigationLinkButtonStyle())
                    }
                }
                #if os(iOS)
                    .padding(.leading, 50)
                #endif
            }
            #if os(tvOS)
            .focusSection()
            #endif
        }
    }
    
    @ViewBuilder
    var showsSection: some View {
        if viewModel.shows.isEmpty && !viewModel.isLoading {
            emptyView
        } else {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 40) {
                    ForEach(viewModel.shows, id: \.self) { show in
                        NavigationLink(
                            destination: ShowDetailsView(viewModel: ShowDetailsViewModel(show: show)),
                            label: {
                                ShowView(show: show)
                                    .frame(width:theme.itemWidth)
                            })
                            .buttonStyle(PlainNavigationLinkButtonStyle())
                    }
                }
                #if os(iOS)
                    .padding(.leading, 50)
                #endif
            }
            #if os(tvOS)
            .focusSection()
            #endif
        }
    }
    
    @ViewBuilder
    var peopleSection: some View {
        if viewModel.persons.isEmpty && !viewModel.isLoading {
            emptyView
        } else {
            let persons = viewModel.persons
            
            ScrollView(.horizontal) {
                LazyHStack(spacing: 40) {
                    ForEach(0..<persons.count, id: \.self) { index in
                        NavigationLink(
                            destination: PersonDetailsView(viewModel: PersonDetailsViewModel(person: persons[index])),
                            label: {
                                PersonView(person: persons[index], radius: theme.personWidth)
                            })
                            .buttonStyle(PlainNavigationLinkButtonStyle())
                            .task {
                                await loadHeadshotIfMissing(person: persons[index], into: $viewModel.persons)
                            }
                    }
                }
                #if os(iOS)
                    .padding(.leading, 50)
                #endif
                #if os(tvOS)
                    .frame(height: 321)
                #endif
                Spacer()
            }
            #if os(tvOS)
            .focusSection()
            #endif
        }
    }
    
    @ViewBuilder
    var errorView: some View {
        if let error = viewModel.error {
            HStack() {
                Spacer()
                ErrorView(error: error)
                    .padding(.bottom, 100)
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    var emptyView: some View {
        if viewModel.search.count > 0 && viewModel.error == nil {
            let openQuote = Locale.current.quotationBeginDelimiter ?? "\""
            let closeQuote = Locale.current.quotationEndDelimiter ?? "\""
            let description = String.localizedStringWithFormat("We didn't turn anything up for %@. Try something else.".localized, "\(openQuote + viewModel.search + closeQuote)")
            
            VStack {
                Spacer()
                Text("No results")
                    .font(.title2)
                    .padding()
                Text(description)
                    .font(.callout)
                    .foregroundColor(.appSecondary)
                    .frame(maxWidth: 400)
                    .multilineTextAlignment(.center)
                Spacer()
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
