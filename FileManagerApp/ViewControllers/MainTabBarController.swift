//
//  MainTabBarController.swift
//  FileManagerApp
//
//  Created by Дмитрий Дудник on 27.08.2025.
//

import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
    }

    private func setupViewControllers() {
        let filesVC = DirectoryViewController()
        filesVC.tabBarItem = UITabBarItem(title: "Файлы", image: UIImage(systemName: "folder"), tag: 0)

        let settingsVC = SettingsViewController()
        settingsVC.tabBarItem = UITabBarItem(title: "Настройки", image: UIImage(systemName: "gearshape"), tag: 1)

        viewControllers = [
            UINavigationController(rootViewController: filesVC),
            UINavigationController(rootViewController: settingsVC)
        ]
    }
}
