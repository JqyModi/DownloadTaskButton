//
//  ViewController.swift
//  DownloadTaskButton
//
//  Created by mac on 2017/12/29.
//  Copyright © 2017年 modi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var downloadTaskBtn: DownloadTaskButton!
    
    var fileName: String?
    var type: String?
    var fileSize: Int = 0
    var currentSize: Int = 0
    var currentData: Data = Data()
    
    var path = ""
    
    var ratio: CGFloat = 0
    
    var fileStream: OutputStream?
    
    var urlSession: URLSession?
    
    /**
     *  解决方式2：
     *  Desc:在URLSession中所有网络任务都是由session发起
        一旦任务开始执行session会对任务强引用，相反，任务一旦被取消则不再对任务强引用
        故将该变量设置为弱引用可以解决用户取消(暂停)下载后再次点击继续时出现同时开启多
        个下载任务的情况
     *  Param:
     */
    weak var downloadTask: URLSessionDownloadTask?
    
    //记录续传数据
    var resumeData: Data?
    
    private func session() -> URLSession {
        if urlSession == nil {
            //全局配置 替代URLRequest配置：
            let config = URLSessionConfiguration.default
            //代理Queue暂时设置为nil
            urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        }
        return urlSession!
    }
    
    /**
     CFRunLoop:
        1.CFRunLoopGetCurrent()获取当前线程运行循环
        2.CFRunLoopStop(self.downloadRunLoop)停止当前线程运行循环
        3.CFRunLoopRun()运行当前线程运行循环
     */
    //指定下载任务RunLoop
    var downloadRunLoop: CFRunLoop?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //初始化urlSession
        session()
        
        
    }
    
    @IBAction func start(_ sender: UIButton) {
        
        //判断当前是否已经在下载
        if self.downloadTask?.state == URLSessionTask.State.running || self.downloadTask?.state == URLSessionTask.State.suspended {
            debugPrint("任务已经在下载中 ~ ")
            return
        }
        
        //07-Socket的简单代码.avi
        let urlStr = "http://localhost/01-网络基础.rar"
        //将urlStr用URL编码：带中文不编码无法转化成URL
        let urlStrEncode = urlStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.init(charactersIn: urlStr))
//        DispatchQueue.global().sync {
//            downloadFileWithUrlByURLSession(urlStr: urlStrEncode!)
//        }
        downloadFileWithUrlAndProgressByURLSession(urlStr: urlStrEncode!)
    }
    
    @IBAction func pause(_ sender: UIButton) {
        if self.downloadTask == nil {
            debugPrint("没有开始的下载任务 ~")
            return
        }
        
        //将task提取成全局变量以便暂停下载
        self.downloadTask?.cancel(byProducingResumeData: { (data) in
            debugPrint("data.lenght -----> \(data?.count)")
            //记录续传数据
            self.resumeData = data
            //释放下载任务: 防止再次点击暂停时出现续传数据为0：
            //解决方式1.取消下载任务后不再进入该代码块
//            self.downloadTask = nil
        })
    }
    
    @IBAction func resume(_ sender: UIButton) {
        
        //判断续传数据是否为空
        if self.resumeData == nil {
            debugPrint("没有未完成的任务 ~")
            return
        }
        
        //重新开启一个新的下载任务继续下载
        self.downloadTask = urlSession?.downloadTask(withResumeData: self.resumeData!)
        //代码块回调不走代理
//        self.downloadTask = urlSession?.downloadTask(withResumeData: self.resumeData!, completionHandler: { (url, response, error) in
//            debugPrint("完成：location = \(url)")
//            //清空续传数据
//            self.resumeData = nil
//        })
        //所有任务默认挂起状态需要开始任务
        self.downloadTask?.resume()
        //清空续传数据：续传数据的目的是重新开启一个下载任务续传数据，一旦续传任务开启之后直接清空
        self.resumeData = nil
    }
    
    /**
     *  Desc:通过URLConnection来下载文件
     *  Param:
     */
    private func downloadFileWithUrlByURLConnection(urlStr: String) {
        debugPrint("urlStr ---> \(urlStr)")
        //将urlStr用URL编码：带中文不编码无法转化成URL
//        let urlStr = urlStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.init(charactersIn: urlStr))
        
//        debugPrint("urlPercent ---> \(urlStr)")
        
        if let url = URL(string: urlStr) {
            let request = URLRequest(url: url)
            /**
            //方式一： NSURLConnection 发送异步请求
            //发送一个异步请求下载文件：缺点：1.无法跟进下载进度 2.下载出现内存峰值
            NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.current!, completionHandler: { (response, data, error) in
//                debugPrint("response ---> \(response)")
//                debugPrint("data ---> \(data)")
//                debugPrint("error ---> \(error)")
                //将数据写入/Users/mac/Desktop
                let path = "/Users/mac/Desktop/\(response?.suggestedFilename!)"
                debugPrint("path ---> \(path)")
                if let nsData = data as? NSData {
                    nsData.write(toFile: path, atomically: true)
                    debugPrint("文件写入完成: \(NSHomeDirectory())")
                }
            })
             */
            
            //方式二：使用代理下载跟进进度及解决内存峰值问题：
            let conn = NSURLConnection(request: request, delegate: self)
            //指定代理工作队列
            conn?.setDelegateQueue(OperationQueue.init())
            conn?.start()
            
            //拿到当前线程的运行循环
            self.downloadRunLoop = CFRunLoopGetCurrent()
            //启动运行循环
            CFRunLoopRun()
        }
    }

    /**
     *  Desc:通过URLSession来进行网络访问
     *  Param:
     */
    private func requestWithUrlByURLSession(urlStr: String) {
        //因为开发中通常都是跟一个服务器交互，苹果提供了一个单例
        let session = URLSession.shared
        let url = URL(string: urlStr)
        let request = URLRequest(url: url!)
        let dataTask = session.dataTask(with: URL(string: urlStr)!) { (data, response, error) in
            debugPrint("response -----> \(response)")
        }
//        let dataTask = session.dataTask(with: request) { (data, response, error) in
//            debugPrint("response -----> \(response)")
//        }
        //启动任务
        dataTask.resume()
        
    }

    /**
     *  Desc:通过URLSession来进行文件下载
     *  Param:网络下载的文件一般都是ZIP文件较多：解压缩：ZipArchive(框架)
     */
    private func downloadFileWithUrlByURLSession(urlStr: String) {
        //因为开发中通常都是跟一个服务器交互，苹果提供了一个单例
        let session = URLSession.shared
        let url = URL(string: urlStr)
        let request = URLRequest(url: url!)
        let dataTask = session.downloadTask(with: url!) { (url, response, error) in
            //文件下载后暂时存放的URL路径
            debugPrint("url -----> \(url)")
            debugPrint("response -----> \(response)")
            
            //解压缩操作
            let destPath = "/Users/mac/Desktop/modi/"
            debugPrint("解压：\(SSZipArchive.unzipFile(atPath: (url?.path)!, toDestination: destPath))")
        }
        //启动任务
        dataTask.resume()
        
    }

    /**
     *  Desc: 通过代理跟进下载进度，代理1对1不能使用系统的共享属性URLSession.shared
     *  Param: urlStr
     */
    private func downloadFileWithUrlAndProgressByURLSession(urlStr: String) {
        //带block回调的不走代理
        self.downloadTask = urlSession?.downloadTask(with: URL(string: urlStr)!)
        //开始任务
        self.downloadTask?.resume()
    }
    
}

