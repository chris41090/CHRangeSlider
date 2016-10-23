//
//  CHRangeSlider.swift
//  CHRangeSlider
//
//  Created by Christos Hadjikyriacos on 30/04/16.
//  Copyright © 2016 Christos Hadjikyriacos. All rights reserved.
//


import UIKit

@objc protocol CHRangeSliderDelegate:class {
    @objc optional func rangeSlider(_ sender:CHRangeSlider,didChangeSelectedMinimumValue selectedMinimum:CGFloat, andMaximumValue selectedMaximum:CGFloat)
    @objc optional func didEndTouchesInRangeSlider(_ sender:CHRangeSlider)
    @objc optional func didStartTouchesInRangeSlider(_ sender:CHRangeSlider)
}

@IBDesignable
class CHRangeSlider:UIControl,UIGestureRecognizerDelegate {
    
    weak var delegate:CHRangeSliderDelegate?
    
    
    var numberFormatterOverride:NumberFormatter? {
        didSet {
            updateLabelValues()
        }
    }
    
    
    
    
    var noRangeUnselectedArea = CALayer()
    var leftUnselectedArea = CALayer()
    var rightUnselectedArea = CALayer()
    var minLabel:CATextLayer = CATextLayer()
    var maxLabel:CATextLayer = CATextLayer()
    var sliderLine:CALayer = CALayer()
    var leftHandle:CALayer = CALayer()
    var rightHandle:CALayer = CALayer()
    var leftHandleSelected:Bool = false
    var rightHandleSelected:Bool = false
    
    
    lazy var decimalNumberFormatter:NumberFormatter = {
        let decimalNumberFormatter = NumberFormatter()
        decimalNumberFormatter.numberStyle = .decimal
        decimalNumberFormatter.maximumFractionDigits = 0
        return decimalNumberFormatter
    }()
    
    @IBInspectable var minValue:CGFloat = 0 {
        didSet {
            refresh()
        }
    }
    
    @IBInspectable var showUnselectedArea:Bool = true {
        didSet {
            noRangeUnselectedArea.isHidden = !showUnselectedArea
            leftUnselectedArea.isHidden =  !showUnselectedArea
            rightUnselectedArea.isHidden = !showUnselectedArea
        }
    }
    
    
    
