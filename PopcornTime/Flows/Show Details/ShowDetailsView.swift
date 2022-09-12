//
//  ShowDetailsView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 04.07.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornKit
import Kingfisher

struct ShowDetailsView: View, MediaPosterLoader {
    let theme = Theme()
    
    @StateObject var viewModel: ShowDetailsViewModel
    @State var showSeasonPicker: Bool = false
    
    var show: Show {
        return viewModel.show
    }
    
    @Namespace var section1
    @Namespace var section2
    @Namespace var section3
    @Environment(\.openURL) var openURL
    
    var body: some View {
        ZStack {
            backgroundImage()
            ScrollViewReader { scroll in
                ScrollView {
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(show.title)
                                    .font(theme.titleFont)
                                    .padding(.bottom, 50)
                                    .padding(.top, 200)
                                    .multilineTextAlignment(.center)
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 50) {
                                
                                infoText
                                Color.clear
                                    .overlay(alignment: .topLeading, content: {
                                        VStack(alignment: .leading, spacing: 20) {
                                            Text(show.summary)
                                                .multilineTextAlignment(.leading)
                                            awards()
                                        }
                                    })
                                    .frame(maxWidth: theme.summaryMaxWidth)
                                actionButtons(scroll: scroll)
                                    .padding(.bottom, 20)
                            }
                        }
                        .id(section1)
                        #if os(tvOS)
                        .frame(idealHeight: 1010)
                        .padding([.leading, .trailing], 100)
                        #else
                        .frame(idealHeight: 780)
                        .padding([.leading, .trailing], theme.watchedSection.leading)
                        #endif
                    }
                    #if os(tvOS)
                    .focusSection()
                    #endif
                    
                    LazyVStack(alignment: .center) {
                        if show.episodes.count > 0 {
                            EpisodesView(show: viewModel.show, episodes: viewModel.seasonEpisodes(), currentSeason: viewModel.currentSeason, currentEpisode: viewModel.latestUnwatchedEpisode, onFocus: {
                                #if os(tvOS)
                                withAnimation() {
                                    scroll.scrollTo(section2, anchor: .top)
                                }
                                #endif
                            })
                            #if os(tvOS)
                            .focusSection()
                            #endif
                        }
                        
                        if viewModel.related.count > 0 {
                            alsoWatchedSection(scroll: scroll)
                                #if os(tvOS)
                                .focusSection()
                                #endif
                        }
                        if viewModel.persons.count > 0 {
                            ActorsCrewView(persons: $viewModel.persons)
                            #if os(tvOS)
                            .focusSection()
                            #endif
                        }
                    }
                    .padding([.bottom, .top], 30)
                    .background( show.episodes.isEmpty ? .clear : Color.init(white: 0, opacity: 0.3))
//                    .padding(.top, 50)
                    .id(section2)
                }
            }
            if let error = viewModel.error {
                BannerView(error: error)
                    .padding([.top, .trailing], 60)
                    .transition(.move(edge: .top))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            viewModel.error = nil
                        }
                    }
            }
        }.onAppear {
            if !showSeasonPicker {
                viewModel.playSongTheme()
                viewModel.load()
            }
        }.onDisappear {
            if !showSeasonPicker {
                viewModel.stopTheme()
            }
        }
        .environmentObject(viewModel)
        .ignoresSafeArea()
    }
    
    func backgroundImage() -> some View {
        Color.clear
            .background(
                KFImage(viewModel.backgroundUrl)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .padding(0)
            )
            .overlay(
                Color(white: 0, opacity: theme.backgroundOpacity))
            .clipped()
    }

    var infoText: some View {
        let localizedSeason = NumberFormatter.localizedString(from: NSNumber(value: viewModel.currentSeason), number: .none)
        let season = viewModel.currentSeason > -1 ? " \(localizedSeason)" : ""
        let title = "Season".localized + season
        
        let genre = show.genres.first?.localizedCapitalized.localized
        let year = show.year
        
        let items = [genre, year].compactMap({$0}).map{Text($0)}
        let certifications = (["HD", "CC"]).map { Text(Image($0).renderingMode(.template)) }
        
        let watchOn: String = .localizedStringWithFormat("Watch %@ on %@".localized, show.title, show.network ?? "TV")
        let runtime = "Run Time".localized + " \(show.runtime ?? 0) min"
        
        return VStack(alignment: .leading) {
            Text(title)
                .font(.system(size: theme.seasonFontSize, weight: .medium))
            HStack(alignment: .center, spacing: 25) {
                ForEach(0..<items.count, id: \.self) { item in
                    items[item]
                }
                ForEach(0..<certifications.count, id: \.self) { item in
                    certifications[item]
                }
                .hideIfCompactSize()
                
                StarRatingView(rating: show.rating / 20)
                    .frame(width: theme.starSize.width, height: theme.starSize.height)
                    .padding(.top, theme.starOffset)
            }
            Group {
                Text(watchOn)
//                Text(runtime)
                RatingsView(viewModel: RatingsViewModel(media: show, ratings: show.ratings))
            }
            .foregroundColor(.appSecondary)
        }
        .font(.callout)
    }
    
    func actionButtons(scroll: ScrollViewProxy?) -> some View {
        HStack(spacing: 24) {
            if viewModel.didLoad {
                if let episode = viewModel.nextEpisodeToWatch() {
                    PlayButton(media: episode)
                }
                if viewModel.show.seasonNumbers.count > 1 {
                    seasonsButton
                }
                watchlistButton
                    .hideIfCompactSize()
            }
            if viewModel.isLoading {
                ProgressView()
                    .padding(.leading, 50)
                    .padding(.bottom, 40)
            }
        }
        .buttonStyle(TVButtonStyle(onFocus: {
            #if os(tvOS)
            withAnimation {
                scroll?.scrollTo(section1, anchor: .top)
            }
            #endif
        }))
    }
    
    var seasonsButton: some View {
        ZStack {
            NavigationLink(
                destination: SeasonPickerView(viewModel: SeasonPickerViewModel(show: show), selectedSeasonNumber: $viewModel.currentSeason),
                isActive: $showSeasonPicker,
                label: {
                    EmptyView()
                })
                .hidden()
            
            Button(action: {
                showSeasonPicker = true
            }, label: {
                VStack {
                    VisualEffectBlur() {
                        Image("Seasons")
                    }
                    Text("Series")
                }
            })
            .frame(width: theme.buttonWidth, height: theme.buttonHeight)
        }
    }
    
    var watchlistButton: some View {
        return Button(action: {
            viewModel.show.isAddedToWatchlist.toggle()
        }, label: {
            VStack {
                VisualEffectBlur() {
                    show.isAddedToWatchlist ? Image("Remove") : Image("Add")
                }
                Text("Watchlist")
            }
        })
        .frame(width: theme.buttonWidth, height: theme.buttonHeight)
    }
    
    func alsoWatchedSection(scroll: ScrollViewProxy) -> some View {
        VStack (alignment: .leading) {
            Text("Viewers Also Watched")
                .font(.callout)
                .foregroundColor(.appSecondary)
                .padding(.leading, theme.watchedSection.leading)
                .padding(.top, 14)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .center, spacing: theme.watchedSection.spacing) {
                    ForEach(viewModel.related, id: \.id) { show in
                        NavigationLink(
                            destination: ShowDetailsView(viewModel: ShowDetailsViewModel(show: show)),
                            label: {
                                ShowView(show: show)
                                    .frame(width: theme.watchedSection.cellWidth)
                            })
                            .buttonStyle(PlainNavigationLinkButtonStyle(onFocus: {
//                                withAnimation {
//                                    scroll.scrollTo(section3, anchor: .top)
//                                }
                            }))
                            .task {
                                await loadPosterIfMissing(media: show, mediaPosters: $viewModel.related)
                            }
                    }
                }
                .padding(.horizontal, theme.watchedSection.leading)
                #if os(tvOS)
                .padding([.top, .bottom], 20) // on focus zoom will not be clipped
                #endif
            }
        }
        .frame(height: theme.watchedSection.height)
        .padding(0)
        .id(section3)
        .background(
            Color(white: 0, opacity: 0.3)
                .padding([.bottom], -10)
            #if os(tvOS)
                .padding([.top], -30)
            #endif
        )
    }
    
    @ViewBuilder
    func awards() -> some View {
        if let awards = show.ratings?.awards {
            Text("Awards: " + awards)
                .font(.caption)
        }
    }
}

