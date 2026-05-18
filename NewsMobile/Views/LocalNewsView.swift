//
//  LocalNewsView.swift
//  NewsMobile
//
//  Local news based on location
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct LocalNewsView: View {
    @StateObject private var localNews = LocalNewsService.shared
    @State private var selectedArticle: NewsArticle?
    @State private var showLocationPicker = false

    var body: some View {
        NavigationStack {
            Group {
                if localNews.currentLocation == nil {
                    setupView
                } else if localNews.isLoading {
                    loadingView
                } else if localNews.localArticles.isEmpty {
                    emptyView
                } else {
                    articlesList
                }
            }
            .navigationTitle("Local News")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showLocationPicker = true
                    } label: {
                        Label(localNews.currentLocation ?? "Set Location", systemImage: "location")
                    }
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView()
            }
            .sheet(item: $selectedArticle) { article in
                ArticleDetailView(article: article)
            }
        }
    }

    private var setupView: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.circle")
                .font(.system(size: 70))
                .foregroundColor(.orange)

            Text("Set Your Location")
                .font(.title)
                .fontWeight(.bold)

            Text("Enter your ZIP code or select a city to see local news.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showLocationPicker = true
            } label: {
                Label("Set Location", systemImage: "mappin.and.ellipse")
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading local news...")
                .foregroundColor(.secondary)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "newspaper")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Local News")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Try a different location.")
                .foregroundColor(.secondary)
        }
    }

    private var articlesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(localNews.localArticles) { article in
                    ArticleCard(article: article)
                        .onTapGesture {
                            selectedArticle = article
                        }
                }
            }
            .padding()
        }
        .refreshable {
            await localNews.fetchLocalNews()
        }
    }
}

struct LocationPickerView: View {
    @StateObject private var localNews = LocalNewsService.shared
    @State private var zipCode = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Enter ZIP Code") {
                    TextField("ZIP Code", text: $zipCode)
                        .keyboardType(.numberPad)

                    Button("Use ZIP Code") {
                        localNews.setLocation(zipCode: zipCode)
                        dismiss()
                    }
                    .disabled(zipCode.isEmpty)
                }

                Section("Or Select a City") {
                    ForEach(LocalNewsService.popularCities, id: \.self) { city in
                        Button(city) {
                            localNews.setLocation(city: city)
                            dismiss()
                        }
                    }
                }

                if localNews.currentLocation != nil {
                    Section {
                        Button("Clear Location", role: .destructive) {
                            localNews.clearLocation()
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Set Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LocalNewsView()
}
