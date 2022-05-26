//
//  PersonDetailView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 04.07.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornKit
import Kingfisher

struct PersonDetailsView: View, MediaPosterLoader {
    let theme = Theme()
    @StateObject var viewModel: PersonDetailsViewModel
    
    var body: some View {
        ZStack {
            ScrollView {
                HStack {
                    if let image = viewModel.person.mediumImage {
                        KFImage(URL(string: image))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    Text(viewModel.person.name)
                        .font(.title)
                }
                if viewModel.movies.count > 0 {
                    movieSection
                }
                if viewModel.shows.count > 0 {
                    showSection
                }
            }
//            .padding(.horizontal)
            .ignoresSafeArea(edges: [.leading, .trailing])
            .onAppear {
                viewModel.load()
            }
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
    
    @ViewBuilder
    var movieSection: some View {
        VStack(alignment: .leading) {
            Text("Movies")
                .font(.callout)
                .foregroundColor(.appSecondary)
                .padding(.top, 14)
                .padding(.leading, theme.leading)
            ScrollView(.horizontal) {
                LazyHStack(spacing: theme.spacing) {
                    ForEach(viewModel.movies, id: \.id) { movie in
                        NavigationLink(
                            destination: MovieDetailsView(viewModel: MovieDetailsViewModel(movie: movie)),
                            label: {
                                MovieView(movie: movie)
                                    .frame(width: 240)
                            })
                            .buttonStyle(PlainNavigationLinkButtonStyle())
                            .task {
                                await loadPosterIfMissing(media: movie, mediaPosters: $viewModel.movies)
                            }
//                            .padding([.leading, .trailing], 10)
                    }
                    .padding(20) // allow zoom
                }
                .padding(.all, 0)
                .padding(.leading, theme.leading)
            }
        }
    }
    
    @ViewBuilder
    var showSection: some View {
        VStack(alignment: .leading) {
            Text("Shows")
                .font(.callout)
                .foregroundColor(.appSecondary)
                .padding(.top, 14)
                .padding(.leading, theme.leading)
            ScrollView(.horizontal) {
                LazyHStack(spacing: theme.spacing) {
                    ForEach(viewModel.shows, id: \.id) { show in
                        NavigationLink(
                            destination: ShowDetailsView(viewModel: ShowDetailsViewModel(show: show)),
                            label: {
                                ShowView(show: show)
                                    .frame(width: 240)
                            })
                            .buttonStyle(PlainNavigationLinkButtonStyle())
                            .task {
                                await loadPosterIfMissing(media: show, mediaPosters: $viewModel.shows)
                            }
//                            .padding([.leading, .trailing], 10)
                    }
                    .padding(20) // allow zoom
                }
                .padding(.all, 0)
                .padding(.leading, theme.leading)
            }
        }
    }
}

extension PersonDetailsView {
    struct Theme {
        let leading: CGFloat = value(tvOS: 90, macOS: 50)
        let spacing: CGFloat = value(tvOS: 40, macOS: 20)
    }
}

struct PersonDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let actor = Actor(name: "Chuck Norris", imdbId: "23", tmdbId: 2, largeImage: nil)
        let viewModel = PersonDetailsViewModel(person: actor)
        viewModel.movies = Movie.dummiesFromJSON()
        viewModel.shows = Show.dummiesFromJSON()
        viewModel.didLoad = true
        
        return VStack {
            PersonDetailsView(viewModel: viewModel)
        }
//        .preferredColorScheme(.dark)
    }
}
