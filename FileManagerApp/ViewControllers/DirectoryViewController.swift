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
    private var isSelectionMode = false
    private var selectedItems = Set<IndexPath>()
    private var deleteButton: UIButton?

    init(path: URL? = nil) {
        self.path = path ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = path.lastPathComponent == "Documents" ? "Файлы и папки" : path.lastPathComponent
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        loadDirectoryContents()

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addImageTapped)),
            UIBarButtonItem(image: UIImage(systemName: "folder.badge.plus"), style: .plain, target: self, action: #selector(addFolderTapped)),
            UIBarButtonItem(image: UIImage(systemName: "checkmark.circle"), style: .plain, target: self,action: #selector(toggleSelectionMode)),
        
        ]
        
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = items[indexPath.row]

        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: item.path, isDirectory: &isDirectory)
        
        cell.selectionStyle = .none

        if isSelectionMode {
            let isSelected = selectedItems.contains(indexPath)
            cell.accessoryView = UIImageView(image: UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle"))
            cell.accessoryView?.tintColor = .systemBlue
        } else {
            cell.accessoryView = nil
            var isDirectory: ObjCBool = false
            FileManager.default.fileExists(atPath: item.path, isDirectory: &isDirectory)
            cell.accessoryType = isDirectory.boolValue ? .disclosureIndicator : .none
        }

        cell.textLabel?.text = item.lastPathComponent
        cell.imageView?.image = UIImage(systemName: isDirectory.boolValue ? "folder" : "photo")
        cell.imageView?.tintColor = .systemBlue
        cell.imageView?.contentMode = .scaleAspectFit

        cell.setNeedsLayout()

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSelectionMode {
            selectedItems.insert(indexPath)
            tableView.reloadRows(at: [indexPath], with: .none)
        } else {
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
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isSelectionMode {
            selectedItems.remove(indexPath)
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    private func loadDirectoryContents() {
        let unsortedItems = FileManagerService.shared.contentsOfDirectory(at: path)

        items = unsortedItems.sorted { a, b in
            var isDirA: ObjCBool = false
            var isDirB: ObjCBool = false

            FileManager.default.fileExists(atPath: a.path, isDirectory: &isDirA)
            FileManager.default.fileExists(atPath: b.path, isDirectory: &isDirB)

            if isDirA.boolValue != isDirB.boolValue {
                return isDirA.boolValue
            }

            return a.lastPathComponent.lowercased() < b.lastPathComponent.lowercased()
        }

        tableView.reloadData()
    }
    
    private func showDeleteButton() {
        let button = UIButton(type: .system)
        button.setTitle("Удалить", for: .normal)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(confirmDeletion), for: .touchUpInside)

        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])

        deleteButton = button
    }

    private func hideDeleteButton() {
        deleteButton?.removeFromSuperview()
        deleteButton = nil
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
    
    @objc private func toggleSelectionMode() {
        isSelectionMode.toggle()
        selectedItems.removeAll()
        tableView.allowsMultipleSelection = isSelectionMode
        navigationItem.leftBarButtonItem?.title = isSelectionMode ? "Отмена" : "Выбрать"

        if isSelectionMode {
            showDeleteButton()
        } else {
            hideDeleteButton()
        }
    }
    
    @objc private func confirmDeletion() {
        let alert = UIAlertController(title: "Удаление", message: "Удалить выбранные элементы?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.deleteSelectedItems()
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    private func deleteSelectedItems() {
        let urlsToDelete = selectedItems.map { items[$0.row] }
        for url in urlsToDelete {
            try? FileManager.default.removeItem(at: url)
        }

        toggleSelectionMode()
        loadDirectoryContents()
    }
}

extension DirectoryViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else { return }

        let fileName = UUID().uuidString + ".png"
        FileManagerService.shared.saveImage(image, named: fileName, in: path)
        loadDirectoryContents()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
