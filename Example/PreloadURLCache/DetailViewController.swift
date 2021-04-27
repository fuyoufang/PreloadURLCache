//
//  DetailViewController.swift
//  PreloadURLCache_Example
//
//  Created by fuyoufang on 2021/4/27.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import WebKit
import SnapKit
import Then
import WebViewJavascriptBridge
import PreloadURLCache

class DetailViewController: UIViewController {
    let preloadURLCache: PreloadURLCache

    lazy var webView = WKWebView().then {
        $0.uiDelegate = self
        $0.navigationDelegate = self
    }
    var javascriptBridge: WKWebViewJavascriptBridge?

    let url: URL
    var startDate: Date?
    var endDate: Date?
    
    init(url: URL) {
        self.url = url
        preloadURLCache = PreloadURLCache { (mk) in
            mk.isUsingURLProtocol(true)
        }
        super.init(nibName: nil, bundle: nil)
        
        javascriptBridge = WKWebViewJavascriptBridge(for: webView)
//        javascriptBridge?.zy_registerLuckySpinHandler(webView, [jsParameterKey_roomId : "roomId"])

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
        webView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        webView.load(URLRequest(url: url))
    }
}

extension DetailViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        let startDate = Date()
        debugPrint("--------------------------")
        debugPrint("开始加载时间：\(startDate)")
        debugPrint("--------------------------")
        self.startDate = startDate
    }

    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let endDate = Date()
        debugPrint("--------------------------")
        debugPrint("结束加载时间：\(endDate)")
        debugPrint("--------------------------")
        self.endDate = endDate
        
        if let startDate = self.startDate {
            debugPrint("--------------------------")
            debugPrint("加载时间：\(endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970)")
            debugPrint("--------------------------")
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        debugPrint("didFail")
    }
    
    
}

extension DetailViewController: WKUIDelegate {
    
}
