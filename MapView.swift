//
//  MapView.swift
//  MeshiTero
//
//  Created by 岩﨑蝶々 on 2026/05/27.
//

import SwiftUI
import MapKit

struct FoodMapView: View {
    @Environment(AppState.self) private var appState
    
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: 35.681236,
                longitude: 139.767125
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.05,
                longitudeDelta: 0.05
            )
        )
    )
    
    var body: some View {
        Map(position: $position) {
            ForEach(appState.posts.compactMap { post -> (post: FoodPost, coordinate: CLLocationCoordinate2D)? in
                guard let latitude = post.latitude, let longitude = post.longitude else {
                    return nil
                }
                
                return (
                    post,
                    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                )
            }, id: \.post.id) { item in
                Annotation(
                    item.post.restaurantName.isEmpty ? item.post.foodName : item.post.restaurantName,
                    coordinate: item.coordinate
                ) {
                    VStack(spacing: 4) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.title)
                            .foregroundStyle(.red)
                        
                        Text(item.post.restaurantName.isEmpty ? item.post.foodName : item.post.restaurantName)
                            .font(.caption2)
                            .padding(4)
                            .background(.black.opacity(0.7))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}
