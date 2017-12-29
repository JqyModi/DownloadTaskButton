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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func start(_ sender: UIButton) {
        //07-Socket的简单代码.avi
        let urlStr = "http://localhost/07-Socket的简单代码.avi"
        
        downloadFileWithUrl(urlStr: urlStr)
    }
    
    @IBAction func pause(_ sender: UIButton) {
    }
    
    @IBAction func resume(_ sender: UIButton) {
    }
    
    private func downloadFileWithUrl(urlStr: String) {
        debugPrint("urlStr ---> \(urlStr)")
        //将urlStr用URL编码：带中文不编码无法转化成URL
        let urlStr = urlStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.init(charactersIn: urlStr))
        
        debugPrint("urlPercent ---> \(urlStr)")
        
        if let url = URL(string: urlStr!) {
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
            NSURLConnection(request: request, delegate: self)?.start()
            //指定代理工作队列
        }
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
         path = NSString(string: path).addingPercentEncoding(withAllowedCharacters: CharacterSet.init(charactersIn: path))!
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
        downloadTaskBtn.ratio = ratio
        
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
        ratio = 0
    }
}

