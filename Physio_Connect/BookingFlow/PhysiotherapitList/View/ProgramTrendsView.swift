//
//  ProgramTrendsView.swift
//  Physio_Connect
//
//  Created by user@8 on 03/01/26.
//

import UIKit

final class ProgramTrendsView: UIView {

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let legendStack = UIStackView()
    private let painLegend = LegendDotView(text: "Pain Level", color: UIColor(hex: "F97316"))
    private let adherenceLegend = LegendDotView(text: "Adherence", color: UIColor(hex: "3B82F6"))

    private let chartView = TrendChartView()
    private let highlightCard = UIView()
    private let highlightIcon = UIImageView()
    private let highlightTitle = UILabel()
    private let highlightSub = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(painSeries: [Int], adherenceSeries: [Int], highlightText: String) {
        chartView.setData(pain: painSeries, adherence: adherenceSeries)
        highlightSub.text = highlightText
    }

    private func build() {
        backgroundColor = .white
        layer.cornerRadius = 22
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 8)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.text = "Pain & Progress Trends"

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = UIColor.black.withAlphaComponent(0.55)
        subtitleLabel.text = "Your recovery is trending positively"

        legendStack.translatesAutoresizingMaskIntoConstraints = false
        legendStack.axis = .horizontal
        legendStack.spacing = 16
        legendStack.addArrangedSubview(painLegend)
        legendStack.addArrangedSubview(adherenceLegend)

        chartView.translatesAutoresizingMaskIntoConstraints = false

        highlightCard.translatesAutoresizingMaskIntoConstraints = false
        highlightCard.backgroundColor = UIColor(hex: "E8FFF1")
        highlightCard.layer.cornerRadius = 16

        highlightIcon.translatesAutoresizingMaskIntoConstraints = false
        highlightIcon.image = UIImage(systemName: "chart.line.uptrend.xyaxis")
        highlightIcon.tintColor = UIColor.white
        highlightIcon.backgroundColor = UIColor(hex: "16A34A")
        highlightIcon.layer.cornerRadius = 18
        highlightIcon.layer.masksToBounds = true

        highlightTitle.translatesAutoresizingMaskIntoConstraints = false
        highlightTitle.font = .systemFont(ofSize: 14, weight: .bold)
        highlightTitle.textColor = UIColor(hex: "14532D")
        highlightTitle.text = "Great Progress!"

        highlightSub.translatesAutoresizingMaskIntoConstraints = false
        highlightSub.font = .systemFont(ofSize: 12, weight: .regular)
        highlightSub.textColor = UIColor(hex: "166534")
        highlightSub.numberOfLines = 0

        highlightCard.addSubview(highlightIcon)
        highlightCard.addSubview(highlightTitle)
        highlightCard.addSubview(highlightSub)

        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(legendStack)
        addSubview(chartView)
        addSubview(highlightCard)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            legendStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
            legendStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            chartView.topAnchor.constraint(equalTo: legendStack.bottomAnchor, constant: 12),
            chartView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            chartView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            chartView.heightAnchor.constraint(equalToConstant: 180),

            highlightCard.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 16),
            highlightCard.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            highlightCard.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            highlightCard.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),

            highlightIcon.leadingAnchor.constraint(equalTo: highlightCard.leadingAnchor, constant: 12),
            highlightIcon.topAnchor.constraint(equalTo: highlightCard.topAnchor, constant: 12),
            highlightIcon.widthAnchor.constraint(equalToConstant: 36),
            highlightIcon.heightAnchor.constraint(equalToConstant: 36),

            highlightTitle.topAnchor.constraint(equalTo: highlightCard.topAnchor, constant: 12),
            highlightTitle.leadingAnchor.constraint(equalTo: highlightIcon.trailingAnchor, constant: 10),
            highlightTitle.trailingAnchor.constraint(equalTo: highlightCard.trailingAnchor, constant: -12),

            highlightSub.topAnchor.constraint(equalTo: highlightTitle.bottomAnchor, constant: 4),
            highlightSub.leadingAnchor.constraint(equalTo: highlightTitle.leadingAnchor),
            highlightSub.trailingAnchor.constraint(equalTo: highlightTitle.trailingAnchor),
            highlightSub.bottomAnchor.constraint(equalTo: highlightCard.bottomAnchor, constant: -12)
        ])
    }
}

