//
//  ViewController.swift
//  PreloadURLCache
//
//  Created by fuyoufang@163.com on 04/27/2021.
//  Copyright (c) 2021 fuyoufang@163.com. All rights reserved.
//

import UIKit
import PreloadURLCache
import WebKit

class ViewController: UIViewController {
    
    lazy var preloadUrls = [
//        "https://v.qq.com/"
        "https://www.baidu.com/"
    ].compactMap {
        URL(string: $0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    @IBAction func preload(_ sender: Any) {
        URLProtocol.wk_registerScheme("http")
        URLProtocol.wk_registerScheme("https")
        
        PreloadURLCache.shard.delegate = self
        PreloadURLCache.shard.preloadByWebView(urls: preloadUrls) { (webView, javascriptBridge) in
            // javascriptBridge.zy_registerLuckySpinHandler(webView, [jsParameterKey_roomId : "roomId"])
        }
    }
    
    @IBAction func openWebView(_ sender: Any) {
        guard let url = preloadUrls.randomElement() else {
            return
        }
        debugPrint(url)
        let detailViewController = DetailViewController(url: url)
        show(detailViewController, sender: nil)
    }
}


extension ViewController: PreloadURLCacheDelegate {
    func preloadDidStartLoad(_ preloadURLCache: PreloadURLCache) {
        debugPrint("开始")
    }
    
    func preloadDidFinishLoad(_ preloadURLCache: PreloadURLCache, webview: WKWebView, remain: UInt) {
        debugPrint("finish")
    }
    
    func preloadDidFailLoad(_ preloadURLCache: PreloadURLCache) {
        debugPrint("fail")
    }
    
    func preloadDidAllDone(_ preloadURLCache: PreloadURLCache) {
        debugPrint("allDone")
    }
}
