//
//  SettingsViewController.swift
//  FileManagerApp
//
//  Created by Дмитрий Дудник on 27.08.2025.
//

import UIKit

final class SettingsViewController: UITableViewController {
    
    private let switchKey = "SettingsSwitchState"
    private let sortKey = "sortAlphabetically"
    private let sizeKey = "showFileSize"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Настройки"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Сортировка"
        case 1: return "Показ размера фото"
        case 2: return "Пароль"
        default: return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)

        switch indexPath.section {
        case 0:
            cell.textLabel?.text = "По алфавиту"
            let sortSwitch = UISwitch()
            sortSwitch.isOn = UserDefaults.standard.bool(forKey: sortKey)
            sortSwitch.addTarget(self, action: #selector(sortSwitchChanged(_:)), for: .valueChanged)
            cell.accessoryView = sortSwitch

        case 1:
            cell.textLabel?.text = "Показывать размер"
            let sizeSwitch = UISwitch()
            sizeSwitch.isOn = UserDefaults.standard.bool(forKey: sizeKey)
            sizeSwitch.addTarget(self, action: #selector(sizeSwitchChanged(_:)), for: .valueChanged)
            cell.accessoryView = sizeSwitch

        case 2:
            cell.textLabel?.text = "Поменять пароль"
            cell.accessoryType = .disclosureIndicator

        default: break
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 2 {
            let vc = ChangePasswordViewController()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc private func switchChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: switchKey)
    }
    
    @objc private func sortSwitchChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: sortKey)
        NotificationCenter.default.post(name: .didChangeSortSetting, object: nil)
    }

    @objc private func sizeSwitchChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: sizeKey)
        NotificationCenter.default.post(name: .didChangeSizeSetting, object: nil)
    }
}

extension Notification.Name {
    static let didChangeSortSetting = Notification.Name("didChangeSortSetting")
    static let didChangeSizeSetting = Notification.Name("didChangeSizeSetting")
}
