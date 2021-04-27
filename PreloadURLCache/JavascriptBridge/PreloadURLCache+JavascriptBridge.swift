//
//  PreloadURLCache+JavascriptBridge.swift
//  PreloadURLCache
//
//  Created by fuyoufang on 2021/4/27.
//

import Foundation
import WebViewJavascriptBridge


// 嵌套结构体
private struct AssociatedKeys {
    static var javascriptBridgeKey = "__JavascriptBridge"
}


extension PreloadURLCache {
    
    var javascriptBridge: WKWebViewJavascriptBridge? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.javascriptBridgeKey) as? WKWebViewJavascriptBridge
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.javascriptBridgeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension PreloadURLCache {
//    var javascriptBridge: WKWebViewJavascriptBridge?
//    self.javascriptBridge = WKWebViewJavascriptBridge(for: webView)

    
    @discardableResult
    public func preloadByWebView(urls: [URL], config: ((WKWebView, WKWebViewJavascriptBridge) -> Void)? = nil) -> Self {
        
        let webView = getWebView()
        
        let javascriptBridge: WKWebViewJavascriptBridge
        if let bridge = self.javascriptBridge {
            javascriptBridge = bridge
        } else {
            javascriptBridge = WKWebViewJavascriptBridge(for: webView)
            self.javascriptBridge = javascriptBridge
        }
        config?(webView, javascriptBridge)
        
        return preloadByWebView(urls: urls)
    }
}
