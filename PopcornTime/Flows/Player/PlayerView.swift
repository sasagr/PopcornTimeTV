//
//  PlayerView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 19.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI
import PopcornKit

struct PlayerView: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @Namespace private var namespace
    #if os(tvOS)
    @Environment(\.resetFocus) var resetFocus
    #endif
    
    var body: some View {
        ZStack {
            VLCPlayerView(mediaplayer: viewModel.mediaplayer)
            #if os(tvOS)
                .addGestures(onSwipeDown: {
                    withAnimation {
                        viewModel.showInfo = true
                    }
                }, onSwipeUp: {
                    withAnimation {
                        viewModel.showControls = true
                    }
                }, onTouchLocationDidChange: { gesture in
                    viewModel.touchLocationDidChange(gesture)
                }, onPositionSliderDrag: { offset in
                    viewModel.handlePositionSliderDrag(offset: offset)
                })
                .prefersDefaultFocus(!viewModel.showInfo, in: namespace)
                .focusable(!viewModel.showInfo)
                .onLongPressGesture(minimumDuration: 0.01, perform: {
                    withAnimation {
                        if viewModel.showControls {
                            viewModel.clickGesture()
                        } else {
                            viewModel.toggleControlsVisible()
                        }
                    }
                })
                .onPlayPauseCommand {
                    withAnimation {
                        viewModel.playandPause()
                    }
                }
                .onMoveCommand(perform: { direction in
                    switch direction {
                    case .down:
                        withAnimation(.spring()) {
                            viewModel.showInfo = true
                        }
                    case .up:
                        withAnimation(.spring()) {
                            viewModel.showControls = true
                        }
                    case .left:
                        viewModel.rewind()
                        viewModel.progress.hint = .rewind
                        viewModel.resetIdleTimer()
                    case .right:
                        viewModel.fastForward()
                        viewModel.progress.hint = .fastForward
                        viewModel.resetIdleTimer()
                    @unknown default:
                        break
                    }
                })
                .onExitCommand {
                    viewModel.stop()
                    presentationMode.wrappedValue.dismiss()
                }
            #else
                .onTapGesture {
                    withAnimation {
                        viewModel.toggleControlsVisible()
                    }
                }
            #endif
            controlsView
            showInfoView
        }
        .onAppear {
            viewModel.playOnAppear()
            viewModel.presentationMode = presentationMode // this screen can dismissed from viewModel
        }.onDisappear {
            viewModel.stop()
        }
        #if os(tvOS)
        .focusScope(namespace)
        .ignoresSafeArea()
        #endif
        .actionSheet(isPresented: $viewModel.resumePlaybackAlert, content: {
            ActionSheet(title: Text(""),
                        message: nil,
                        buttons: [
                            .default(Text("Resume Playing".localized)) {
                              self.viewModel.play(resumePlayback: true)
                            },
                            .default(Text("Start from Beginning".localized)) {
                              self.viewModel.play()
                            }
                        ])
        })
    }
    
    @ViewBuilder
    var dimmerView: some View {
        if viewModel.showControls {
            Color(white: 0, opacity: 0.3)
                .ignoresSafeArea()
        }
    }
    
    @ViewBuilder
    var controlsView: some View {
        if !viewModel.isLoading && viewModel.showControls {
            #if os(tvOS)
            VStack {
//                if viewModel.showInfo {
//                    Image("Now Playing Info")
//                        .padding(.top, 40)
//                }
                Spacer()
                ZStack {
                    Rectangle()
                        .foregroundColor(.clear)        // Making rectangle transparent
                        .background(LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .top, endPoint: .bottom))
                        .frame(height: 190)
                    ProgressBarView(progress: viewModel.progress)
                        .frame(height: 10)
                        .padding([.leading, .trailing], 90)
                }
            }
                .transition(.move(edge: .bottom))
            #elseif os(iOS)
            PlayerControlsView()
                .transition(.opacity)
            #endif
        }
    }
    
    @ViewBuilder
    var showInfoView: some View {
        if viewModel.showInfo {
            VStack {
                PlayerOptionsView(media: viewModel.media,
                                  audioDelay: viewModel.audioDelayBinding,
                                  audioProfile: viewModel.audioProfileBinding,
                                  subtitleDelay: viewModel.subtitleDelayBinding,
                                  subtitleEncoding: viewModel.subtitleEncodingBinding,
                                  subtitle: viewModel.subtitleBinding)
                #if os(tvOS)
                .prefersDefaultFocus(in: namespace)
                .onExitCommand(perform: {
                    withAnimation(.spring()) {
                        viewModel.showInfo = false
                    }
                })
                .onPlayPauseCommand {
                    viewModel.playandPause()
                }
                #endif
                Spacer()
            }
            .zIndex(1)
            .transition(.move(edge: .top))
            #if os(tvOS)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    resetFocus(in: namespace)
                }
            }
            #endif
        }
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        let url = URL(string: "http://www.youtube.com/watch?v=zI2qbr99H64")!
        let loadingModel = PlayerViewModel(media: Movie.dummy(), fromUrl: url, localUrl: url, directory: url, streamer: .shared())
        
        let showControlsModel = PlayerViewModel(media: Movie.dummy(), fromUrl: url, localUrl: url, directory: url, streamer: .shared())
        showControlsModel.isLoading = false
        showControlsModel.showControls = true
        showControlsModel.showInfo = true
        
        
        return Group {
            PlayerView()
                .background(Color.blue)
                .environmentObject(showControlsModel)
            PlayerView()
                .background(Color.blue)
                .environmentObject(loadingModel)
        }
    }
    
    static var dummyPreview: some View {
        let url = URL(string: "http://www.youtube.com/watch?v=zI2qbr99H64")!
        
        let showControlsModel = PlayerViewModel(media: Movie.dummy(), fromUrl: url, localUrl: url, directory: url, streamer: .shared(), testingMode: true)
        showControlsModel.isLoading = false
        showControlsModel.showControls = false
        showControlsModel.showInfo = false
        showControlsModel.isPlaying = true
        showControlsModel.progress = .init(progress: 0.2, isBuffering: false, bufferProgress: 0.7, isScrubbing: false, scrubbingProgress: 0, remainingTime: "03 min", elapsedTime: "05 min", scrubbingTime: "la la", screenshot: nil, hint: .none)
        
        
        return Group {
            PlayerView()
                .background(Color.blue)
                .environmentObject(showControlsModel)
        }
    }
}

