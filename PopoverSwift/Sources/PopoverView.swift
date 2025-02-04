//
//  PopoverView.swift
//  PopoverSwift
//
//  Created by Roy Shaw on 3/18/16.
//  Copyright © @2016 Red Rain (https://github.com/cuzv).
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

open class PopoverView: UIView {
    fileprivate let items: [PopoverItem]
    fileprivate let fromView: UIView
    fileprivate let initialIndex: Int
    fileprivate let direction: Direction
    fileprivate let reverseHorizontalCoordinates: Bool
    fileprivate let style: PopoverStyle
    fileprivate let dismissHandler: (() -> Void)?

    fileprivate weak var commonSuperView: UIView!

    let arrawView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.rowHeight = RowHeight
        tableView.bounces = false
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        tableView.backgroundColor = UIColor.clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.layer.cornerRadius = CornerRadius
        tableView.layer.masksToBounds = true

        return tableView
    }()

    lazy var tableViewWidth: CGFloat = {
        var maxLengthTitle: String = ""
        self.items.forEach { (item: PopoverItem) -> Void in
            if item.title.length > maxLengthTitle.length {
                maxLengthTitle = item.title
            }
        }
        var width: CGFloat = maxLengthTitle.size(font: CellLabelFont, preferredMaxLayoutWidth: CGFloat.greatestFiniteMagnitude).width
        if width < 160 {
            width = 160
        }

        width += Leading * 2

        if self.style == .withImage {
            width += ImageWidth + Spacing
        }

        return width
    }()

    lazy var tableViewHeight: CGFloat = {
        let count = self.items.count > MaxRowCount ? MaxRowCount : self.items.count
        return CGFloat(count) * RowHeight
    }()

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init(_ host: PopoverController, commonSuperView: UIView) {
        if host.reverseHorizontalCoordinates {
            self.items = host.items.reversed()
        } else {
            self.items = host.items
        }
        self.fromView = host.fromView
        self.initialIndex = host.initialIndex
        self.direction = host.direction
        self.reverseHorizontalCoordinates = host.reverseHorizontalCoordinates
        self.style = host.style
        self.dismissHandler = host.dismissHandler

        self.commonSuperView = commonSuperView

        super.init(frame: CGRect.zero)

        setup()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
    
        if arrawView.layer.contents != nil {
            return
        }
    
        let color = items[0].coverColor ?? UIColor.white
        let arrawCenterX: CGFloat = fromView.frame.midX - arrawView.frame.midX + arrawView.bounds.midX
        let bounds = arrawView.bounds
    
        // Determine whether the arrow should be flipped (pointing up or down)
        let shouldFlipArrow = (direction == .up)
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let image = drawArrawImage(
                in: bounds,
                strokeColor: color,
                fillColor: color,
                lineWidth: LineWidth,
                arrawCenterX: arrawCenterX,
                arrawWidth: 10,
                arrawHeight: 10,
                cornerRadius: CornerRadius,
                handstand: shouldFlipArrow // Flip arrow based on direction
            )
            DispatchQueue.main.async {
                self.arrawView.image = image
            }
        }
    
        tableView.scrollToRow(at: IndexPath(row: initialIndex, section: 0), at: .top, animated: false)
    }

    func setup() {
        tableView.delegate = self
        tableView.dataSource = self
        addSubview(arrawView)
        addSubview(tableView)

        var clazz: AnyClass? = PopoverCell.self
        var identifier: String = PopoverCell.identifier
        if style == .withImage {
            clazz = PopoverWihtImageCell.self
            identifier = PopoverWihtImageCell.identifier
        }
        tableView.register(clazz, forCellReuseIdentifier: identifier)
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let location = touches.first?.location(in: self), !arrawView.frame.contains(location) {
            dismiss()
        }
    }

    func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.tableView.alpha = 0
            self.arrawView.alpha = 0
        }, completion: {_ in
            self.subviews.forEach { $0.removeFromSuperview() }
            self.removeFromSuperview()
            self.dismissHandler?()
            completion?()
        })
    }

    func addConstraints() {
        let screenWidth: CGFloat = superview!.frame.width
        var centerX: CGFloat = fromView.frame.origin.x + fromView.bounds.width / 2.0
        let rightHand = centerX - screenWidth / 2.0 > 0
        if rightHand {
            centerX = screenWidth - centerX
        }

        var constant0: CGFloat = 0
        let distance = centerX - (tableViewWidth / 2.0 + 6)
        if distance <= 0 {
            constant0 = rightHand ? distance : -distance
        }

        var attribute0: LayoutAttribute = .top
        var attribute1: LayoutAttribute = .bottom
        var constant1: CGFloat = 10

        if direction == .up {
            attribute0 = .bottom
            attribute1 = .top
            constant1 = -10
        }

        commonSuperView.addConstraints([
            NSLayoutConstraint(
                item: tableView,
                attribute: .centerX,
                relatedBy: .equal,
                toItem: fromView,
                attribute: .centerX,
                multiplier: 1,
                constant: constant0
            ),
            NSLayoutConstraint(
                item: tableView,
                attribute: attribute0,
                relatedBy: .equal,
                toItem: fromView,
                attribute: attribute1,
                multiplier: 1,
                constant: constant1
            ),
            NSLayoutConstraint(
                item: tableView,
                attribute: .width,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1,
                constant: tableViewWidth
            ),
            NSLayoutConstraint(
                item: tableView,
                attribute: .height,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1,
                constant: tableViewHeight
            )
        ])

        commonSuperView.addConstraints([
            NSLayoutConstraint(
                item: arrawView,
                attribute: .width,
                relatedBy: .equal,
                toItem: tableView,
                attribute: .width,
                multiplier: 1,
                constant: LineWidth * 2
            ),
            NSLayoutConstraint(
                item: arrawView,
                attribute: .height,
                relatedBy: .equal,
                toItem: tableView,
                attribute: .height,
                multiplier: 1,
                constant: abs(constant1) - 2
            ),
            NSLayoutConstraint(
                item: arrawView,
                attribute: .centerX,
                relatedBy: .equal,
                toItem: tableView,
                attribute: .centerX,
                multiplier: 1,
                constant: 0
            ),
            NSLayoutConstraint(
                item: arrawView,
                attribute: .centerY,
                relatedBy: .equal,
                toItem: tableView,
                attribute: .centerY,
                multiplier: 1,
                constant: -constant1 / 2.0
            )
        ])
    }

#if DEBUG
    deinit {
        debugPrint("\(#file):\(#line):\(type(of: self)):\(#function)")
    }
#endif
}

extension PopoverView: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if style == .withImage {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PopoverWihtImageCell.identifier) as? PopoverWihtImageCell else {
                fatalError("Must register cell first")
            }
            cell.setupData(items[(indexPath as NSIndexPath).row])
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PopoverCell.identifier) as? PopoverCell else {
                fatalError("Must register cell first")
            }
            cell.setupData(items[(indexPath as NSIndexPath).row])
            return cell
        }
    }
}

extension PopoverView: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let popoverItem = items[(indexPath as NSIndexPath).row]
        dismiss {
            popoverItem.handler?(popoverItem)
        }
    }
}
