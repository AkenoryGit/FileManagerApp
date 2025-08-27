//
//  ChangePasswordViewController.swift
//  FileManagerApp
//
//  Created by Дмитрий Дудник on 27.08.2025.
//

import UIKit

final class ChangePasswordViewController: UIViewController {
    
    private let newPasswordField = UITextField()
    private let confirmPasswordField = UITextField()
    private let saveButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Сменить пароль"
        view.backgroundColor = .systemBackground

        setupUI()
    }

    private func setupUI() {
        newPasswordField.placeholder = "Новый пароль"
        confirmPasswordField.placeholder = "Повторите пароль"
        
        newPasswordField.isSecureTextEntry = true
        confirmPasswordField.isSecureTextEntry = true

        newPasswordField.borderStyle = .roundedRect
        confirmPasswordField.borderStyle = .roundedRect

        saveButton.setTitle("Сохранить", for: .normal)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [newPasswordField, confirmPasswordField, saveButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    @objc private func saveTapped() {
        guard let newPass = newPasswordField.text, !newPass.isEmpty,
              let confirmPass = confirmPasswordField.text, !confirmPass.isEmpty else {
            showAlert(message: "Введите оба поля.")
            return
        }

        guard newPass == confirmPass else {
            showAlert(message: "Пароли не совпадают.")
            return
        }

        let keychainService: KeychainServiceProtocol = KeychainService()
        keychainService.update(newPass)

        showAlert(title: "Успешно", message: "Пароль сохранён.")
    }

    private func showAlert(title: String = "Ошибка", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}
