//
//  FileManagerService.swift
//  FileManagerApp
//
//  Created by Дмитрий Дудник on 26.08.2025.
//

import Foundation
import UIKit

final class FileManagerService {

    static let shared = FileManagerService()
    private let fileManager = FileManager.default

    private init() {}

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func contentsOfDirectory(at path: URL? = nil) -> [URL] {
        let targetURL = path ?? documentsDirectory
        do {
            return try fileManager.contentsOfDirectory(at: targetURL, includingPropertiesForKeys: nil)
        } catch {
            print("Ошибка при получении содержимого директории: \(error)")
            return []
        }
    }

    func createDirectory(named name: String, in path: URL? = nil) {
        let targetURL = (path ?? documentsDirectory).appendingPathComponent(name)
        do {
            try fileManager.createDirectory(at: targetURL, withIntermediateDirectories: true)
        } catch {
            print("Ошибка при создании директории: \(error)")
        }
    }

    func saveImage(_ image: UIImage, named fileName: String, in path: URL? = nil) {
        guard let data = image.pngData() else { return }
        let targetURL = (path ?? documentsDirectory).appendingPathComponent(fileName)
        do {
            try data.write(to: targetURL)
        } catch {
            print("Ошибка при сохранении изображения: \(error)")
        }
    }
}
