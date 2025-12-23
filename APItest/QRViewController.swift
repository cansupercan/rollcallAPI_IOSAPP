//
//  QRViewController.swift
//  APItest
//
//  Created by imac-3888 on 2025/12/19.
//

import UIKit

class QRViewController: UIViewController {

    // MARK: - IBOutlet
    @IBOutlet weak var tbvevent: UITableView!
    @IBOutlet weak var nvView: UIView!
    
    // MARK: - Property
    private var events: [EventInfo] = []
    let APImanger = APIService.shared
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "ＱＲ頁面"
        nvView.backgroundColor = UIColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0)
        
        // 設定 TableView
        tbvevent.delegate = self
        tbvevent.dataSource = self
        tbvevent.register(UITableViewCell.self, forCellReuseIdentifier: "eventCell")
        
        // 獲取事件數據
        fetchEvents()
    }

    // MARK: - UI Settings

    // MARK: - IBAction

    // MARK: - Function
    private func fetchEvents() {
        APImanger.getAllEvents { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                self.events = response.data ?? []
                DispatchQueue.main.async {
                    self.tbvevent.reloadData()
                }
            case .failure(let error):
                // 在主線程上顯示錯誤提示
                DispatchQueue.main.async {
                    self.showAlert(title: "獲取事件失敗", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Extensions
extension QRViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath)
        let event = events[indexPath.row]
        
        // 簡單顯示事件ID和筆記
        var content = cell.defaultContentConfiguration()
        content.text = "Note: \(event.note)"
        content.secondaryText = "ID: \(event.id ?? 0) - \(event.timestamp)"
        cell.contentConfiguration = content
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 可以添加點擊事件的處理，例如導航到事件詳情頁面
        tableView.deselectRow(at: indexPath, animated: true)
        let event = events[indexPath.row]
        showAlert(title: "事件詳情", message: "ID: \(event.id ?? 0)\nNote: \(event.note)\nTimestamp: \(event.timestamp)")
    }
}

