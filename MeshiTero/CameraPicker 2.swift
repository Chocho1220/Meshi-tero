//
//  CameraPicker.swift
//  MeshiTero
//
//  Created by 岩﨑蝶々 on 2026/05/27.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers
import ImageIO
import AVFoundation

enum ImageSourceType {
    case camera
    case photoLibrary
}

struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    @Binding var image: UIImage?
    @Binding var videoURL: URL?
    @Binding var photoLatitude: Double?
    @Binding var photoLongitude: Double?
    
    let sourceType: ImageSourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        
        switch sourceType {
        case .camera:
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                picker.sourceType = .camera
                picker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
                picker.cameraCaptureMode = .photo
            } else {
                picker.sourceType = .photoLibrary
                picker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
            }
            
        case .photoLibrary:
            picker.sourceType = .photoLibrary
            picker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
        }
        
        // 動画の最大長さを15秒に制限する
        picker.videoMaximumDuration = 15.0
        
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let mediaType = info[.mediaType] as? String {
                if mediaType == UTType.movie.identifier {
                    if let movieURL = info[.mediaURL] as? URL {
                        parent.videoURL = movieURL
                        parent.image = nil // 画像をクリア
                        let coordinates = Self.extractVideoCoordinates(from: movieURL)
                        parent.photoLatitude = coordinates?.latitude
                        parent.photoLongitude = coordinates?.longitude
                    }
                } else {
                    if let selectedImage = info[.originalImage] as? UIImage {
                        parent.image = selectedImage
                        parent.videoURL = nil // 動画をクリア
                        
                        var lat: Double? = nil
                        var lon: Double? = nil
                        
                        // フォトライブラリから選択された場合
                        if let imageURL = info[.imageURL] as? URL,
                           let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
                           let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
                           let gpsInfo = imageProperties[kCGImagePropertyGPSDictionary] as? [CFString: Any] {
                            
                            if let latitude = gpsInfo[kCGImagePropertyGPSLatitude] as? Double,
                               let longitude = gpsInfo[kCGImagePropertyGPSLongitude] as? Double {
                                
                                if let latRef = gpsInfo[kCGImagePropertyGPSLatitudeRef] as? String, latRef == "S" {
                                    lat = -latitude
                                } else {
                                    lat = latitude
                                }
                                
                                if let lonRef = gpsInfo[kCGImagePropertyGPSLongitudeRef] as? String, lonRef == "W" {
                                    lon = -longitude
                                } else {
                                    lon = longitude
                                }
                            }
                        }
                        
                        // カメラで撮影した場合のメタデータ
                        if lat == nil, lon == nil,
                           let metadata = info[.mediaMetadata] as? [String: Any],
                           let gpsInfo = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
                            
                            if let latitude = gpsInfo[kCGImagePropertyGPSLatitude as String] as? Double,
                               let longitude = gpsInfo[kCGImagePropertyGPSLongitude as String] as? Double {
                                
                                if let latRef = gpsInfo[kCGImagePropertyGPSLatitudeRef as String] as? String, latRef == "S" {
                                    lat = -latitude
                                } else {
                                    lat = latitude
                                }
                                
                                if let lonRef = gpsInfo[kCGImagePropertyGPSLongitudeRef as String] as? String, lonRef == "W" {
                                    lon = -longitude
                                } else {
                                    lon = longitude
                                }
                            }
                        }
                        
                        parent.photoLatitude = lat
                        parent.photoLongitude = lon
                    }
                }
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        private static func extractVideoCoordinates(from url: URL) -> (latitude: Double, longitude: Double)? {
            let asset = AVAsset(url: url)

            for item in asset.metadata {
                if let coordinates = coordinates(from: item) {
                    return coordinates
                }
            }

            for format in asset.availableMetadataFormats {
                for item in asset.metadata(forFormat: format) {
                    if let coordinates = coordinates(from: item) {
                        return coordinates
                    }
                }
            }

            return nil
        }

        private static func coordinates(from item: AVMetadataItem) -> (latitude: Double, longitude: Double)? {
            if let stringValue = item.stringValue,
               let coordinates = parseISO6709(stringValue) {
                return coordinates
            }

            if let dataValue = item.dataValue,
               let stringValue = String(data: dataValue, encoding: .utf8),
               let coordinates = parseISO6709(stringValue) {
                return coordinates
            }

            return nil
        }

        private static func parseISO6709(_ rawValue: String) -> (latitude: Double, longitude: Double)? {
            let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let pattern = #"^([+-]\d+(?:\.\d+)?)([+-]\d+(?:\.\d+)?)([+-]\d+(?:\.\d+)?)?/?$"#

            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                return nil
            }

            let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
            guard let match = regex.firstMatch(in: trimmed, range: range),
                  let latitudeRange = Range(match.range(at: 1), in: trimmed),
                  let longitudeRange = Range(match.range(at: 2), in: trimmed),
                  let latitude = Double(String(trimmed[latitudeRange])),
                  let longitude = Double(String(trimmed[longitudeRange])) else {
                return nil
            }

            return (latitude, longitude)
        }
    }
}