private final class LegendDotView: UIView {
    private let dot = UIView()
    private let label = UILabel()

    init(text: String, color: UIColor) {
        super.init(frame: .zero)
        label.text = text
        dot.backgroundColor = color
        build()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func build() {
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.layer.cornerRadius = 5
        dot.layer.masksToBounds = true

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = UIColor.black.withAlphaComponent(0.7)

        addSubview(dot)
        addSubview(label)

        NSLayoutConstraint.activate([
            dot.leadingAnchor.constraint(equalTo: leadingAnchor),
            dot.centerYAnchor.constraint(equalTo: centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 10),
            dot.heightAnchor.constraint(equalToConstant: 10),

            label.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

private final class TrendChartView: UIView {

    private var pain: [Int] = [6, 5, 4, 5, 3, 3, 2]
    private var adherence: [Int] = [90, 80, 95, 70, 100, 85, 92]

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setData(pain: [Int], adherence: [Int]) {
        if pain.count == 7 { self.pain = pain }
        if adherence.count == 7 { self.adherence = adherence }
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let inset: CGFloat = 16
        let chartRect = rect.insetBy(dx: inset, dy: inset)

        let bgPath = UIBezierPath(roundedRect: chartRect, cornerRadius: 14)
        UIColor.white.setFill()
        bgPath.fill()

        ctx.setStrokeColor(UIColor.black.withAlphaComponent(0.06).cgColor)
        ctx.setLineWidth(1)
        for i in 0..<4 {
            let y = chartRect.minY + (CGFloat(i) * chartRect.height / 3)
            ctx.move(to: CGPoint(x: chartRect.minX, y: y))
            ctx.addLine(to: CGPoint(x: chartRect.maxX, y: y))
        }
        ctx.strokePath()

        drawLine(series: adherence, minValue: 0, maxValue: 100, color: UIColor(hex: "3B82F6"), fillAlpha: 0.15, in: chartRect)
        drawLine(series: pain, minValue: 0, maxValue: 10, color: UIColor(hex: "F97316"), fillAlpha: 0.12, in: chartRect)
    }

    private func drawLine(series: [Int],
                          minValue: Int,
                          maxValue: Int,
                          color: UIColor,
                          fillAlpha: CGFloat,
                          in rect: CGRect) {
        guard series.count == 7 else { return }
        let stepX = rect.width / 6
        let range = maxValue - minValue
        let points: [CGPoint] = series.enumerated().map { index, value in
            let normalized = CGFloat(value - minValue) / CGFloat(max(range, 1))
            let x = rect.minX + (CGFloat(index) * stepX)
            let y = rect.maxY - (normalized * rect.height)
            return CGPoint(x: x, y: y)
        }

        let path = UIBezierPath()
        path.move(to: points[0])
        for i in 1..<points.count {
            let prev = points[i - 1]
            let current = points[i]
            let mid = CGPoint(x: (prev.x + current.x) / 2, y: (prev.y + current.y) / 2)
            path.addQuadCurve(to: mid, controlPoint: prev)
            if i == points.count - 1 {
                path.addQuadCurve(to: current, controlPoint: current)
            }
        }

        let fillPath = path.copy() as! UIBezierPath
        fillPath.addLine(to: CGPoint(x: points.last!.x, y: rect.maxY))
        fillPath.addLine(to: CGPoint(x: points.first!.x, y: rect.maxY))
        fillPath.close()
        color.withAlphaComponent(fillAlpha).setFill()
        fillPath.fill()

        color.setStroke()
        path.lineWidth = 2.5
        path.lineCapStyle = .round
        path.stroke()

        for point in points {
            let dot = UIBezierPath(ovalIn: CGRect(x: point.x - 3.5, y: point.y - 3.5, width: 7, height: 7))
            color.setFill()
            dot.fill()
        }
    }
}
