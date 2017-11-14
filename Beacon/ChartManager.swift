//
//  SubLineChartView.swift
//  Hal
//
//  Created by Thibault Imbert on 7/24/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation
import Charts

class ChartManager: EventDispatcher, ChartViewDelegate
{
    
    private let chart: LineChartView
    private var hours: [String] = []
    private var chartData: LineChartData!
    private var highColor: UIColor = UIColor(red: 246/255, green: 188/255, blue: 11/255, alpha: 1.0)
    private var averageColor: UIColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1.0)
    private var normalColor: UIColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    private var lowColor: UIColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
    private var inited: DarwinBoolean = false
    private var zoomed: DarwinBoolean = false
    
    public static var HIGH_LIMIT:Double = 150
    public static var LOW_LIMIT:Double = 70
    
    private var lowLimitLine = ChartLimitLine(limit: Double(ChartManager.LOW_LIMIT))
    private var highLimitLine = ChartLimitLine(limit: Double(ChartManager.HIGH_LIMIT))
    private var averageLimitLine = ChartLimitLine(limit: Double(0))
    
    public var selectedSample: GlucoseSample!
    public var position: Int!
    public var samples: [GlucoseSample]!
    public var curvature: Double!
    public var average: Double!
    private var parent: ViewController!
    
    init (parent: ViewController, lineChart: LineChartView)
    {
        self.parent = parent
        chart = lineChart
        chart.delegate = self as ChartViewDelegate
        chart.backgroundColor = .clear
        
        highLimitLine.lineColor = highColor
        lowLimitLine.lineColor = lowColor
        
        averageLimitLine.lineColor = averageColor
        averageLimitLine.lineDashLengths = [0.9]
        averageLimitLine.lineDashPhase = 0.9
        
        chart.rightAxis.addLimitLine(lowLimitLine)
        chart.rightAxis.addLimitLine(highLimitLine)
        chart.rightAxis.addLimitLine(averageLimitLine)
        
        chart.xAxis.granularity = 1
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.labelTextColor = UIColor.white
        chart.rightAxis.labelTextColor = UIColor.white
        
        chart.xAxis.drawGridLinesEnabled = false
        chart.rightAxis.drawGridLinesEnabled = false
        chart.leftAxis.drawGridLinesEnabled = false
        chart.leftAxis.drawLabelsEnabled = false
        chart.leftAxis.enabled = false
        chart.rightAxis.drawAxisLineEnabled = false
        chart.legend.enabled = false
        chart.chartDescription?.enabled = false
        chart.doubleTapToZoomEnabled = false
        chart.xAxis.axisMinimum = 5.5
    }
    
    public func setData(data: [GlucoseSample], average: Double)
    {
        self.average = average
        samples = data.reversed()
        hours.removeAll()
        
        averageLimitLine.limit = average
        
        var lineDataEntry: [ChartDataEntry] = [ChartDataEntry]()
        
        var dx_dt: [Double] = []
        var dy_dt: [Double] = []
        
        var circleColors: [NSUIColor] = []
        
        var i: Int = 0
        for sample in samples {
            let sugarLevel = ChartDataEntry(x: Double(i), y: Double(sample.value))
            dx_dt.append(sugarLevel.x)
            dy_dt.append(sugarLevel.y)
            hours.append(sample.time)
            //let (_, _, hour) = Utils.getDate(unixdate: sample.time, format: "hh:mm a")
            lineDataEntry.append (sugarLevel)
            var color: UIColor
            if (sugarLevel.y > ChartManager.HIGH_LIMIT) {
                color = highColor
            } else if ( sugarLevel.y <= ChartManager.HIGH_LIMIT && sugarLevel.y >= ChartManager.LOW_LIMIT) {
                color = normalColor
            } else { color = lowColor }
            circleColors.append(color)
            i = i + 1
        }
        
        /*
        var step: Int = samples.count / 5
        for var index in 1...5 {
            let inc: Int = index * step
            let time: String = samples[inc-1].time
            hours.append(time)
            print ( index * step )
        }*/
        
        curvature = Math.curvature(x: dx_dt, y: dy_dt)
    
        let chartDataSet = LineChartDataSet(values: lineDataEntry, label: "Time")
        chartDataSet.colors = circleColors
        chartDataSet.circleColors = circleColors
        chartDataSet.drawValuesEnabled = false
        chartDataSet.circleRadius = 1.0
        
        let gradientColors = [UIColor.red.cgColor, UIColor.clear.cgColor] as CFArray
        let colorLocations: [CGFloat] = [1.0, 0.0]
        guard let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations) else { print ("gradient error"); return }
        
        chartDataSet.fill = Fill.fillWithLinearGradient(gradient, angle: 90.0)
        chartDataSet.drawFilledEnabled = true
        
        chartData = LineChartData()
        chartData.addDataSet(chartDataSet)
        chart.data = chartData
        
        if ( !inited.boolValue ){
            chart.animate(xAxisDuration: 1.0, yAxisDuration: 1.0, easingOption: .easeInOutQuart)
            inited = true;
        }
        
        chart.xAxis.valueFormatter = IndexAxisValueFormatter(values:hours)
     
        if (zoomed.boolValue)
        {
            recentView()
        } else {
            fulltimeView()
        }
        
        position = Int((lineDataEntry.last?.x)!)
        selectedSample = samples.last
        chart.highlightValue(x: (lineDataEntry.last?.x)!, y: (lineDataEntry.last?.y)!, dataSetIndex: 0)
    }
    
    internal func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight)
    {
        position = Int(entry.x)
        selectedSample = samples[position]
        dispatchEvent(event: Event(type: EventType.selection, target: self))
    }
    
    public func fulltimeView()
    {
        zoomed = false
        chart.zoom(scaleX: 0, scaleY: 0, x: 0, y: 0)
    }
    
    public func recentView()
    {
        if ( zoomed.boolValue == false ) {
            let xScale: CGFloat = 288 / 38
            chart.zoom(scaleX: xScale, scaleY: 0.0, x: 0.0, y: 0.0)
            chart.moveViewToX(288 - 38)
        }
        zoomed = true
    }
}
