//
//  PreloadURLCacheMk.swift
//  WKWebViewCache
//
//  Created by fuyoufang on 2021/4/10.
//

import Foundation

public class PreloadURLCacheMk {
    
    let config = PreloadURLCacheConfig.shared
    
    /// 内存容量
    @discardableResult
    public func memoryCapacity(_ capacity: UInt) -> Self {
        config.memoryCapacity = capacity
        return self
    }
    
    /// 本地存储容量
    @discardableResult
    public func diskCapacity(_ capacity: UInt) -> Self {
        config.diskCapacity = capacity
        return self
    }
    
    //缓存时间
    @discardableResult
    public func cacheTime(_ time: TimeInterval) -> Self {
        config.cacheTime = time
        return self
    }
    
    //子目录
    @discardableResult
    public func subDirectory(_ directory: String) -> Self {
        config.subDirectory = directory
        return self
    }
    
    //是否启动下载模式
    @discardableResult
    public func isDownloadMode(_ mode: Bool) -> Self {
        config.isDownloadMode = mode
        return self
    }
    
    //域名白名单
    @discardableResult
    public func whiteListsHost(_ lists: [String]) -> Self {
        lists.forEach {
            config.whiteListsHost[$0] = true
        }
        return self
    }
    //WebView的user-agent白名单
    @discardableResult
    public func whiteUserAgent(_ userAgent: String) -> Self {
        config.whiteUserAgent = userAgent
        // #warning("todo")
//        WKWebView *wb = [[WKWebView alloc] initWithFrame:CGRectZero];
//        NSString *defaultAgent = [wb stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
//        NSString *agentForWhite = [defaultAgent stringByAppendingString:v];
//        NSDictionary *dictionnary = [[NSDictionary alloc] initWithObjectsAndKeys:agentForWhite, @"UserAgent", nil];
//        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionnary];
        return self
    }
    
    //添加一个域名白名单
    @discardableResult
    public func addHostWhiteList(_ list: String) -> Self {
        config.whiteListsHost[list] = true
        return self
    }
    
    //添加请求白名单
    @discardableResult
    public func addRequestUrlWhiteList(_ url: String) -> Self {
        config.whiteListsRequestUrl[url] = true
        return self
    }

    // NSURLProtocol相关设置
    // 是否使用NSURLProtocol，默认使用NSURLCache
    @discardableResult
    public func isUsingURLProtocol(_ isUsing: Bool) -> Self {
        config.isUsingURLProtocol = isUsing
        return self
    }

    //替换请求
    @discardableResult
    public func replaceUrl(_ url: String?) -> Self {
        config.replaceUrl = url
        return self
    }
    
    @discardableResult
    public func replaceData(_ data: Data?) -> Self {
        config.replaceData = data
        return self
    }
}

