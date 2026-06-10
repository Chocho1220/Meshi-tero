//
//  PlacePickerView.swift
//  MeshiTero
//
//  Created by 岩﨑蝶々 on 2026/06/02.
//

import SwiftUI
import MapKit
import CoreLocation
import Observation

struct PlacePickerView: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var selectedPlaceName: String
    @Binding var selectedAddress: String
    @Binding var selectedLatitude: Double?
    @Binding var selectedLongitude: Double?
    @Binding var restaurantName: String
    @Binding var address: String
    
    // 写真のEXIF位置情報（オプション）
    var searchLatitude: Double? = nil
    var searchLongitude: Double? = nil
    
    @State private var locationManager = LocationManager()
    @State private var searchText = "飲食店" // 初期検索キーワードを広めにする
    @State private var places: [MKMapItem] = []
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // 検索元インジケータ
                HStack {
                    Image(systemName: searchLatitude != nil ? "photo.fill" : "location.fill")
                        .foregroundColor(searchLatitude != nil ? .pink : .blue)
                    Text(searchLatitude != nil ? "写真の撮影場所の近くから検索中" : "現在地周辺から検索中")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                HStack {
                    TextField("キーワード（例：ラーメン、カフェ、レストラン）", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("検索") {
                        searchPlaces()
                    }
                }
                .padding()
                
                List(places, id: \.self) { place in
                    Button {
                        selectPlace(place)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(place.name ?? "名前なし")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                
                                Text(place.placemark.title ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                if let category = place.pointOfInterestCategory {
                                    Text(categoryDisplayName(category))
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.white.opacity(0.12))
                                        .cornerRadius(4)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // 距離表示
                            let dist = distanceText(to: place)
                            if !dist.isEmpty {
                                Text(dist)
                                    .font(.caption)
                                    .foregroundStyle(.pink)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            }
            .background(Color.black.ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .preferredColorScheme(.dark)
            .navigationTitle("近くのお店を選ぶ")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if searchLatitude == nil {
                    locationManager.requestLocation()
                }
                
                // 初回読み込み時に即時検索
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    searchPlaces()
                }
            }
        }
    }
    
    func searchPlaces() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        if let lat = searchLatitude, let lon = searchLongitude {
            request.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
            )
        } else if let location = locationManager.location {
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)).span
            )
        }
        
        MKLocalSearch(request: request).start { response, error in
            if let response = response {
                places = response.mapItems
            }
        }
    }
    
    func selectPlace(_ place: MKMapItem) {
        let name = place.name ?? "お店"
        let placeAddress = place.placemark.title ?? ""
        let coordinate = place.placemark.coordinate
        
        selectedPlaceName = name
        selectedAddress = placeAddress
        selectedLatitude = coordinate.latitude
        selectedLongitude = coordinate.longitude
        
        restaurantName = name
        address = placeAddress
        
        dismiss()
    }
    
    func distanceText(to place: MKMapItem) -> String {
        let center: CLLocation
        if let lat = searchLatitude, let lon = searchLongitude {
            center = CLLocation(latitude: lat, longitude: lon)
        } else if let location = locationManager.location {
            center = location
        } else {
            return ""
        }
        
        let dest = CLLocation(latitude: place.placemark.coordinate.latitude, longitude: place.placemark.coordinate.longitude)
        let distance = center.distance(from: dest)
        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    func categoryDisplayName(_ category: MKPointOfInterestCategory) -> String {
        switch category {
        case .restaurant: return "レストラン"
        case .cafe: return "カフェ"
        case .bakery: return "パン屋"
        case .brewery: return "ブルワリー"
        case .winery: return "ワイナリー"
        case .foodMarket: return "フードマーケット"
        default: return "飲食店"
        }
    }
}

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    @ObservationIgnored
    private let manager = CLLocationManager()
    
    var location: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error.localizedDescription)
    }
}