    @IBInspectable var maxValue:CGFloat = 100 {
        didSet{
            refresh()
        }
    }
    @IBInspectable var selectedMinimum:CGFloat = 10 {
        didSet {
            
            if didSet {
                
                if selectedMinimum < minValue {
                    selectedMinimum = minValue
                }
                
                refresh()
            }
            
        }
    }
    @IBInspectable var selectedMaximum:CGFloat = 90 {
        didSet {
            if didSet {
                
                if selectedMaximum > maxValue {
                    selectedMaximum = maxValue
                }
                
                
                refresh()
                
            }
            
            
        }
    }
    @IBInspectable var hideLabels:Bool = false
    @IBInspectable var minLabelColor:UIColor? {
        didSet {
            minLabel.foregroundColor = minLabelColor?.cgColor
        }
    }
    @IBInspectable var maxLabelColor:UIColor? {
        didSet {
            maxLabel.foregroundColor = maxLabelColor?.cgColor
        }
    }
    @IBInspectable var disableRange:Bool = false {
        didSet {
            if disableRange && showUnselectedArea {
                leftHandle.isHidden = true
                minLabel.isHidden = true
                noRangeUnselectedArea.isHidden = false
                leftUnselectedArea.isHidden = true
                rightUnselectedArea.isHidden = true
            }else if !disableRange && showUnselectedArea{
                leftUnselectedArea.isHidden = false
                rightUnselectedArea.isHidden = false
                noRangeUnselectedArea.isHidden = true
                leftHandle.isHidden = false
            }
        }
    }
    @IBInspectable var minDistance:CGFloat = -1
    @IBInspectable var maxDistance:CGFloat = -1
    @IBInspectable var enableStep:Bool = false
    @IBInspectable var step:CGFloat = 0.1
    
    
    let HANDLE_TOUCH_AREA_EXPANSION:CGFloat = -30
    let HANDLE_DIAMETER:CGFloat = 20
    let TEXT_HEIGHT:CGFloat = 14
    let kLabelFontSize:CGFloat =  12.0
    
    
    func initialiseControl() {
        sliderLine = CALayer()
        sliderLine.backgroundColor = tintColor.cgColor
        leftUnselectedArea = CALayer()
        rightUnselectedArea = CALayer()
        noRangeUnselectedArea = CALayer()
        layer.addSublayer(sliderLine)
        sliderLine.addSublayer(leftUnselectedArea)
        sliderLine.addSublayer(rightUnselectedArea)
        sliderLine.addSublayer(noRangeUnselectedArea)
        
        leftHandle.cornerRadius = HANDLE_DIAMETER / 2
        leftHandle.backgroundColor  = UIColor.white.cgColor
        leftHandle.borderWidth = 1
        leftHandle.borderColor = UIColor.black.cgColor
        
        layer.addSublayer(leftHandle)
        
        leftUnselectedArea.backgroundColor = UIColor.gray.cgColor
        rightUnselectedArea.backgroundColor = UIColor.gray.cgColor
        noRangeUnselectedArea.backgroundColor = UIColor.gray.cgColor
        rightHandle.cornerRadius = HANDLE_DIAMETER / 2
        rightHandle.backgroundColor  = UIColor.white.cgColor
        rightHandle.borderWidth = 1
        rightHandle.borderColor = UIColor.black.cgColor
        
        layer.addSublayer(rightHandle)
        
        leftHandle.frame = CGRect(x: 0, y: 0, width: HANDLE_DIAMETER, height: HANDLE_DIAMETER)
        rightHandle.frame = CGRect(x: 0, y: 0, width: HANDLE_DIAMETER, height: HANDLE_DIAMETER)
        
        
        
        minLabel = CATextLayer()
        minLabel.alignmentMode = kCAAlignmentCenter
        minLabel.fontSize = kLabelFontSize
        minLabel.frame = CGRect(x: 0, y: 0, width: 75, height: TEXT_HEIGHT)
        minLabel.contentsScale = UIScreen.main.scale
        
        if minLabelColor == nil {
            minLabel.foregroundColor = tintColor.cgColor
        }
        else {
            minLabel.foregroundColor = minLabelColor!.cgColor
        }
        
        
        layer.addSublayer(minLabel)
        
        maxLabel = CATextLayer()
        maxLabel.alignmentMode = kCAAlignmentCenter
        maxLabel.fontSize = kLabelFontSize
        maxLabel.frame = CGRect(x: 0, y: 0, width: 75, height: TEXT_HEIGHT)
        maxLabel.contentsScale = UIScreen.main.scale
        
        if maxLabelColor == nil {
            maxLabel.foregroundColor = tintColor.cgColor
        }
        else {
            maxLabel.foregroundColor = maxLabelColor!.cgColor
        }
        
        layer.addSublayer(maxLabel)
        
        refresh()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let barSidePadding:CGFloat = 16
        let currentFrame = frame
        let yMiddle = currentFrame.size.height/2
        let lineLeftSide = CGPoint(x: barSidePadding, y: yMiddle)
        let lineRightSide = CGPoint(x: currentFrame.size.width-barSidePadding, y: yMiddle)
        sliderLine.frame = CGRect(x: lineLeftSide.x, y: lineLeftSide.y, width: lineRightSide.x-lineLeftSide.x, height: 10)
        sliderLine.masksToBounds = true
        sliderLine.cornerRadius = 5
        updateLabelValues()
        updateHandle()
        updateLabel()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialiseControl()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialiseControl()
    }
    
