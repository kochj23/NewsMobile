//
//  WeatherWidget.swift
//  NewsMobile
//
//  Compact weather display widget
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct WeatherWidget: View {
    @StateObject private var weatherService = WeatherService.shared

    var body: some View {
        Group {
            if let weather = weatherService.currentWeather {
                HStack(spacing: 12) {
                    Image(systemName: weather.icon)
                        .font(.title)
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(weather.temperature))°")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(weather.condition)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Feels like \(Int(weather.feelsLike))°")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("\(weather.humidity)% humidity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            } else if weatherService.isLoading {
                HStack {
                    ProgressView()
                    Text("Loading weather...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            } else {
                Button {
                    weatherService.requestLocation()
                } label: {
                    HStack {
                        Image(systemName: "location.circle")
                        Text("Enable location for weather")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
}

#Preview {
    WeatherWidget()
        .padding()
}
