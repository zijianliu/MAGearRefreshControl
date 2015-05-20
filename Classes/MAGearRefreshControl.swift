//
//  MAGearRefreshControl.swift
//
//  Created by Michaël Azevedo on 20/05/2015.
//  Copyright (c) 2015 micazeve. All rights reserved.
//

import UIKit




///MARK: - MAGearRefreshDelegate protocol


/// Protocol between the MAGearRefreshControl and its delegate (mostly UITableViewController).
@objc protocol MAGearRefreshDelegate {
    
    /// Method called when the pull to refresh move was triggered.
    ///
    /// :param: view The MAGearRefreshControl object.
    func MAGearRefreshTableHeaderDidTriggerRefresh(view:MAGearRefreshControl)
    
    /// Method called to know if the data source is loading or no
    ///
    /// :param: view The MAGearRefreshControl object.
    ///
    /// :returns: true if the datasource is loading, false otherwise
    func MAGearRefreshTableHeaderDataSourceIsLoading(view:MAGearRefreshControl) -> Bool
}



/// Multiplicator factor in order to draw the gear correctly. Was set arbitrarily and can be changed.
let multRadius:UInt = 80


//MARK: - MAGear Class

/// This class represents a gear in the most abstract way, without any graphical code related.
class MAGear {
    
    //MARK: Instance properties
    
    /// The circle on which two gears effectively mesh, about halfway through the tooth.
    let pitchDiameter:CGFloat
    
    /// Diameter of the gear, measured from the tops of the teeth.
    let outsideDiameter:CGFloat
    
    /// Diameter of the gear, measured at the base of the teeth.
    let insideDiameter:CGFloat
    
    /// The number of teeth per inch of the circumference of the pitch diameter. The diametral pitch of all meshing gears must be the same.
    let diametralPitch:UInt
    
    /// Number of teeth of the gear.
    let nbTeeth:UInt
    
    
    //MARK: Init method
    
    /// Init method.
    ///
    /// :param: diametralPitch Diametral pitch of the group of gears
    /// :param: nbTeeth Number of teeth of the gear. Must be greater than 2.
    init (diametralPitch:UInt, nbTeeth:UInt) {
        
        assert(nbTeeth > 2)
        
        self.diametralPitch = diametralPitch
        self.pitchDiameter = CGFloat(multRadius*nbTeeth)/CGFloat(diametralPitch)
        self.outsideDiameter = CGFloat(multRadius*(nbTeeth+2))/CGFloat(diametralPitch)
        self.insideDiameter = CGFloat(multRadius*(nbTeeth-2))/CGFloat(diametralPitch)
        self.nbTeeth = nbTeeth
    }
}

//MARK: - MASingleGearView Class

/// This class is used to draw a gear in a UIView.
class MASingleGearView : UIView {
    
    //MARK: Instance properties
    
    /// Gear linked to this view.
    private var gear:MAGear!
    
    /// Color of the gear.
    var gearColor = UIColor.blackColor()
    
    /// Phase of the gear. Varies between 0 and 1.
    /// A phase of 0 represents a gear with the rightmost tooth fully horizontal, while a phase of 0.5 represents a gear with a hole in the rightmost point.
    /// A phase of 1 thus is graphically equivalent to a phase of 0
    var phase:Double = 0
    
    //MARK: Init methods
    
    /// Custom init method
    ///
    /// :param: gear Gear linked to this view
    /// :param: gearColor Color of the gear
    init(gear:MAGear, gearColor:UIColor) {
        
        var width = Int(gear.outsideDiameter + 1)
        if width%2 == 1 {
            width++
        }
        
        super.init(frame: CGRectMake(0, 0, CGFloat(width), CGFloat(width)))
        
        self.backgroundColor = UIColor.clearColor()
        self.gearColor = gearColor
        self.gear = gear
    }
    
    /// Required initializer
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Drawing methods
    
