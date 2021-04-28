//
//  PreloadURLProtocol.swift
//  WKWebViewCache
//
//  Created by fuyoufang on 2021/4/10.
//

import Foundation

private let URLProtocolHandled = "WKWebViewCache_URLProtocolHandled"

class PreloadURLProtocol: URLProtocol {
    var _task: URLSessionDataTask?
    var data: Data?
    var response: URLResponse?
    var filePath: String?
    var otherInfoPath: String?
    
    override class func canInit(with request: URLRequest) -> Bool {
        let config = PreloadURLCacheConfig.shared
        
        //User-Agent来过滤
        if let whiteUserAgent = config.whiteUserAgent,
           whiteUserAgent.count > 0 {
            guard let uAgent = request.allHTTPHeaderFields?["User-Agent"],
                  uAgent.hasSuffix(whiteUserAgent) else {
                return false
            }
        }
     
        //只允许GET方法通过
        guard request.httpMethod == "GET" else {
            return false
        }
        
            //防止递归
        guard URLProtocol.property(forKey: URLProtocolHandled, in: request) == nil else {
            return false
        }
        
            // 对于域名白名单的过滤
        if config.whiteListsHost.count > 0 {
            guard let host = request.url?.host,
                  let _ = config.whiteListsHost[host]  else {
                return false
            }
        }
        
        guard let sheme = request.url?.scheme?.lowercased(),
              (sheme == "http" || sheme == "https") else {
            return false
        }
        return true
    }
  
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
        return super.requestIsCacheEquivalent(a, to: b)
    }
    
    override func startLoading() {
        let config = PreloadURLCacheConfig.shared

        filePath = config.filePath(request: self.request, isInfo: false)
        otherInfoPath = config.filePath(request: self.request, isInfo: true)
        
        let fm = FileManager.default
        var expire = false
        
        if let filePath = self.filePath,
           let otherInfoPath = self.otherInfoPath,
           fm.fileExists(atPath: filePath),
           let otherInfo = NSDictionary(contentsOfFile: otherInfoPath) {
            // 有缓存文件的情况
            let createTime: TimeInterval
            if let time = otherInfo["time"] as? String {
                createTime = TimeInterval(time) ?? 0
            } else {
                createTime = 0
            }
            
            if config.cacheTime > 0 {
                if createTime + config.cacheTime < Date().timeIntervalSince1970 {
                    expire = true
                }
            }
            if expire {
                // cache失效了
                try? fm.removeItem(atPath: filePath) //清除缓存data
                try? fm.removeItem(atPath: otherInfoPath) //清除缓存其它信息
            } else {
                //从缓存里读取数据
                guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
                      let url = self.request.url else {
                    expire = true
                    return
                }
                let response = URLResponse(url: url,
                                           mimeType: otherInfo["MIMEType"] as? String,
                                           expectedContentLength: data.count,
                                           textEncodingName: otherInfo["textEncodingName"] as? String)
                
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            }
        } else {
            expire = true
        }
       
        if expire {
            guard let request: NSMutableURLRequest = (self.request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
                return
            }

            URLProtocol.setProperty(true, forKey: URLProtocolHandled, in: request)
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
            self._task = session.dataTask(with: self.request)
            self._task?.resume()
        }
    }
    
    override func stopLoading() {
        self._task?.cancel()
    }
    
    // MARK: - Helper
    func clear() {
        data = nil
        _task = nil
        response = nil
    }
    
    func append(data: Data) {
        if self.data == nil {
            self.data = data
        } else {
            self.data?.append(data)
        }
    }
    
}

// MARK: - NSURLSession Delegate
extension PreloadURLProtocol: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            debugPrint(error)
        }
    }

    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
        self.response = response
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
        append(data: data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        client?.urlProtocolDidFinishLoading(self)
        if let error = error {
            if let urlError = error as? URLError, urlError.code == URLError.cancelled {
                // url 取消
            } else {
                client?.urlProtocol(self, didFailWithError: error)
            }
        } else {
            //开始缓存
            if let otherInfoPath = self.otherInfoPath,
               let filePath = self.filePath,
               let data = self.data {
                let dic = NSMutableDictionary()
                dic["time"] = Date().timeIntervalSince1970
                dic["MIMEType"] = self.response?.mimeType
                dic["textEncodingName"] = self.response?.textEncodingName
                dic.write(toFile: otherInfoPath, atomically: true)
                
                try? data.write(to: URL(fileURLWithPath: filePath))
            }
            
        }
        clear()
    }
    
}