extension ViewController: NSURLConnectionDataDelegate {
    /*
     收到服务器响应
     */
    func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        debugPrint("收到服务器响应: response ---> \(response)")
        //获取必要信息
        fileName = response.suggestedFilename!
        type = response.mimeType!
        fileSize = Int(response.expectedContentLength)
        path = "/Users/mac/Desktop/" + fileName!
        
        //防止用户再次点击：判断是否存在
//         path = NSString(string: path).addingPercentEncoding(withAllowedCharacters: CharacterSet.init(charactersIn: path))!
        do {
            try FileManager.default.removeItem(atPath: path)
        }catch {
            debugPrint("error ---> \(error)")
        }
        
        //方式三：通过文件输出流写入磁盘
        //初始化输出流
        fileStream = OutputStream(toFileAtPath: path, append: true)
        //打开流
        fileStream?.open()
    }
    /*
     收到服务器响应数据
     data：接收到的数据块大小随机
     */
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        debugPrint(" 收到服务器响应数据: data ---> \(data)")
//        currentData.append(data)
        currentSize += (data.count)
        //计算出当前下载进度百分比
        ratio = CGFloat(currentSize) / CGFloat(fileSize)
        debugPrint(" ratio ---> \(ratio)")
        debugPrint(" thread ---> \(Thread.current)")
        
        DispatchQueue.main.async {
            self.downloadTaskBtn.ratio = self.ratio
        }
//        self.downloadTaskBtn.ratio = self.ratio
        
        //将数据写入磁盘：接收一块写一块：避免内存峰值问题
//        if let nsData = data as? NSData {}
        //获取操作文件的Handler
        debugPrint("path ---> \(path)")
        //将urlStr用URL编码：带中文不编码无法转化成URL
        path = NSString(string: path).addingPercentEncoding(withAllowedCharacters: CharacterSet.init(charactersIn: path))!
        //fp相对于文件指针：需要指针后移：指哪写哪
        /*
        let fp = FileHandle(forWritingAtPath: path)
        if fp == nil {
            do {
                try data.write(to: URL.init(fileURLWithPath: path), options: Data.WritingOptions.atomicWrite)
            }catch {
                debugPrint("error --> \(error)")
            }
        }else {
            //先将指针后移在最后追加文件
            fp?.seekToEndOfFile()
            //写入文件
            fp?.write(data)
            //关闭文件指针：节省开支及下一个读写：C语言中文件打开关闭通常成对出现
            fp?.closeFile()
        }
        //检测下载的文件是否正确用MD5校验: md5 fileName
         */
        
        //方式三：通过文件输出流写入磁盘: buffer: UnsafePointer<UInt8>
        var buffer = [UInt8]()
        fileStream?.write(&buffer, maxLength: data.count)
    }
    /*
     完成
     */
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        debugPrint("完成")
        currentData.removeAll()
        //清空防止ratio一直增大
        currentSize = 0
        //关闭流
        fileStream?.close()
//        ratio = 0
        
        //停止当前线程的RunLoop
        CFRunLoopStop(self.downloadRunLoop)
    }
    
    
}

extension ViewController: URLSessionDownloadDelegate {
    /**
     *  Desc: 文件下载进度监听
     *  Param: 1.bytesWritten：数据块大小
               2.totalBytesWritten：已经下载
               3.totalBytesExpectedToWrite：文件总大小
     */
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
        debugPrint("progress ---> \(progress)")
        //主线程更新UI
        DispatchQueue.main.async {
            self.downloadTaskBtn.ratio = progress
        }
        
    }
    
    /**
     *  Desc: 续传数据
     *  Param:
     */
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        debugPrint("didResumeAtOffset")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        debugPrint("完成：location = \(location)")
        //解压缩操作
        let destPath = "/Users/mac/Desktop/modi/"
        debugPrint("解压：\(SSZipArchive.unzipFile(atPath: (location.path), toDestination: destPath))")
    }
}
