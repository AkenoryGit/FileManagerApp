//
//  DirectoryViewController.swift
//  FileManagerApp
//
//  Created by Дмитрий Дудник on 26.08.2025.
//

import UIKit

final class DirectoryViewController: UITableViewController {

    private var path: URL
    private var items: [URL] = []

    init(path: URL? = nil) {
        self.path = path ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadFiles), name: .didChangeSortSetting, object: nil)
           NotificationCenter.default.addObserver(self, selector: #selector(reloadFiles), name: .didChangeSizeSetting, object: nil)
        
        title = path.lastPathComponent == "Documents" ? "Файлы и папки" : path.lastPathComponent
        loadDirectoryContents()

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addImageTapped)),
            UIBarButtonItem(image: UIImage(systemName: "folder.badge.plus"), style: .plain, target: self, action: #selector(addFolderTapped))
        ]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        let item = items[indexPath.row]

        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: item.path, isDirectory: &isDirectory)

        cell.selectionStyle = .none
        cell.accessoryType = isDirectory.boolValue ? .disclosureIndicator : .none
        cell.accessoryView = nil

        cell.textLabel?.text = item.lastPathComponent

        if isDirectory.boolValue {
            cell.imageView?.image = UIImage(systemName: "folder")
        } else if item.pathExtension.lowercased() == "png",
                  let data = try? Data(contentsOf: item),
                  let image = UIImage(data: data) {
            cell.imageView?.image = image
        } else {
            cell.imageView?.image = UIImage(systemName: "doc")
        }

        if let originalImage = cell.imageView?.image {
            let targetSize = CGSize(width: 40, height: 40)
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            let resizedImage = renderer.image { _ in
                originalImage.draw(in: CGRect(origin: .zero, size: targetSize))
            }

            cell.imageView?.image = resizedImage
            cell.imageView?.contentMode = .scaleAspectFill
            cell.imageView?.clipsToBounds = true
            cell.imageView?.layer.cornerRadius = 4
            cell.imageView?.layer.masksToBounds = true
        }

        if !isDirectory.boolValue {
            let showSize = UserDefaults.standard.bool(forKey: "showFileSize")
            if showSize,
               let attributes = try? FileManager.default.attributesOfItem(atPath: item.path),
               let fileSize = attributes[.size] as? Int,
               let creationDate = attributes[.creationDate] as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short

                let sizeKB = Double(fileSize) / 1024.0
                cell.detailTextLabel?.text = String(format: "%.1f KB • %@", sizeKB, formatter.string(from: creationDate))
            } else {
                cell.detailTextLabel?.text = nil
            }
        } else {
            cell.detailTextLabel?.text = nil
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let selectedURL = items[indexPath.row]
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: selectedURL.path, isDirectory: &isDirectory)

        if isDirectory.boolValue {
            let subdirectoryVC = DirectoryViewController(path: selectedURL)
            navigationController?.pushViewController(subdirectoryVC, animated: true)
        } else if selectedURL.pathExtension.lowercased() == "png" {
            let imageVC = ImageViewController(imagePath: selectedURL)
            navigationController?.pushViewController(imageVC, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] _, _, completionHandler in
            guard let self else {
                completionHandler(false)
                return
            }

            let fileURL = items[indexPath.row]

            let alert = UIAlertController(title: "Удаление", message: "Удалить «\(fileURL.lastPathComponent)»?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { _ in
                try? FileManager.default.removeItem(at: fileURL)
                self.loadDirectoryContents()
                completionHandler(true)
            })
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel) { _ in
                completionHandler(false)
            })

            self.present(alert, animated: true)
        }

        deleteAction.backgroundColor = .systemRed
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    private func loadDirectoryContents() {
        let allItems = FileManagerService.shared.contentsOfDirectory(at: path)

        let folders = allItems.filter { url in
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            return isDir.boolValue
        }

        let files = allItems.filter { url in
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            return !isDir.boolValue
        }

        let sortAlphabetically = UserDefaults.standard.bool(forKey: "sortAlphabetically")

        if sortAlphabetically {
            items = folders.sorted { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() } +
                    files.sorted { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() }
        } else {
            items = folders.sorted { $0.lastPathComponent.lowercased() > $1.lastPathComponent.lowercased() } +
                    files.sorted { $0.lastPathComponent.lowercased() > $1.lastPathComponent.lowercased() }
        }

        tableView.reloadData()
    }

    @objc private func addFolderTapped() {
        let alert = UIAlertController(title: "Создать папку", message: "Введите имя", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Имя папки" }

        let createAction = UIAlertAction(title: "Создать", style: .default) { [weak self] _ in
            guard let self, let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            FileManagerService.shared.createDirectory(named: name, in: path)
            loadDirectoryContents()
        }

        alert.addAction(createAction)
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func addImageTapped() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc private func reloadFiles() {
        loadDirectoryContents()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension DirectoryViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else { return }

        let alert = UIAlertController(title: "Сохранить изображение", message: "Введите имя файла", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Имя файла"
        }

        let saveAction = UIAlertAction(title: "Сохранить", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let fileNameInput = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            let fileName = (fileNameInput?.isEmpty == false ? fileNameInput! : UUID().uuidString) + ".png"

            FileManagerService.shared.saveImage(image, named: fileName, in: self.path)
            self.loadDirectoryContents()
        }

        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))

        present(alert, animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
