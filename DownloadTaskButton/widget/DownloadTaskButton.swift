//
//  DownloadTaskButton.swift
//  DownloadTaskButton
//
//  Created by mac on 2017/12/29.
//  Copyright © 2017年 modi. All rights reserved.
//

import UIKit

class DownloadTaskButton: UIButton {
    
    var width: CGFloat = 0
    var height: CGFloat = 0
    
    var ratio: CGFloat = 0.0 {
        didSet {
            title = String(format: "%.2f%%", ratio*100)
            setNeedsDisplay()
        }
    }
    
    var title: String? {
        didSet {
            setTitle(title, for: .normal)
            setTitleColor(UIColor.orange, for: .normal)
        }
    }
    
    //定义进度条宽度
    var lineWidth: CGFloat = 2.5

    override func awakeFromNib() {
        width = bounds.width
        height = bounds.height
        
        lineWidth = 5
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code : rect = self.bounds
        drawArcWithProgress(ratio: ratio)
    }

    private func drawArcWithProgress(ratio: CGFloat) {
        //
        let arcCenter = CGPoint(x: width/2, y: height/2)
        var radius = (width > height) ? height/2 : width/2
        radius -= self.lineWidth * 0.5
        let startAngle: CGFloat = CGFloat(-M_PI_2)
        let endAngle = ratio * 2 * CGFloat(M_PI) + startAngle
        debugPrint(" endAngle ---> \(endAngle)")
        let path = UIBezierPath(arcCenter: arcCenter, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        path.lineWidth = lineWidth
        //颜色
        UIColor.orange.set()
        path.stroke()
    }
}
