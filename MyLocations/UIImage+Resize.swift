//
//  UIImage+Resize.swift
//  MyLocations
//
//  Created by xyy on 16/2/25.
//  Copyright © 2016年 Razeware. All rights reserved.
//

import UIKit

extension UIImage {
    func resizedImageWithBounds(bounds: CGSize) -> UIImage {
        let horizontalRatio = bounds.width / size.width
        let verticalRatio = bounds.height / size.height
        let ratio = min(horizontalRatio, verticalRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, 0)
        drawInRect(CGRect(origin: CGPoint.zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func aspectFillImage(image: UIImage) -> UIImage {
        let scale = size.width - size.height
        if scale > 0 {
            //return UIImage(CGImage: CGImageCreateWithImageInRect(self.CGImage, CGRectMake((52 - scale) / 2, 0, 52, 52))!)
            let rect = CGRectMake(scale / 2, 0, size.height, size.height)
            let imageRef = CGImageCreateWithImageInRect(image.CGImage, rect)!
            
            UIGraphicsBeginImageContextWithOptions(CGSize(width: size.height, height: size.height), true, 0)
            let con = UIGraphicsGetCurrentContext()
            CGContextDrawImage(con, CGRectMake(0, 0, size.height, size.height), imageRef)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return UIImage(CGImage: newImage.CGImage!, scale: CGFloat(1.0), orientation: .DownMirrored)
        } else {
            //return UIImage(CGImage: CGImageCreateWithImageInRect(self.CGImage, CGRectMake(0, (52 + scale) / 2, 52, 52))!)
            let rect = CGRectMake(0, -(scale / 2), size.width, size.width)
            let imageRef = CGImageCreateWithImageInRect(image.CGImage, rect)!
            
            UIGraphicsBeginImageContextWithOptions(CGSize(width: size.width, height: size.width), true, 0)
            let con = UIGraphicsGetCurrentContext()
            CGContextDrawImage(con, CGRectMake(0, 0, size.width, size.width), imageRef)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return UIImage(CGImage: newImage.CGImage!, scale: CGFloat(1.0), orientation: .DownMirrored)
        }
    }
}