    /// Override of drawing method
    override func drawRect(rect: CGRect) {
        let baseSpace = CGColorSpaceCreateDeviceRGB()
        let currentContext = UIGraphicsGetCurrentContext()
        CGContextClearRect(currentContext, rect)
        
        let pitchRadius = gear.pitchDiameter/2
        let outsideRadius = gear.outsideDiameter/2
        let insideRadius = gear.insideDiameter/2
        
        CGContextSaveGState(currentContext)
        CGContextTranslateCTM(currentContext, rect.width/2, rect.height/2)
        CGContextAddEllipseInRect(currentContext, CGRectMake(-insideRadius/3, -insideRadius/3, insideRadius*2/3, insideRadius*2/3));
        CGContextAddEllipseInRect(currentContext, CGRectMake(-insideRadius, -insideRadius, insideRadius*2, insideRadius*2));
        CGContextSetFillColorWithColor(currentContext, self.gearColor.CGColor)
        CGContextEOFillPath(currentContext)
        
        let angleUtile =  CGFloat(M_PI / (2 * Double(gear.nbTeeth)))
        let angleUtileDemi = angleUtile/2
        
        // In order to draw the teeth quite easily, instead of having complexs calculations,
        // we calcule the needed point for drawing the rightmost horizontal tooth and will rotate the context
        // in order to use the same points
        
        let pointPitchHaut = CGPointMake(cos(angleUtile) * pitchRadius, sin(angleUtile) * pitchRadius)
        let pointPitchBas = CGPointMake(cos(angleUtile) * pitchRadius, -sin(angleUtile) * pitchRadius)
        
        let pointInsideHaut = CGPointMake(cos(angleUtile) * insideRadius, sin(angleUtile) * insideRadius)
        let pointInsideBas = CGPointMake(cos(angleUtile) * insideRadius, -sin(angleUtile) * insideRadius)
        
        let pointOutsideHaut = CGPointMake(cos(angleUtileDemi) * outsideRadius, sin(angleUtileDemi) * outsideRadius)
        let pointOutsideBas = CGPointMake(cos(angleUtileDemi) * outsideRadius, -sin(angleUtileDemi) * outsideRadius)
        
        
        for i in 0..<gear.nbTeeth {
            
            // Saving the context before rotating it
            CGContextSaveGState(currentContext)
            
            let gearOriginAngle =  CGFloat((Double(i)) * M_PI * 2 / Double(gear.nbTeeth))
            
            CGContextRotateCTM(currentContext, gearOriginAngle)
            
            // Drawing the tooth
            CGContextMoveToPoint(currentContext, pointInsideHaut.x, pointInsideHaut.y)
            CGContextAddLineToPoint(currentContext, pointPitchHaut.x, pointPitchHaut.y)
            CGContextAddLineToPoint(currentContext, pointOutsideHaut.x, pointOutsideHaut.y)
            CGContextAddLineToPoint(currentContext, pointOutsideBas.x, pointOutsideBas.y)
            CGContextAddLineToPoint(currentContext, pointPitchBas.x, pointPitchBas.y)
            CGContextAddLineToPoint(currentContext, pointInsideBas.x, pointInsideBas.y)
            CGContextFillPath(currentContext)
        
            // Restoring the context
            CGContextRestoreGState(currentContext)
        }
        
        CGContextRestoreGState(currentContext)
    }
    
}

//MARK: - MAMultiGearView Class

/// This class is used to draw multiples gears in a UIView.
class MAMultiGearView : UIView {
    
    //MARK: Instance properties
    
    /// Left border of the view.
    private var leftBorderView:UIView = UIView()
    
    /// Right border of the view.
    private var rightBorderView:UIView = UIView()
    
    /// Margin between the bars and the border of the screen.
    var barMargin:CGFloat   = 10
    
    /// Width of the bars
    var barWidth:CGFloat    = 20
    
    /// Boolean used to display or hide the side bars.
    var showBars = true {
        didSet {
            leftBorderView.hidden   = !showBars
            rightBorderView.hidden  = !showBars
        }
    }
    
    /// Diametral pitch of the group of gear
    private var diametralPitch:UInt = 24
    
    /// Array of views of gear
    private var arrayViews:[MASingleGearView] = []
    
    /// Relations between the gears.
    /// Ex.  arrayRelations[3] = 2   ->    the 3rd gear is linked to the 2nd one.
    private var arrayRelations:[Int] = [0]
    
    /// Angles between the gears, in degree, according to the unit circle
    /// Ex.  arrayAngles[3] ->   the angle between the 3rd gear and its linked one
    private var arrayAngles:[Double] = [0]
    
 
    //MARK: Init methods
    
    /// Default initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
    
        clipsToBounds = true
        
