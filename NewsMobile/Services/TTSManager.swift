//
//  TTSManager.swift
//  NewsMobile
//
//  Text-to-Speech manager for audio briefings
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import AVFoundation

@MainActor
class TTSManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = TTSManager()

    @Published var isPlaying = false
    @Published var currentArticleIndex = 0
    @Published var currentArticle: NewsArticle?

    private let synthesizer = AVSpeechSynthesizer()
    private var articles: [NewsArticle] = []
    private var onComplete: (() -> Void)?

    override private init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenContent, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    func startBriefing(articles: [NewsArticle], startIndex: Int = 0) {
        self.articles = articles
        self.currentArticleIndex = startIndex
        speakCurrentArticle()
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        currentArticle = nil
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .word)
        isPlaying = false
    }

    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            isPlaying = true
        }
    }

    func next() {
        synthesizer.stopSpeaking(at: .immediate)
        currentArticleIndex += 1
        if currentArticleIndex < articles.count {
            speakCurrentArticle()
        } else {
            isPlaying = false
            currentArticle = nil
        }
    }

    func previous() {
        synthesizer.stopSpeaking(at: .immediate)
        if currentArticleIndex > 0 {
            currentArticleIndex -= 1
        }
        speakCurrentArticle()
    }

    private func speakCurrentArticle() {
        guard currentArticleIndex < articles.count else {
            isPlaying = false
            return
        }

        let article = articles[currentArticleIndex]
        currentArticle = article

        let settings = SettingsManager.shared.settings
        let rate = settings.speechRate.rate

        var textToSpeak = "From \(article.source.name). \(article.title)."
        if let description = article.rssDescription {
            textToSpeak += " \(description)"
        }

        let utterance = AVSpeechUtterance(string: textToSpeak)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }

        isPlaying = true
        synthesizer.speak(utterance)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.currentArticleIndex += 1
            if self.currentArticleIndex < self.articles.count {
                try? await Task.sleep(nanoseconds: 500_000_000)
                self.speakCurrentArticle()
            } else {
                self.isPlaying = false
                self.currentArticle = nil
                self.onComplete?()
            }
        }
    }
}
