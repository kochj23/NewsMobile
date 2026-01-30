//
//  AudioBriefingView.swift
//  NewsMobile
//
//  Audio briefing player
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct AudioBriefingView: View {
    let articles: [NewsArticle]
    @StateObject private var tts = TTSManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Current article info
                if let article = tts.currentArticle {
                    VStack(spacing: 12) {
                        Image(systemName: article.category.icon)
                            .font(.system(size: 50))
                            .foregroundColor(Color(hex: article.category.color))

                        Text(article.source.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(article.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)

                        Text("Audio Briefing")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("\(articles.count) articles ready")
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Progress
                VStack(spacing: 8) {
                    ProgressView(value: Double(tts.currentArticleIndex), total: Double(articles.count))
                        .tint(.blue)

                    Text("\(tts.currentArticleIndex + 1) of \(articles.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Controls
                HStack(spacing: 40) {
                    Button {
                        tts.previous()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.title)
                    }

                    Button {
                        if tts.isPlaying {
                            tts.pause()
                        } else if tts.currentArticle != nil {
                            tts.resume()
                        } else {
                            tts.startBriefing(articles: articles)
                        }
                    } label: {
                        Image(systemName: tts.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 70))
                    }

                    Button {
                        tts.next()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title)
                    }
                }
                .foregroundColor(.primary)

                // Stop button
                Button {
                    tts.stop()
                    dismiss()
                } label: {
                    Text("Stop Briefing")
                        .foregroundColor(.red)
                }
                .padding(.top)

                Spacer()
            }
            .navigationTitle("Audio Briefing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onDisappear {
            tts.stop()
        }
    }
}

#Preview {
    AudioBriefingView(articles: [])
}