    override var intrinsicContentSize : CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 65)
    }
    
    func getPercentageAlongLineForValue(_ value:CGFloat) -> CGFloat {
        if minValue == maxValue {
            return 0
        }
        
        let maxMinDif:CGFloat = maxValue - minValue
        let valueSubstracted = value - minValue
        
        return valueSubstracted / maxMinDif
    }
    
    func getXPositionAlongLineForValue(_ value:CGFloat) -> CGFloat {
        let percentage = self.getPercentageAlongLineForValue(value)
        let maxMinDif = sliderLine.frame.maxX - sliderLine.frame.minX
        let offset = percentage * maxMinDif
        return sliderLine.frame.minX + offset
    }
    
    func updateLabelValues() {
        if hideLabels || numberFormatterOverride == nil {
            minLabel.string = ""
            maxLabel.string = ""
            return
        }
        
        //let formatter = numberFormatterOverride != nil ?numberFormatterOverride : decimalNumberFormatter
    
        minLabel.string = selectedMinimum.description
        maxLabel.string = selectedMaximum.description

    }
    
    
    
    func updateHandle() {
        let leftHandleCenter:CGPoint = CGPoint(x: getXPositionAlongLineForValue(selectedMinimum), y: sliderLine.frame.midY)
        leftHandle.position = leftHandleCenter
        
        let rightHandleCenter = CGPoint(x: getXPositionAlongLineForValue(selectedMaximum), y: self.sliderLine.frame.midY)
        rightHandle.position = rightHandleCenter
        
        leftUnselectedArea.frame  = CGRect(x: 0,y: 0,width: leftHandle.frame.minX, height: 10)
        rightUnselectedArea.frame  = CGRect(x: rightHandle.frame.minX,y: 0,width: frame.width - rightHandle.frame.minX , height: 10)
        noRangeUnselectedArea.frame = CGRect(x: rightHandle.frame.minX,y: 0,width: frame.width - rightHandle.frame.minX , height: 10)
    }
    
    func updateLabel() {
        let padding:CGFloat = 8
        let minSpacingBetterrnLabels:CGFloat = 8
        
        let leftHandleCentre:CGPoint = getCentreOfRect(leftHandle.frame)
        var newMinLabelCenter = CGPoint(x: leftHandleCentre.x, y: leftHandle.frame.origin.y - (minLabel.frame.size.height/2) - padding)
        let rightHandleCentre =  getCentreOfRect(self.rightHandle.frame)
        var newMaxLabelCenter = CGPoint(x: rightHandleCentre.x, y: self.rightHandle.frame.origin.y - (self.maxLabel.frame.size.height/2) - padding)
        let minLabelTextSize = minLabel.preferredFrameSize()
        let maxLabelTextSize = maxLabel.preferredFrameSize()



        let newLeftMostXInMaxLabel = newMaxLabelCenter.x - (maxLabelTextSize.width)/2
        let newRightMostXInMinLabel = newMinLabelCenter.x + (minLabelTextSize.width)/2
        let newSpacingBetweenTextLabels = newLeftMostXInMaxLabel - newRightMostXInMinLabel
        
        if disableRange || newSpacingBetweenTextLabels > minSpacingBetterrnLabels {
            minLabel.position = newMinLabelCenter
            maxLabel.position = newMaxLabelCenter
        }else {
            newMinLabelCenter = CGPoint(x: self.minLabel.position.x, y: self.leftHandle.frame.origin.y - (self.minLabel.frame.size.height/2) - padding)
            newMaxLabelCenter = CGPoint(x: self.maxLabel.position.x, y: self.rightHandle.frame.origin.y - (self.maxLabel.frame.size.height/2) - padding)
            self.minLabel.position = newMinLabelCenter
            self.maxLabel.position = newMaxLabelCenter
            
            if minLabel.position.x == maxLabel.position.x  {
                minLabel.position = CGPoint(x: leftHandleCentre.x, y: minLabel.position.y)
                maxLabel.position = CGPoint(x: leftHandleCentre.x + self.minLabel.frame.size.width/2 + minSpacingBetterrnLabels + self.maxLabel.frame.size.width/2, y: self.maxLabel.position.y)
            }
        }
    }
    
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let gesturePressLocation = touch.location(in: self)
        
        if (self.leftHandle.frame.insetBy(dx: HANDLE_TOUCH_AREA_EXPANSION, dy: HANDLE_TOUCH_AREA_EXPANSION).contains(gesturePressLocation) || self.rightHandle.frame.insetBy(dx: HANDLE_TOUCH_AREA_EXPANSION, dy: HANDLE_TOUCH_AREA_EXPANSION).contains(gesturePressLocation))
        {
            let distanceFromLeftHandle = distanceBetweenPoint(gesturePressLocation, andPoint: getCentreOfRect(leftHandle.frame))
            let distanceFromRightHandle = distanceBetweenPoint(gesturePressLocation, andPoint: getCentreOfRect(rightHandle.frame))
            
            if distanceFromLeftHandle < distanceFromRightHandle && !disableRange {
                leftHandleSelected = true
                animateHandle(leftHandle, withSelection: true)
            }else {
                if selectedMaximum == maxValue && getCentreOfRect(leftHandle.frame).x == getCentreOfRect(rightHandle.frame).x {
                    leftHandleSelected = true
                    animateHandle(leftHandle, withSelection: true)
                }
                else {
                    rightHandleSelected = true
                    animateHandle(rightHandle, withSelection: true)
                }
            }
            
            delegate?.didStartTouchesInRangeSlider?(self)
            return true
            
        }else {
            return false
        }
    }
    
    var didSet = true
    
    func refresh() {
        
        didSet = false
        
        if enableStep && step >= 0 {
            selectedMaximum = CGFloat(roundf(Float( self.selectedMaximum / step))) * step
            selectedMinimum = CGFloat(roundf(Float( self.selectedMinimum / step))) * step
        }
        
        let diff = selectedMaximum - selectedMinimum
        
        if minDistance != -1 && diff < minDistance {
            if leftHandleSelected {
                selectedMinimum = selectedMaximum - minDistance
            }else {
                selectedMaximum = selectedMinimum + minDistance
            }
        }
        else if maxDistance != -1 && diff > maxDistance{
            if leftHandleSelected {
                selectedMinimum = selectedMaximum - maxDistance
            }else if rightHandleSelected {
                selectedMaximum = selectedMinimum + maxDistance
            }
        }
        
        if selectedMinimum <= minValue {
            selectedMinimum = minValue
        }
        
        if selectedMaximum >= maxValue {
            selectedMaximum = maxValue
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        updateHandle()
        updateLabel()
        CATransaction.commit()
        updateLabelValues()
        
        
        delegate?.rangeSlider?(self, didChangeSelectedMinimumValue: selectedMinimum, andMaximumValue: selectedMaximum)
        
        didSet = true
    }
    
    
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        
        let percentage = ((location.x-self.sliderLine.frame.minX) - HANDLE_DIAMETER/2) / (self.sliderLine.frame.maxX - self.sliderLine.frame.minX)
        
        let selectedValue = percentage * (self.maxValue - self.minValue) + self.minValue
        
        if leftHandleSelected
        {
            if (selectedValue < self.selectedMaximum){
                self.selectedMinimum = selectedValue;
            }
            else {
                self.selectedMinimum = self.selectedMaximum;
            }
            
        }
        else if (self.rightHandleSelected)
        {
            if (selectedValue > self.selectedMinimum || (self.disableRange && selectedValue >= self.minValue)){ //don't let the dots cross over, (unless range is disabled, in which case just dont let the dot fall off the end of the screen)
                self.selectedMaximum = selectedValue;
            }
            else {
                self.selectedMaximum = self.selectedMinimum;
            }
        }
        
        
        return true
        
    }
    
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        if (self.leftHandleSelected){
            self.leftHandleSelected = false
            animateHandle(leftHandle, withSelection: false)
        } else {
            self.rightHandleSelected = false
            animateHandle(rightHandle, withSelection: false)
        }
    }
    
    
    func animateHandle(_ handle:CALayer, withSelection selected:Bool) {
        if selected {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.3)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
            handle.transform = CATransform3DMakeScale(1.7, 1.7, 1)
            
            updateLabel()
            CATransaction.commit()
            
            
        }
        else {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.3)
            
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
            handle.transform = CATransform3DIdentity
            updateLabel()
            CATransaction.commit()
        }
    }
    
    func distanceBetweenPoint(_ point1:CGPoint, andPoint point2:CGPoint) -> CGFloat {
        let xDist = point2.x - point1.x
        let yDist = point2.y - point1.y
        
        return sqrt((xDist * xDist) + (yDist * yDist))
    }
    
    func getCentreOfRect(_ rect:CGRect) -> CGPoint {
        return CGPoint(x: rect.midX, y: rect.midY)
    }
    
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        
        let color = tintColor.cgColor
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.5)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        self.sliderLine.backgroundColor = color;
        self.leftHandle.backgroundColor = color;
        self.rightHandle.backgroundColor = color;
        
        if (self.minLabelColor == nil){
            self.minLabel.foregroundColor = color;
        }
        if (self.maxLabelColor == nil){
            self.maxLabel.foregroundColor = color;
        }
        CATransaction.commit()
    }
    
    
    
    
    
    
    
    
    
    
    
    
}