        leftBorderView = UIView(frame:CGRectMake(barMargin, 0, barWidth, frame.height))
        leftBorderView.backgroundColor = UIColor.initRGB(92, g: 133, b: 236)
        
        
        rightBorderView = UIView(frame:CGRectMake(frame.width - barMargin - barWidth, 0, barWidth, frame.height))
        rightBorderView.backgroundColor = UIColor.initRGB(92, g: 133, b: 236)
        
        
        addSubview(leftBorderView)
        addSubview(rightBorderView)
    }
    
    /// Required initializer
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK: Method to add gears
    
    /// Add the initial gear to the view. It is always centered in the view.
    ///
    /// :param: nbTeeth Number of teeth of the gear.
    /// :param: color Color of the gear.
    ///
    /// :returns: true if the gear was succesfully created, false otherwise (if at least one gear exists).
    func addInitialGear(#nbTeeth:UInt, color: UIColor) -> Bool {
        
        if arrayViews.count > 0  {
            return false
        }
        
        let gear = MAGear(diametralPitch: diametralPitch, nbTeeth: nbTeeth)
        
        let view = MASingleGearView(gear: gear, gearColor:color)
        view.phase = 0
        
        view.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2)
        
        arrayViews.append(view)
        self.insertSubview(view, belowSubview: leftBorderView)
        
        return true
    }
    /// Add another gear to the view and link it to another already existing gear
    ///
    /// :param: gearLinked Index of the previously created gear
    /// :param: nbTeeth Number of teeth of the gear.
    /// :param: color Color of the gear.
    /// :param: angleInDegree Angle (in degree) between the gear to create and the previous gear, according to the unit circle.
    ///
    /// :returns: true if the gear was succesfully created, false otherwise (if the gearLinked index is incorrect).
    func addLinkedGear(gearLinked: Int, nbTeeth:UInt, color:UIColor, angleInDegree:Double) -> Bool {

        if gearLinked >= arrayViews.count || gearLinked < 0 {
            return false
        }
        
        let linkedGearView      = arrayViews[gearLinked]
        let linkedGear          = linkedGearView.gear
        
        let gear = MAGear(diametralPitch: diametralPitch, nbTeeth: nbTeeth)
        
        let dist = Double(gear.pitchDiameter + linkedGear.pitchDiameter)/2
        
        let xValue = CGFloat(dist*cos(angleInDegree*M_PI/180))
        let yValue = CGFloat(-dist*sin(angleInDegree*M_PI/180))
        
        
        var angleBetweenMainTeethsInDegree = 360/Double(linkedGear.nbTeeth)
        
        var nbDentsPassees = angleInDegree / angleBetweenMainTeethsInDegree
        var phaseForAngle = nbDentsPassees -  Double(Int(nbDentsPassees))
        
        
        var phaseNewGearForAngle = 0.5 + phaseForAngle - linkedGearView.phase
        if gear.nbTeeth%2 == 1 {
            phaseNewGearForAngle += 0.5
        }
        phaseNewGearForAngle = phaseNewGearForAngle - trunc(phaseNewGearForAngle)
        
        var angleBetweenNewTeethsInDegree = 360/Double(gear.nbTeeth)
        var nbNewDentsPassees = angleInDegree / angleBetweenNewTeethsInDegree
        var phaseForNewAngle = 1-(nbNewDentsPassees -  Double(Int(nbNewDentsPassees)))
    
        
        let view = MASingleGearView(gear: gear, gearColor:color)
        view.center = CGPointMake(linkedGearView.center.x + xValue, linkedGearView.center.y + yValue)
        
        arrayRelations.append(gearLinked)
        arrayAngles.append(angleInDegree)
        view.phase = phaseNewGearForAngle - phaseForNewAngle
        
        arrayViews.append(view)
        self.insertSubview(view, belowSubview: leftBorderView)
        return true
    }
    
    
    /// Set the phase for the first gear and calculate it for all the linked gears
    ///
    /// :param: phase Phase between 0 and 1 for the first gear.
    func setMainGearPhase(phase:Double) {
        if arrayViews.count == 0  {
            return
        }
        
        var newPhase = phase
        if newPhase >= 1 {
            newPhase = 0
        } else if newPhase < 0 {
            newPhase = 0
        }
        
        arrayViews[0].phase = newPhase
        
        for i in 1..<arrayViews.count {
            
            let gearView = arrayViews[i]
            
            
            let gear                = gearView.gear
            let linkedGearView      = arrayViews[arrayRelations[i]]
            let linkedGear          = linkedGearView.gear
            
            
            let angleInDegree = arrayAngles[i]
            
            let angleBetweenMainTeethsInDegree = 360/Double(linkedGear.nbTeeth)
            
            let nbDentsPassees = angleInDegree / angleBetweenMainTeethsInDegree
            var phaseForAngle = nbDentsPassees -  Double(Int(nbDentsPassees))
            
            var phaseNewGearForAngle = 0.5 + phaseForAngle - linkedGearView.phase
            if gear.nbTeeth%2 == 1 {
                phaseNewGearForAngle += 0.5
            }
            phaseNewGearForAngle = phaseNewGearForAngle - trunc(phaseNewGearForAngle)
            
            var angleBetweenNewTeethsInDegree = 360/Double(gear.nbTeeth)
            
            var nbNewDentsPassees = angleInDegree / angleBetweenNewTeethsInDegree
            var phaseForNewAngle = 1-(nbNewDentsPassees -  Double(Int(nbNewDentsPassees)))
            
            
            let finalPhase = phaseNewGearForAngle - phaseForNewAngle
            
            arrayViews[i].phase  = finalPhase
            
            
        }
        for view in arrayViews {
            
            let angleInRad = -view.phase * 2 * M_PI / Double(view.gear.nbTeeth)
            view.transform = CGAffineTransformMakeRotation(CGFloat(angleInRad))
            
        }
    }
    
    //MARK: View configuration
    
    /// Method used to reset the position of all the gear according to the view frame. Is used principally when the frame is changed
    private func configureView()
    {
        if arrayViews.count == 0 {
            return
        }
        
        arrayViews[0].center.x = frame.size.width/2
        arrayViews[0].center.y = frame.height/2
        
        
        for i in 1..<arrayViews.count {
            
            let angleBetweenGears = arrayAngles[i]
            
            let gearView = arrayViews[i]
            let gear = gearView.gear
            
            
            let linkedGearView      = arrayViews[arrayRelations[i]]
            let linkedGear          = linkedGearView.gear
            let dist = Double(gear.pitchDiameter + linkedGear.pitchDiameter)/2
            let xValue = CGFloat(dist*cos(angleBetweenGears*M_PI/180))
            let yValue = CGFloat(-dist*sin(angleBetweenGears*M_PI/180))
            
            gearView.center = CGPointMake(linkedGearView.center.x + xValue, linkedGearView.center.y + yValue)
            
            arrayViews[i].gear = gear
            
        }
        
        leftBorderView.frame    = CGRectMake(10,  0, barWidth, frame.height)
        rightBorderView.frame   = CGRectMake(frame.size.width - 10 - barWidth, 0, barWidth, frame.height)
        
    }
    
    //MARK: Override setFrame
    
    override var frame:CGRect  {
        didSet {
            configureView()
        }
    }

}

