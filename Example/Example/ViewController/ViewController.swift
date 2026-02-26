//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2025/3/13.
//

import UIKit
import WWHUD
import WWEventSource
import WWSimpleAI_Ollama

// MARK: - ViewController
final class ViewController: UIViewController {
    
    @IBOutlet weak var modelTextField: UITextField!
    @IBOutlet weak var resultTextView: UITextView!
    
    private let baseURL = "http://192.168.1.20:11434"
    
    private var isDismiss = false
    private var responseString: String = ""
    
    @IBAction func configureModel(_ sender: UIButton) {
        Task { await initLoadModelIntoMemory() }
    }
    
    @IBAction func generateDemo(_ sender: UIButton) {
        Task { await generate(prompt: "\(sender.title(for: .normal)!)") }
    }
    
    @IBAction func talkDemo(_ sender: UIButton) {
        Task { await talk(content: "\(sender.title(for: .normal)!)") }
    }
        
    @IBAction func generateLiveDemo(_ sender: UIButton) {
        liveGenerate(prompt: "\(sender.title(for: .normal)!)")
    }
}

// MARK: - WWEventSourceDelegate
extension ViewController: WWEventSource.Delegate {
    
    func serverSentEventsConnectionStatus(_ eventSource: WWEventSource, result: Result<WWEventSource.ConnectionStatus, any Error>) {
        sseStatusAction(eventSource: eventSource, result: result)
    }
    
    func serverSentEventsRawData(_ eventSource: WWEventSource, result: Result<WWEventSource.RawInformation, any Error>) {
        
        switch result {
        case .failure(let error): displayText(error)
        case .success(let rawInformation): sseRawString(eventSource: eventSource, rawInformation: rawInformation)
        }
    }
    
    func serverSentEvents(_ eventSource: WWEventSource, eventValue: WWEventSource.EventValue) {
        print(eventValue)
    }
}

// MARK: - 小工具
private extension ViewController {
    
    /// 先將模型載入記憶體中
    func initLoadModelIntoMemory() async {
        
        displayHUD()
        configure()
        
        let result = await WWSimpleAI.Ollama.shared.loadIntoMemory(api: .generate)
        
        switch result {
        case .failure(let error): displayText(error.localizedDescription)
        case .success(let responseType): displayResponse(type: responseType)
        }
        
        WWHUD.shared.dismiss()
    }
    
    /// 生成文本回應
    /// - Parameters:
    ///   - prompt: 提問文字
    func generate(prompt: String) async {
        
        displayHUD()
        
        let result = await WWSimpleAI.Ollama.shared.generate(prompt: prompt)
        
        switch result {
        case .failure(let error): displayText(error.localizedDescription)
        case .success(let responseType): displayResponse(type: responseType)
        }
        
        WWHUD.shared.dismiss()
    }
    
    /// 聊天對談
    /// - Parameter content: 提問
    func talk(content: String) async {
        
        displayHUD()
        
        let result = await WWSimpleAI.Ollama.shared.talk(content: content)
        
        switch result {
        case .failure(let error): displayText(error.localizedDescription)
        case .success(let responseType): displayResponse(type: responseType)
        }
        
        WWHUD.shared.dismiss()
    }
    
    /// 及時回應 (SSE)
    /// - Parameters:
    ///   - prompt: 提問文字
    func liveGenerate(prompt: String) {
        
        displayHUD()
        
        let urlString = WWSimpleAI.Ollama.API.generate.url(for: baseURL)
        let json = """
        {
          "model": "\(WWSimpleAI.Ollama.shared.model)",
          "prompt": "\(prompt)",
          "stream": true
        }
        """
        
        _ = WWEventSource.shared.connect(httpMethod: .POST, delegate: self, urlString: urlString, httpBodyType: .string(json))
    }
}

// MARK: - 小工具
private extension ViewController {
    
    /// 設定模型
    func configure() {
        
        guard let model = modelTextField.text else { return }
        
        WWSimpleAI.Ollama.shared.baseURL = baseURL
        WWSimpleAI.Ollama.shared.model = model
    }
    
    /// 顯示AI回應
    /// - Parameter type: WWSimpleOllamaAI.ResponseType
    func displayResponse(type: WWSimpleAI.Ollama.ResponseType) {
        
        switch type {
        case .string(let string): displayText(string)
        case .data(let data): displayText(data)
        case .ndjson(let ndjson): displayText(ndjson)
        }
    }
    
    /// 顯示HUD
    func displayHUD() {
        resultTextView.text = ""
        WWHUD.shared.display()
    }
    
    /// 顯示文字
    /// - Parameter value: Any?
    func displayText(_ value: Any?) {
        resultTextView.text = "\(value ?? "")"
    }
}

// MARK: - SSE (Server Sent Events - 單方向串流)
private extension ViewController {
    
    /// SSE狀態處理
    /// - Parameters:
    ///   - eventSource: WWEventSource
    ///   - result: Result<WWEventSource.Constant.ConnectionStatus, any Error>
    func sseStatusAction(eventSource: WWEventSource, result: Result<WWEventSource.ConnectionStatus, any Error>) {
        
        switch result {
        case .failure(let error):
            
            WWHUD.shared.dismiss()
            displayText(error.localizedDescription)
            isDismiss = true
            responseString = ""
            
        case .success(let status):
            
            switch status {
            case .connecting: isDismiss = false
            case .open: if !isDismiss { WWHUD.shared.dismiss(); isDismiss = true }
            case .closed: responseString = ""; isDismiss = false
            }
        }
    }
    
    /// SSE資訊處理
    /// - Parameters:
    ///   - eventSource: WWEventSource
    ///   - rawInformation: WWEventSource.RawInformation
    func sseRawString(eventSource: WWEventSource, rawInformation: WWEventSource.RawInformation) {
        
        defer {
            resultTextView.text = responseString
            resultTextView._autoScrollToBottom()
        }
        
        if rawInformation.response.statusCode != 200 {
            responseString = rawInformation.data._string() ?? "\(rawInformation.response.statusCode)"; return
        }
        
        guard let jsonObject = rawInformation.data._jsonObject() as? [String: Any],
              let _response = jsonObject["response"] as? String
        else {
            return
        }
        
        responseString += _response
    }
}
