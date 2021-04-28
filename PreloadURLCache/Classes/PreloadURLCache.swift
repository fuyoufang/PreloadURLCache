//
//  WKWebViewCache.swift
//  WKWebViewCache
//
//  Created by fuyoufang on 2021/3/31.
//

import Foundation
import WebKit
import Then

public protocol PreloadURLCacheDelegate: AnyObject {
    func preloadDidStartLoad(_ preloadURLCache: PreloadURLCache)
    func preloadDidFinishLoad(_ preloadURLCache: PreloadURLCache, webview: WKWebView, remain: UInt)
    func preloadDidFailLoad(_ preloadURLCache: PreloadURLCache)
    func preloadDidAllDone(_ preloadURLCache: PreloadURLCache)
}

public extension PreloadURLCacheDelegate {
    func preloadDidStartLoad(_ preloadURLCache: PreloadURLCache) {}
    func preloadDidFinishLoad(_ preloadURLCache: PreloadURLCache, webview: WKWebView, remain: UInt) {}
    func preloadDidFailLoad(_ preloadURLCache: PreloadURLCache) {}
    func preloadDidAllDone(_ preloadURLCache: PreloadURLCache) {}
}


/// 预加载缓存
public class PreloadURLCache: URLCache {
    let mk: PreloadURLCacheMk
    
    public weak var delegate: PreloadURLCacheDelegate?
    
    // 预加载的webview的url列表
    var preloadWebUrls = [URL]() // 使用 URL 加载
    var preloadWebHtmls = [String]() // 使用 html 加载
    var isUseHtmlPreload: Bool = false
    // 用于预加载的webview
    var __webView: WKWebView?
    
    
    // MARK: Initialize
    
