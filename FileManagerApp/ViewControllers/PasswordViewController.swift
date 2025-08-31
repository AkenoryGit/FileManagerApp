//
//  PasswordViewController.swift
//  FileManagerApp
//
//  Created by Дмитрий Дудник on 27.08.2025.
//

import UIKit

final class PasswordViewController: UIViewController {

    private let keychainService: KeychainServiceProtocol = KeychainService()

    private var isCreatingPassword = false
    private var firstPasswordEntry: String?

    private let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Введите пароль"
        tf.isSecureTextEntry = true
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let actionButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Создать пароль", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        configureInitialState()
    }

    private func setupUI() {
        view.addSubview(passwordTextField)
        view.addSubview(actionButton)

        NSLayoutConstraint.activate([
            passwordTextField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            passwordTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passwordTextField.widthAnchor.constraint(equalToConstant: 200),

            actionButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 16),
            actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        actionButton.addTarget(self, action: #selector(handleAction), for: .touchUpInside)
    }

    private func configureInitialState() {
        if keychainService.load() == nil {
            isCreatingPassword = true
            actionButton.setTitle("Создать пароль", for: .normal)
        } else {
            isCreatingPassword = false
            actionButton.setTitle("Ввести пароль", for: .normal)
        }
    }

    @objc private func handleAction() {
        guard let input = passwordTextField.text, input.count >= 4 else {
            showError("Пароль должен быть не менее 4 символов")
            return
        }

        if isCreatingPassword {
            if firstPasswordEntry == nil {
                firstPasswordEntry = input
                passwordTextField.text = ""
                actionButton.setTitle("Повторите пароль", for: .normal)
            } else if firstPasswordEntry == input {
                keychainService.save(input)
                showMainTabBar()
            } else {
                showError("Пароли не совпадают")
                resetToInitialCreateState()
            }
        } else {
            if keychainService.load() == input {
                showMainTabBar()
            } else {
                showError("Неверный пароль")
            }
        }
    }

    private func resetToInitialCreateState() {
        firstPasswordEntry = nil
        passwordTextField.text = ""
        actionButton.setTitle("Создать пароль", for: .normal)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }

    private func showMainTabBar() {
        let tabBarVC = MainTabBarController()
        tabBarVC.modalPresentationStyle = .fullScreen
        present(tabBarVC, animated: true)
    }
}