//MARK: - MAGearRefreshControl Class

/// This class is used to draw an animated group of gears and offers the same interactions as an UIRefreshControl
class MAGearRefreshControl: MAMultiGearView {
    
    //MARK: Instance properties
    
    /// Enum representing the different state of the refresh control
    enum MAGearRefreshState: UInt8 {
        case Normal         // The user is pulling but hasn't reach the activation threshold yet
        case Pulling        // The user is still pulling and has passed the activation threshold
        case Loading        // The refresh control is animating
    }
    
    /// State of the refresh control
    private var state = MAGearRefreshState.Normal
    
    /// Delegate conforming to the MAGearRefreshDelegate protocol. Most of time it's an UITableViewController
    var delegate:MAGearRefreshDelegate?
    
    /// Content offset of the tableview
    private var contentOffset:CGFloat = 0
    
    //MARK: Various methods

    /// Set the state of the refresh control.
    ///
    /// :param: aState New state of the refresh control.
    private func setState(aState:MAGearRefreshState) {
        
        switch aState {
            
        case .Pulling:
            break
            
        case .Normal:
            
            if state != .Normal {
                UIView.animateWithDuration(0.5, animations: { () -> Void in
                    for i in 1..<self.arrayViews.count {
                        self.arrayViews[i].alpha = 1
                        
                    } }, completion:nil)
            }
         
            break
            
        case .Loading:
            self.rotate()
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                for i in 1..<self.arrayViews.count {
                    self.arrayViews[i].alpha = 0
                    
                } }, completion:nil)
            break
        default:
            break
        }
        state = aState
    }
    
    /// Method called to rotate the main gear by 360 degree
    private func rotate() {
        
        var rotate = true
        if let rot = delegate?.MAGearRefreshTableHeaderDataSourceIsLoading(self) {
            rotate = rot
        }
        
        if rotate {
            UIView.animateWithDuration(1, delay: 0, options: .CurveLinear, animations: { () -> Void in
                self.arrayViews[0].transform = CGAffineTransformRotate(self.arrayViews[0].transform, CGFloat(M_PI))
                }, completion: { (finished) -> Void in
                    self.rotate()
            })
        }
    }
    
    //MARK: Public methods
    
    /// Method to call when the scrollview was scrolled.
    ///
    /// :param: scrollView The scrollview.
    func MAGearRefreshScrollViewDidScroll(scrollView:UIScrollView) {
        
        configureWithContentOffsetY(-scrollView.contentOffset.y)
        
        if (state == .Loading) {
            
            var offset = max(scrollView.contentOffset.y * -1, 0)
            offset = min(offset, 60)
            scrollView.contentInset = UIEdgeInsetsMake(offset, 0, 0, 0)
            
        } else {
            if (scrollView.dragging) {
                              
                var loading = false
                
                if let load = delegate?.MAGearRefreshTableHeaderDataSourceIsLoading(self) {
                    loading = load
                }
                
                if state == .Pulling && scrollView.contentOffset.y > -65 && scrollView.contentOffset.y < 0 && !loading {
                    setState(.Normal)
                } else if state == .Normal && scrollView.contentOffset.y < -65 && !loading {
                    setState(.Pulling)
                }
                
                
                if (scrollView.contentInset.top != 0) {
                    scrollView.contentInset = UIEdgeInsetsZero;
                }
            }
            var phase = -Double(scrollView.contentOffset.y/20)
            phase -= Double(Int(phase))
            setMainGearPhase(phase)
        }
    }
    
    /// Method to call when the scrollview ended dragging
    ///
    /// :param: scrollView The scrollview.
    func MAGearRefreshScrollViewDidEndDragging(scrollView:UIScrollView) {
        var loading = false
        
        if let load = delegate?.MAGearRefreshTableHeaderDataSourceIsLoading(self) {
            loading = load
        }
        
        if scrollView.contentOffset.y <= -65.0 && !loading {
            
            delegate?.MAGearRefreshTableHeaderDidTriggerRefresh(self)
            
            setState(.Loading)
            
            var contentOffset = scrollView.contentOffset
            
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                scrollView.contentInset = UIEdgeInsetsMake(60, 0, 0, 0)
                scrollView.contentOffset = contentOffset;           // Workaround for smooth transition on iOS8
            })
        }
    }
    
    /// Method to call when the datasource finished loading
    ///
    /// :param: scrollView The scrollview.
    func MAGearRefreshScrollViewDataSourceDidFinishedLoading(scrollView:UIScrollView) {

        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.arrayViews[0].transform = CGAffineTransformMakeScale(1.2, 1.2)
        }) { (finished) -> Void in
            
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.arrayViews[0].transform = CGAffineTransformMakeScale(0.1, 0.1)
                })
            
            UIView.animateWithDuration(0.3, delay: 0.1, options: .CurveLinear, animations: { () -> Void in
                scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
            }, completion: { (finished) -> Void in
                self.setState(.Normal)
            })
        }
    }
    

    //MARK: View configuration
    
    /// Method to configure the view with an Y offset of the scrollview
    ///
    /// :param: offset Offset of the scrollView
    private func configureWithContentOffsetY(offset:CGFloat)
    {
        contentOffset = offset
        configureView()
    }
    
    /// Override of configureView(). The override is needed since we don't want the first gear to be centered within the view.
    /// Instead, we want it to be centered within the visible part of the view
    override private func configureView() {
        if arrayViews.count == 0 {
            return
        }
        
        arrayViews[0].center.x = frame.size.width/2
        arrayViews[0].center.y = frame.height  - contentOffset/2
        
        
        for i in 1..<arrayViews.count {
            
            let angleBetweenGears = arrayAngles[i]
            
            let gearView = arrayViews[i]
            let gear = gearView.gear
            
            
            let linkedGearView      = arrayViews[arrayRelations[i]]
            let linkedGear          = linkedGearView.gear
            let dist = Double(gear.pitchDiameter + linkedGear.pitchDiameter)/2
            let xValue = CGFloat(dist*cos(angleBetweenGears*M_PI/180))
            let yValue = CGFloat(-dist*sin(angleBetweenGears*M_PI/180))
            
            gearView.center = CGPointMake(linkedGearView.center.x + xValue, linkedGearView.center.y + yValue)
            
            arrayViews[i].gear = gear
            
        }
        
        leftBorderView.frame    = CGRectMake(barMargin, frame.height - contentOffset, barWidth, contentOffset)
        rightBorderView.frame   = CGRectMake(frame.size.width - barMargin - barWidth, frame.height - contentOffset, barWidth, contentOffset)
    }
}
