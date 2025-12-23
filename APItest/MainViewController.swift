//
//  MainViewController.swift
//  APItest
//
//  Created by imac-3888 on 2025/12/19.
//

import UIKit
import CoreLocation

class MainViewController: UIViewController {

    // MARK: - IBOutlet
    @IBOutlet weak var btntesst: UIButton!
    @IBOutlet weak var lbhttp: UILabel!
    @IBOutlet weak var btnchange: UIButton!
    @IBOutlet weak var btnadd: UIButton!
    @IBOutlet weak var nvView: UIView!
    
    // MARK: - Property
    private let locationManager = CLLocationManager()
    private var eventNote: String?
    let APImanger = APIService.shared
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        nvView.backgroundColor = UIColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0)
        // 設置導航欄
        setupNavigationBar()
        
        // 顯示當前網址
        updateURLDisplay()
        
        // 設定定位服務
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - UI Settings
    private func setupNavigationBar() {
        // 設置導航欄背景顏色為深紅色
        navigationController?.navigationBar.backgroundColor = UIColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0)
        navigationController?.navigationBar.barTintColor = UIColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0)
        navigationController?.navigationBar.tintColor = UIColor.white
        
        // 設置標題顏色為白色
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        // 左邊按鈕 - QR View
        let leftButton = UIBarButtonItem(title: "QR", style: .plain, target: self, action: #selector(leftButtonPressed))
        leftButton.tintColor = UIColor.white
        navigationItem.leftBarButtonItem = leftButton
        
        // 右邊按鈕 - Scan View
        let rightButton = UIBarButtonItem(title: "掃描", style: .plain, target: self, action: #selector(rightButtonPressed))
        rightButton.tintColor = UIColor.white
        navigationItem.rightBarButtonItem = rightButton
        
        // 設置標題
        navigationItem.title = "API測試"
    }
    
    // MARK: - IBAction
    @IBAction func btnChangePressed(_ sender: UIButton) {
        showURLChangeAlert()
    }
    
    @IBAction func pingtest(_ sender: Any) {
        // 顯示載入指示器
        let loadingAlert = UIAlertController(title: "連線測試", message: "正在測試API連線...", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        APIService.shared.testConnection { [weak self] result in
            DispatchQueue.main.async {
                // 關閉載入指示器
                loadingAlert.dismiss(animated: true) {
                    self?.showPingTestResult(result)
                }
            }
        }
    }
    
    @IBAction func eventadd(_ sender: Any) {
        promptForEventNote()
    }
    
    // MARK: - Function
    @objc private func leftButtonPressed() {
        let qrViewController = QRViewController()
        navigationController?.pushViewController(qrViewController, animated: true)
    }
    
    @objc private func rightButtonPressed() {
        let scanViewController = scanViewController()
        navigationController?.pushViewController(scanViewController, animated: true)
    }
    
    private func updateURLDisplay() {
        lbhttp.text = APIService.shared.getCurrentBaseURL()
    }
    
    private func showURLChangeAlert() {
        let alert = UIAlertController(title: "修改網址", message: "請輸入新的host地址", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "例如: localhost"
            textField.text = APIService.shared.getCurrentHost()
        }
        
        let confirmAction = UIAlertAction(title: "確定", style: .default) { [weak self] _ in
            guard let textField = alert.textFields?.first,
                  let newHost = textField.text,
                  !newHost.isEmpty else {
                return
            }
            
            APIService.shared.updateBaseURL(host: newHost)
            self?.updateURLDisplay()
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func showPingTestResult(_ result: Result<SimpleResponse, Error>) {
        let alert: UIAlertController
        
        switch result {
        case .success(let response):
            alert = UIAlertController(title: "API連線測試成功", message: """
            狀態: \(response.status)
            訊息: \(response.message)
            時間戳記: \(response.timestamp ?? "無")
            Token: \(response.token != nil ? "已獲得" : "無")
            """, preferredStyle: .alert)
            
        case .failure(let error):
            let errorMessage: String
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    errorMessage = "無網路連接，請檢查網路設定"
                case .timedOut:
                    errorMessage = "連線逾時，請檢查網路或服務器狀態"
                case .cannotConnectToHost:
                    errorMessage = "無法連接到服務器，請確認網址是否正確"
                case .badURL:
                    errorMessage = "無效的網址格式"
                default:
                    errorMessage = "網路錯誤: \(urlError.localizedDescription)"
                }
            } else {
                errorMessage = "API錯誤: \(error.localizedDescription)"
            }
            
            alert = UIAlertController(title: "API連線測試失敗", message: errorMessage, preferredStyle: .alert)
        }
        
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }
    
    private func registerNewEvent(note: String, location: CLLocation) {
        // 顯示載入指示器
        let loadingAlert = UIAlertController(title: "新增事件中", message: "正在註冊事件...", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        // 準備請求
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let request = EventRegistrationRequest(
            timestamp: timestamp,
            latitude: "\(location.coordinate.latitude)", // 使用獲取到的緯度
            longitude: "\(location.coordinate.longitude)", // 使用獲取到的經度
            altitude: "\(location.altitude)", // 使用獲取到的海拔
            note: note
        )
        
        // 呼叫API
        APImanger.registerEvent(request) { [weak self] result in
            DispatchQueue.main.async {
                // 關閉載入指示器
                loadingAlert.dismiss(animated: true) {
                    self?.showEventRegistrationResult(result)
                }
            }
        }
    }
    
    private func showEventRegistrationResult(_ result: Result<SimpleResponse, Error>) {
        let alert: UIAlertController
        
        switch result {
        case .success(let response):
            alert = UIAlertController(title: "事件註冊成功", message: """
            狀態: \(response.status)
            訊息: \(response.message)
            時間戳記: \(response.timestamp ?? "無")
            """, preferredStyle: .alert)
            
        case .failure(let error):
            let errorMessage: String
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    errorMessage = "無網路連接，請檢查網路設定"
                case .timedOut:
                    errorMessage = "連線逾時，請檢查網路或服務器狀態"
                case .cannotConnectToHost:
                    errorMessage = "無法連接到服務器，請確認網址是否正確"
                default:
                    errorMessage = "網路錯誤: \(urlError.localizedDescription)"
                }
            } else {
                errorMessage = "API錯誤: \(error.localizedDescription)"
            }
            
            alert = UIAlertController(title: "事件註冊失敗", message: errorMessage, preferredStyle: .alert)
        }
        
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }
    
    private func promptForEventNote() {
        let alert = UIAlertController(title: "新增事件", message: "請輸入事件筆記", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "事件筆記"
        }
        
        let confirmAction = UIAlertAction(title: "確定", style: .default) { [weak self] _ in
            guard let self = self,
                  let textField = alert.textFields?.first,
                  let note = textField.text,
                  !note.isEmpty else {
                // Optionally, show an alert that the note cannot be empty
                return
            }
            
            // 儲存筆記並開始定位
            self.eventNote = note
            self.locationManager.startUpdatingLocation()
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
}

// MARK: - Extensions
extension MainViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 停止定位以節省電量
        manager.stopUpdatingLocation()
        
        // 檢查是否有儲存的筆記
        guard let note = self.eventNote else { return }
        
        // 使用獲取到的位置和筆記來註冊事件
        registerNewEvent(note: note, location: location)
        
        // 清除筆記
        self.eventNote = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 停止定位
        manager.stopUpdatingLocation()
        
        // 顯示錯誤訊息
        let alert = UIAlertController(title: "定位失敗", message: "無法獲取您的位置，請檢查定位服務設定。錯誤：\(error.localizedDescription)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .denied, .restricted:
            // 提示用戶開啟定位服務
            let alert = UIAlertController(title: "定位服務已關閉", message: "請至「設定」>「隱私權」>「定位服務」開啟，以允許應用程式獲取您的位置。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "確定", style: .default))
            present(alert, animated: true)
        case .notDetermined:
            // 請求授權
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }
}
