//
//  WeatherService.swift
//  NewsMobile
//
//  Weather data service
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import CoreLocation

@MainActor
class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = WeatherService()

    @Published var currentWeather: WeatherData?
    @Published var isLoading = false

    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.first else { return }
            self.currentLocation = location
            await self.fetchWeather(for: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }

    private func fetchWeather(for location: CLLocation) async {
        isLoading = true

        // Use a free weather API
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code"

        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let current = json["current"] as? [String: Any] {

                let temp = current["temperature_2m"] as? Double ?? 0
                let humidity = current["relative_humidity_2m"] as? Int ?? 0
                let feelsLike = current["apparent_temperature"] as? Double ?? temp
                let weatherCode = current["weather_code"] as? Int ?? 0

                let (condition, icon) = weatherDescription(for: weatherCode)

                currentWeather = WeatherData(
                    temperature: temp,
                    condition: condition,
                    icon: icon,
                    location: "Current Location",
                    humidity: humidity,
                    feelsLike: feelsLike
                )
            }
        } catch {
            print("Weather fetch error: \(error)")
        }

        isLoading = false
    }

    private func weatherDescription(for code: Int) -> (String, String) {
        switch code {
        case 0: return ("Clear", "sun.max.fill")
        case 1, 2, 3: return ("Partly Cloudy", "cloud.sun.fill")
        case 45, 48: return ("Foggy", "cloud.fog.fill")
        case 51, 53, 55: return ("Drizzle", "cloud.drizzle.fill")
        case 61, 63, 65: return ("Rain", "cloud.rain.fill")
        case 66, 67: return ("Freezing Rain", "cloud.sleet.fill")
        case 71, 73, 75: return ("Snow", "cloud.snow.fill")
        case 77: return ("Snow Grains", "cloud.snow.fill")
        case 80, 81, 82: return ("Rain Showers", "cloud.heavyrain.fill")
        case 85, 86: return ("Snow Showers", "cloud.snow.fill")
        case 95: return ("Thunderstorm", "cloud.bolt.fill")
        case 96, 99: return ("Thunderstorm with Hail", "cloud.bolt.rain.fill")
        default: return ("Unknown", "questionmark.circle")
        }
    }
}