extension ShowDetailsView {
    struct Theme {
        let buttonWidth: CGFloat = value(tvOS: 142, macOS: 100)
        let buttonHeight: CGFloat = value(tvOS: 115, macOS: 81)
        
        let starSize: CGSize = value(tvOS: CGSize(width: 220, height: 40), macOS: CGSize(width: 110, height: 20))
        let starOffset: CGFloat = value(tvOS: -8, macOS: -4)
        var watchedSection: (height: CGFloat, cellWidth: CGFloat, cellHeight: CGFloat, spacing: CGFloat, leading: CGFloat)
        { (height: value(tvOS: 475, macOS: 280),
               cellWidth: value(tvOS: 220, macOS: 150),
               cellHeight: value(tvOS: 460, macOS: 180),
               spacing: value(tvOS: 80, macOS: 30),
            leading: value(tvOS: 90, macOS: 50, compactSize: 20)) }
        let backgroundOpacity = value(tvOS: 0.3, macOS: 0.5)
        let seasonFontSize: CGFloat = value(tvOS: 43, macOS: 21)
        let titleFont: Font = Font.system(size: value(tvOS: 76, macOS: 50), weight: .medium)
        let summaryMaxWidth: CGFloat = value(tvOS: 1200, macOS: 800)
    }
}

struct ShowDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        let show = Show.dummy()
        let model = ShowDetailsViewModel(show: show)
        model.currentSeason = show.latestUnwatchedEpisode()?.season ?? show.seasonNumbers.first ?? -1
        model.persons = show.actors
        model.related = show.related
        model.didLoad = true
        
        return Group {
            ShowDetailsView(viewModel: model)
//                .previewInterfaceOrientation(.portrait)
            
            ShowDetailsView(viewModel: model)
            #if os(tvOS)
            .previewLayout(.fixed(width: 2000, height: 2400))
            #else
            .previewLayout(.fixed(width: 1024, height: 1800))
            #endif
        }
        .preferredColorScheme(.dark)
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
