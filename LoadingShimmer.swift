//
//  LoadingShimmer.swift
//  LoadingShimmer_Example
//
//  Created by JOGENDRA on 20/05/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

let kScreenHeight = UIScreen.main.bounds.size.height
let safeAreaTopHeight = (kScreenHeight == 812.0 || kScreenHeight == 896.0) ? 88 : 64

class LoadingShimmer: NSObject {

    private var cover: UIView?
    private var viewCover: UIView? {
        if cover == nil {
            let cover = UIView()
            cover.tag = 1024
            cover.backgroundColor = UIColor.white
        }
        return cover
    }

    private var colorLayer: CAGradientLayer?

    private var maskLayer: CAShapeLayer?

    private var coverablePath: UIBezierPath?
    private var totalCoverablePath: UIBezierPath? {
        if coverablePath == nil {
            coverablePath = UIBezierPath()
        }
        return coverablePath
    }

    private var addOffsetflag = false

    public func startCovering(_ view: UIView?) {
        self.coverSubviews(view)
    }

    public func stopCovering(_ view: UIView?) {
        self.removeSubviews(view)
    }


    func removeSubviews(_ view: UIView?) {

        if view == nil {
            return
        }

        for subview in view?.subviews ?? [] {
            if subview.tag == 1024 {
                subview.removeFromSuperview()
                break
            }
        }

    }

    func coverSubviews(_ view: UIView?) {

        if view == nil {
            return
        }

        for subview in view?.subviews ?? [] {
            if subview.tag == 1127 {
                return
            }
        }

        let coverableCellsIds = ["Cell1", "Cell1", "Cell1", "Cell1", "Cell1"]
        if type(of: view!) === UITableView.self {
            for i in 0..<coverableCellsIds.count {
                getTableViewPath(view, index: i, coverableCellsIds: coverableCellsIds)
            }
            addCover(view)
            return
        }

        view?.backgroundColor = UIColor.white

        if (view?.subviews.count ?? 0) > 0 {
            for subview in view?.subviews ?? [] {

                var defaultCoverblePath = UIBezierPath(roundedRect: subview.bounds, cornerRadius: subview.frame.size.height / 2.0)
                if type(of: subview) === UILabel.self || type(of: subview) === UITextView.self {
                    defaultCoverblePath = UIBezierPath(roundedRect: subview.bounds, cornerRadius: 4)
                }
                let relativePath: UIBezierPath = defaultCoverblePath

                let offsetPoint: CGPoint = subview.convert(subview.bounds, to: view).origin
                subview.layoutIfNeeded()
                relativePath.apply(CGAffineTransform(translationX: offsetPoint.x, y: offsetPoint.y))

                totalCoverablePath?.append(relativePath)
            }
            addCover(view)
        }

    }


    func getTableViewPath(_ view: UIView?, index i: Int, coverableCellsIds: [Any]?) {

        let tableView = view as? UITableView


        let cell: UITableViewCell? = tableView?.dequeueReusableCell(withIdentifier: coverableCellsIds?[i] as? String ?? "")
        let headerOffset = getHeaderOffset()

        cell?.frame = CGRect(x: 0, y: (cell?.frame.size.height ?? 0.0) * CGFloat(i) + CGFloat(headerOffset), width: cell?.frame.size.width ?? 0.0, height: cell?.frame.size.height ?? 0.0)

        cell?.layoutIfNeeded()
        for cellSubview in cell?.contentView.subviews ?? [] {
            let defaultCoverblePath = UIBezierPath(roundedRect: cellSubview.bounds, cornerRadius: cellSubview.frame.size.height / 2.0)
            var offsetPoint: CGPoint = cellSubview.convert(cellSubview.bounds, to: tableView).origin
            if i == 0 {
                if offsetPoint.y > cellSubview.frame.origin.y {
                    addOffsetflag = true
                }
            }
            if addOffsetflag {
                offsetPoint.y -= CGFloat(headerOffset)
            }
            cellSubview.layoutIfNeeded()
            defaultCoverblePath.apply(CGAffineTransform(translationX: offsetPoint.x, y: offsetPoint.y + CGFloat(headerOffset)))

            totalCoverablePath?.append(defaultCoverblePath)
        }

    }

    func addCover(_ view: UIView?) {
        viewCover?.frame = CGRect(x: 0, y: 0, width: view?.frame.size.width ?? 0.0, height: view?.frame.size.height ?? 0.0)
        view?.addSubview(viewCover!)
        let colorLayer = CAGradientLayer()
        colorLayer.frame = view?.bounds ?? CGRect.zero

        colorLayer.startPoint = CGPoint(x: -1.4, y: 0)
        colorLayer.endPoint = CGPoint(x: 1.4, y: 0)

        colorLayer.colors = [
            UIColor(red: 0, green: 0, blue: 0, alpha: 0.01).cgColor,
            UIColor(red: 0, green: 0, blue: 0, alpha: 0.1).cgColor,
            UIColor(red: 1, green: 1, blue: 1, alpha: 0.009).cgColor,
            UIColor(red: 0, green: 0, blue: 0, alpha: 0.04).cgColor,
            UIColor(red: 0, green: 0, blue: 0, alpha: 0.02).cgColor
        ]

        colorLayer.locations = [
            NSNumber(value: Double(colorLayer.startPoint.x)),
            NSNumber(value: Double(colorLayer.startPoint.x)),
            NSNumber(value: 0),
            NSNumber(value: 0.2),
            NSNumber(value: 1.2)
        ]

        viewCover?.layer.addSublayer(colorLayer)
        let maskLayer = CAShapeLayer()
        maskLayer.path = totalCoverablePath?.cgPath
        maskLayer.fillColor = UIColor.red.cgColor

        colorLayer.mask = maskLayer
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = colorLayer.locations
        animation.toValue = [NSNumber(value: 0), NSNumber(value: 1), NSNumber(value: 1), NSNumber(value: 1.2), NSNumber(value: 1.2)]
        animation.duration = 0.9
        animation.repeatCount = HUGE
        animation.isRemovedOnCompletion = false
        colorLayer.add(animation, forKey: "locations-layer")

    }

    func getHeaderOffset() -> CGFloat {
        if currentViewController() != nil {
            return CGFloat(safeAreaTopHeight)
        } else {
            return 0
        }
    }

    func currentViewController() -> UIViewController? {
        let keyWindow: UIWindow? = UIApplication.shared.keyWindow
        var vc: UIViewController? = keyWindow?.rootViewController
        while ((vc?.presentedViewController) != nil) {
            vc = vc?.presentedViewController

            if (vc is UINavigationController) {
                vc = (vc as? UINavigationController)?.visibleViewController
            } else if (vc is UITabBarController) {
                vc = (vc as? UITabBarController)?.selectedViewController
            }
        }
        return vc
    }

    func currentNavigationController() -> UINavigationController? {
        return currentViewController()?.navigationController
    }

}