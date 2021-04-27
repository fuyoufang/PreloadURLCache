//
//  PreloadURLCacheConfig.swift
//  WKWebViewCache
//
//  Created by fuyoufang on 2021/4/10.
//

import Foundation

public class PreloadURLCacheConfig: NSObject {
    
    //-----------属性--------------
    var memoryCapacity: UInt = 20 * 1024 * 1024
    var diskCapacity: UInt = 200 * 1024 * 1024
    var cacheTime: TimeInterval = 0
    
    var isDownloadMode = false //是否为下载模式
    var isSavedOnDisk = false  //是否存磁盘

    // 磁盘路径
    lazy var diskPath: String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last!
    var subDirectory = "UrlCacheDownload"
    var cacheFolder = "Url"
    
    // 防止下载请求的循环调用
    var responseDic = [URL: Bool]()
    
    // 域名白名单
    var whiteListsHost = [String: Bool]()
    // 请求地址白名单
    var whiteListsRequestUrl = [String: Bool]()
    // WebView 的 user-agent 白名单
    var whiteUserAgent: String?

    var replaceUrl: String?
    var replaceData: Data?

    // NSURLProtocol
    
    // 是否使用URLProtocol
    var isUsingURLProtocol: Bool = false
    
    // MARK: Initialize
    
    @objc public static let shared = PreloadURLCacheConfig()
   
    // MARK: - Cache Helper
    
    /// 根据请求进行判断localResourcePathDic是否已经缓存，有返回NSCachedURLResponse,没有的话返回nil

    /// - Parameter request: 请求
    /// - Returns: 缓存的 response
    func localCacheRespone(request: URLRequest) -> CachedURLResponse? {
        
        let fm = FileManager.default
        
        if let filePath = self.filePath(request: request, isInfo: false),
           let otherInfoFilePath = self.filePath(request: request, isInfo: true),
           fm.fileExists(atPath: filePath),
           let otherInfo = NSDictionary(contentsOfFile: otherInfoFilePath) {
            //有缓存文件的情况
            var expire = false
            
            
            if cacheTime > 0 {
                let createTime: TimeInterval
                if let time = otherInfo["time"] as? String {
                    createTime = TimeInterval(time) ?? 0
                } else {
                    createTime = 0
                }
                if (createTime + cacheTime) < Date().timeIntervalSince1970 {
                    expire = true
                }
            }
            
            if expire {
                // cache失效了
                try? fm.removeItem(atPath: filePath)
                try? fm.removeItem(atPath: otherInfoFilePath)
                return nil
            } else {
                // 从缓存里读取数据
                guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
                    return nil
                }
                
                guard let url = request.url else {
                    return nil
                }
                let response = URLResponse(url: url,
                                           mimeType: otherInfo["MIMEType"] as? String,
                                           expectedContentLength: data.count,
                                           textEncodingName: otherInfo["textEncodingName"] as? String)
                return CachedURLResponse(response: response, data: data)
            }
        } else {
            //从网络读取
            self.isSavedOnDisk = false
            guard let url = request.url else {
                return nil
            }
            guard self.responseDic[url] == nil else {
                return nil
            }
            self.responseDic[url] = true
            
            let filePath = self.filePath(request: request, isInfo: false)
            let otherInfoFilePath = self.filePath(request: request, isInfo: true)
            var cachedResponse: CachedURLResponse? = nil
            let session = URLSession.shared
            let date = Date()
            let task = session.dataTask(with: request) { (data, response, error) in
                if error != nil {
                    cachedResponse = nil
                } else if let response = response, let data = data {
                    let dic = NSMutableDictionary()
                    dic["time"] = "\(date.timeIntervalSince1970)"
                    dic["MIMEType"] = response.mimeType
                    dic["textEncodingName"] = response.textEncodingName
                    
                    if let file = filePath {
                        // [data writeToFile:filePath atomically:YES];
                        try? data.write(to: URL(fileURLWithPath: file))
                    }
                    
                    if let file = otherInfoFilePath {
                        dic.write(toFile: file, atomically: true)
                    }
                    cachedResponse = CachedURLResponse(response: response, data: data)
                }
            }
            task.resume()
            return cachedResponse
        }
    }

    /// 清除请求对应的缓存
    /// - Parameter request:
    func removeCacheFile(request: URLRequest) {
        let fm = FileManager.default
        if let filePath = self.filePath(request: request, isInfo: false) {
            try? fm.removeItem(atPath: filePath)
        }
        if let otherInfoFilePath = self.filePath(request: request, isInfo: true) {
            try? fm.removeItem(atPath: otherInfoFilePath)
        }
    }

    /// 清除自建的缓存目录
    func checkCapacity() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            if self.folderSize() > self.diskCapacity {
                self.deleteCacheFolder()
            }
        }
    }
    
    //查找请求对应的文件路径
    func filePath(request: URLRequest, isInfo info: Bool) -> String? {
        guard let url = request.url?.absoluteString else {
            return nil
        }
        if info {
            let otherInfoFileName = cacheRequestOtherInfoFileName(url)
            return cacheFilePath(file: otherInfoFileName)
            
        } else {
            let fileName = cacheRequestFileName(url)
            return cacheFilePath(file: fileName)
        }
    }
    
    func cacheRequestFileName(_ requestUrl: String) -> String {
        return requestUrl.md5()
    }
    
    func cacheRequestOtherInfoFileName(_ requestUrl: String) -> String {
        return "\(requestUrl)-otherInfo".md5()
    }
    
    func cacheFilePath(file: String) -> String {
        
        let path = "\(diskPath)/\(cacheFolder)"
        var isDir: ObjCBool = false
        let fm = FileManager.default
        if fm.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue {
            
        } else {
            try? fm.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }

        let subDirPath = "\(diskPath)/\(cacheFolder)/\(subDirectory)"
        if fm.fileExists(atPath: subDirectory, isDirectory: &isDir) && isDir.boolValue {
            
        } else {
            try? fm.createDirectory(atPath: subDirPath, withIntermediateDirectories: true, attributes: nil)
        }
        return "\(subDirPath)/\(file)"
    }

    
    func deleteCacheFolder() {
        try? FileManager.default.removeItem(atPath: cacheFolderPath())
    }
    
    func folderSize() -> UInt {
        let cacheFolderPath = self.cacheFolderPath()
        guard let filesArray = try? FileManager.default.subpathsOfDirectory(atPath: cacheFolderPath) else {
            return 0
        }
        
        var fileSize: UInt64 = 0 // unsigned long long int
                
        let url = URL(fileURLWithPath: cacheFolderPath)
        
        filesArray.forEach { (fileName) in
            var filePath = url
            filePath.appendPathComponent(fileName)
            guard let fileDic = try? FileManager.default.attributesOfItem(atPath: filePath.absoluteString),
                  let size = fileDic[FileAttributeKey.size] as? UInt64 else {
                return
            }
            fileSize += size
        }
        return UInt(fileSize)
    }
    
    func cacheFolderPath() -> String {
        return "\(diskPath)/\(cacheFolder)/\(subDirectory)"
    }
}