    /// 初始化并开启缓存
    /// - Parameter config: 缓存配置
    public init(config: (PreloadURLCacheMk) -> Void) {
        let mk = PreloadURLCacheMk()
        mk.isDownloadMode(true)
        config(mk)
        self.mk = mk
        super.init(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
        configWithMk()
        
    }
    
    // MARK: - Public
    
    public func update(_ config: (PreloadURLCacheMk) -> Void) {
        config(mk)
        configWithMk()
    }
    
    // MARK: PreLoad by Webview

    /// 使用 WebView 进行预加载缓存
    /// - Parameter urls: 预加载链接
    /// - Returns: 预加载类，方便链式调用
    @discardableResult
    public func preloadByWebView(urls: [URL]) -> Self {
        guard urls.count > 0 else {
            return self
        }
    
        preloadWebUrls.append(contentsOf: urls)
        urls.forEach { (url) in
            if let host = url.host {
                mk.config.whiteListsHost[host] = true
            }
        }
        
        requestWebWithFirstPreUrl()
        return self
    }
    
    
    /// 使用以html内容在WebView里读取进行内容预加载缓存
    /// - Parameter htmls: htmls 内容
    /// - Returns: 预加载类，方便链式调用
    public func preloadByWebView(htmls: [String]) -> Self {
        guard htmls.count > 0 else {
            return self
        }
        preloadWebHtmls.append(contentsOf: htmls)
        isUseHtmlPreload = true
        requestWebWithFirstPreHtml()
        return self
    }
    
    // 使用url
    //    - (STMURLCache *)preLoadByRequestWithUrls:(NSArray *)urls {
    //        NSUInteger i = 1;
    //        for (NSString *urlString in urls) {
    //            NSMutableURLRequest *re = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    //            re.HTTPMethod = @"GET";
    //            NSURLSession *session = [NSURLSession sharedSession];
    //            NSURLSessionDataTask *task = [session dataTaskWithRequest:re completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    //            }];
    //            [task resume];
    //            i++;
    //        }
    //
    //        return self;
    //    }
    
    /// 关闭缓存
    func stop() {
        if mk.config.isUsingURLProtocol {
            URLProtocol.unregisterClass(PreloadURLProtocol.self)
        } else {
            URLCache.shared = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
        }
        mk.config.checkCapacity()
    }

    
    // MARK: Private

    func getWebView() -> WKWebView {
        if let webView = self.__webView {
            return webView
        } else {
            let webView = WKWebView().then {
                $0.uiDelegate = self
                $0.navigationDelegate = self
            }
            self.__webView = webView

            return webView
        }
    }
    
    func configWithMk() {
        mk.config.isSavedOnDisk = true
        
        if mk.config.isUsingURLProtocol {
            _ = PreloadURLCacheConfig.shared.then {
                $0.cacheTime = mk.config.cacheTime
                $0.diskCapacity = mk.config.diskCapacity
                $0.diskPath = mk.config.diskPath
                $0.cacheFolder = mk.config.cacheFolder
                $0.subDirectory = mk.config.subDirectory
                $0.whiteUserAgent = mk.config.whiteUserAgent
                $0.whiteListsHost = mk.config.whiteListsHost
            }
            URLProtocol.registerClass(PreloadURLProtocol.self)
        } else {
            URLCache.shared = self
        }
    }
    
    // MARK: - WebView Delegate Private Method
    func requestWebDone() {
        guard preloadWebUrls.count > 0 else {
            preloadAllDone()
            return
            
        }
        preloadWebUrls.removeFirst()
        if isUseHtmlPreload {
            requestWebWithFirstPreHtml()
        } else {
            requestWebWithFirstPreUrl()
        }
        if preloadWebUrls.count == 0 {
            preloadAllDone()
        }
    }

    func preloadAllDone() {
        self.__webView = nil
        stop()
        self.delegate?.preloadDidAllDone(self)   
    }

    func requestWebWithFirstPreUrl() {
        guard let url = preloadWebUrls.first else {
            return
        }
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
        getWebView().load(request)
    }
    
    func requestWebWithFirstPreHtml() {
        guard let html = preloadWebHtmls.first else {
            return
        }
        getWebView().loadHTMLString(html, baseURL: nil)
    }


    // MARK: - NSURLCache Method
    public override func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        
        let config = mk.config
        
        //替换请求的处理
        if (config.replaceUrl?.count ?? 0) > 0,
           let replaceData = config.replaceData {
            guard let url = request.url else {
                return nil
            }
            let response = URLResponse(url: url,
                                       mimeType: "text/html",
                                       expectedContentLength: replaceData.count,
                                       textEncodingName: "utf-8")
            return CachedURLResponse(response: response, data: replaceData)
        }
        
        // 对于模式的过滤
        guard config.isDownloadMode else {
            return nil
        }
        
        // 对于域名白名单的过滤
        guard let host = request.url?.host,
           let _ = config.whiteListsHost[host] else {
            return nil
        }
        
        // 只允许GET方法通过
        guard request.httpMethod == "GET" else {
            return nil
        }
        
        // User-Agent来过滤
        if let whiteUserAgent = config.whiteUserAgent, whiteUserAgent.count > 0 {
            if let uAgent = request.allHTTPHeaderFields?["User-Agent"] {
                guard uAgent.hasSuffix(whiteUserAgent) else {
                    return nil
                }
            }
        }
        
        // 开始缓存
        guard let cachedResponse = config.localCacheRespone(request: request) else {
            return nil
        }
        
        storeCachedResponse(cachedResponse, for: request)
        return cachedResponse
    }

    // MARK: - Cache Capacity

    public override func removeCachedResponse(for request: URLRequest) {
        super.removeCachedResponse(for: request)
        mk.config.removeCacheFile(request: request)
    }
    
    deinit {
        URLCache.shared = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
    }

}

extension PreloadURLCache: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        delegate?.preloadDidStartLoad(self)
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        requestWebDone()
        self.delegate?.preloadDidFinishLoad(self, webview: webView, remain: UInt(preloadWebUrls.count))   
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        delegate?.preloadDidFailLoad(self)
        
        guard let e = error as? URLError, e.code == URLError.cancelled else {
            requestWebDone()
            return
        }
        
        if preloadWebUrls.count > 0 {
            preloadWebUrls.removeFirst()
            if preloadWebUrls.count == 0 {
                preloadAllDone()
            }
        } else {
            preloadAllDone()
        }
    }
}

extension PreloadURLCache: WKUIDelegate {

}
