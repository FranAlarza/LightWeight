import Charts
import SwiftUI

struct ProgressChartView: View {
    let points: [ChartPoint]
    let dateDomain: ClosedRange<Date>
    let valueDomain: ClosedRange<Double>
    let metric: ProgressMetric
    let unit: WeightUnit

    @State private var selectedDate: Date?

    var body: some View {
        if points.isEmpty {
            ContentUnavailableView(
                "Sin datos en este periodo",
                systemImage: "chart.xyaxis.line",
                description: Text("Prueba con un rango más amplio.")
            )
            .frame(height: 220)
        } else {
            chart
        }
    }

    private var chart: some View {
        Chart {
            ForEach(points) { point in
                LineMark(
                    x: .value("Fecha", point.date, unit: .day),
                    y: .value(metric.title, point.value)
                )
                .interpolationMethod(.monotone)
                PointMark(
                    x: .value("Fecha", point.date, unit: .day),
                    y: .value(metric.title, point.value)
                )
                .symbolSize(30)
            }
            if let selected = selectedPoint {
                RuleMark(x: .value("Fecha", selected.date, unit: .day))
                    .foregroundStyle(.secondary.opacity(0.4))
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        SelectionCallout(point: selected, unit: unit)
                    }
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartXScale(domain: dateDomain, range: .plotDimension(startPadding: 8, endPadding: 24))
        .chartYScale(domain: valueDomain)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month(.abbreviated), anchor: .top)
            }
        }
        .chartYAxisLabel(unit.symbol)
        .frame(height: 220)
        .accessibilityLabel("Gráfica de \(metric.title)")
    }

    private var selectedPoint: ChartPoint? {
        guard let selectedDate else { return nil }
        return points.min {
            abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
        }
    }
}

private struct SelectionCallout: View {
    let point: ChartPoint
    let unit: WeightUnit

    var body: some View {
        VStack(spacing: 2) {
            Text(unit.formatted(point.value))
                .font(.headline.monospacedDigit())
            Text(point.date.formatted(.dateTime.day().month().year()))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(.regularMaterial, in: .rect(cornerRadius: 8))
    }
}

#Preview {
    let points = (0..<10).map { index in
        ChartPoint(date: .now.addingTimeInterval(Double(index) * -86_400 * 4), value: 80 - Double(index) * 1.5)
    }
    ProgressChartView(
        points: points.reversed(),
        dateDomain: points.last!.date...Date.now,
        valueDomain: 60...85,
        metric: .maxWeight,
        unit: .kilograms
    )
        .padding()
}
