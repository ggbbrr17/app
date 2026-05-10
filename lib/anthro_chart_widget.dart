import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:growth_standards/growth_standards.dart';

class AnthroChartWidget extends StatefulWidget {
  final int ageInMonths;
  final double weightKg;
  final double heightCm;
  final String genderStr;
  final String diagnosis;

  const AnthroChartWidget({
    super.key,
    required this.ageInMonths,
    required this.weightKg,
    required this.heightCm,
    required this.genderStr,
    this.diagnosis = "",
  });

  @override
  State<AnthroChartWidget> createState() => _AnthroChartWidgetState();
}

class _AnthroChartWidgetState extends State<AnthroChartWidget> {
  int _activeTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    Color diagColor = Colors.greenAccent;
    IconData diagIcon = Icons.check_circle_outline;
    if (widget.diagnosis.toLowerCase().contains("desnutrición") || widget.diagnosis.toLowerCase().contains("severa") || widget.diagnosis.toLowerCase().contains("delgadez")) {
      diagColor = Colors.redAccent;
      diagIcon = Icons.warning_amber_rounded;
    } else if (widget.diagnosis.toLowerCase().contains("riesgo") || widget.diagnosis.toLowerCase().contains("moderada") || widget.diagnosis.toLowerCase().contains("sobrepeso")) {
      diagColor = Colors.orangeAccent;
      diagIcon = Icons.error_outline;
    }

    final bmi = widget.weightKg / ((widget.heightCm / 100) * (widget.heightCm / 100));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.diagnosis.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: diagColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: diagColor.withValues(alpha: 0.5), width: 2),
            ),
            child: Row(
              children: [
                Icon(diagIcon, color: diagColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.diagnosis,
                    style: TextStyle(color: diagColor, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
        
        // Tab switcher
        Container(
          height: 36,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              _buildTab(0, "P/E"),
              _buildTab(1, "T/E"),
              _buildTab(2, "IMC/E"),
              _buildTab(3, "P/T"),
            ],
          ),
        ),

        AspectRatio(
          aspectRatio: 1.4,
          child: IndexedStack(
            index: _activeTabIndex,
            children: [
              _buildChart(type: "WFA", xValue: widget.ageInMonths.toDouble(), yValue: widget.weightKg),
              _buildChart(type: "HFA", xValue: widget.ageInMonths.toDouble(), yValue: widget.heightCm),
              _buildChart(type: "BFA", xValue: widget.ageInMonths.toDouble(), yValue: bmi),
              _buildChart(type: "WFH", xValue: widget.heightCm, yValue: widget.weightKg),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index, String label) {
    bool active = _activeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTabIndex = index),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.cyanAccent.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: active ? Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.cyanAccent : Colors.white54,
              fontSize: 10,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChart({required String type, required double xValue, required double yValue}) {
    Sex sex = (widget.genderStr.toLowerCase() == 'm' || widget.genderStr.toLowerCase() == 'masculino' || widget.genderStr.toLowerCase() == 'male')
        ? Sex.male
        : Sex.female;

    List<FlSpot> line0 = [];
    List<FlSpot> line2 = [];
    List<FlSpot> lineMinus2 = [];
    List<FlSpot> line3 = [];
    List<FlSpot> lineMinus3 = [];

    double minX = 0, maxX = 60;
    double minY = 0, maxY = 30;
    String xLabel = "Edad (m)";

    if (type == "WFH") {
       xLabel = "Talla (cm)";
       minX = 45; maxX = 120;
       minY = 2; maxY = 30;
       
       Map<num, dynamic>? wflData = WHOGrowthStandardsWeightForLengthData().data[sex]?.map((k, v) => MapEntry(k, v.lms));
       Map<num, dynamic>? wfhData = WHOGrowthStandardsWeightForHeightData().data[sex]?.map((k, v) => MapEntry(k, v.lms));

       for (double h = minX; h <= maxX; h += 0.5) {
          dynamic lms = h < 85 ? (wflData?[h]) : (wfhData?[h]);
          if (lms != null) {
            line0.add(FlSpot(h, lms.standardDeviation(0).toDouble()));
            line2.add(FlSpot(h, lms.standardDeviation(2).toDouble()));
            lineMinus2.add(FlSpot(h, lms.standardDeviation(-2).toDouble()));
            line3.add(FlSpot(h, lms.standardDeviation(3).toDouble()));
            lineMinus3.add(FlSpot(h, lms.standardDeviation(-3).toDouble()));
          }
       }
    } else {
       maxX = widget.ageInMonths <= 60 ? 60 : (widget.ageInMonths <= 120 ? 120 : widget.ageInMonths.toDouble());
       Map<int, dynamic>? standardData;
       Map<int, dynamic>? referenceData;

       if (type == "WFA") {
         standardData = WHOGrowthStandardsWeightForAgeData().data[sex]?.map((k, v) => MapEntry(k, v.lms));
         referenceData = WHOGrowthReferenceWeightForAgeData().data[sex]?.map((k, v) => MapEntry(k, v.lms));
         minY = 0; maxY = maxX > 60 ? 60 : 30;
       } else if (type == "HFA") {
         standardData = WHOGrowthStandardsLengthForAgeData().data[sex]?.map((k, v) => MapEntry(k, v.lms));
         referenceData = WHOGrowthReferenceHeightForAgeData().data[sex]?.map((k, v) => MapEntry(k, v.lms));
         minY = 40; maxY = maxX > 60 ? 180 : 130;
       } else if (type == "BFA") {
         standardData = WHOGrowthStandardsBodyMassIndexForAgeData().data[sex]?.map((k, v) => MapEntry(k, v.lms));
         referenceData = WHOGrowthReferenceBodyMassIndexForAgeData().data[sex]?.map((k, v) => MapEntry(k, v.lms));
         minY = 10; maxY = 30;
       }

       for (int i = 0; i <= maxX; i++) {
         dynamic lms = i <= 60 ? (standardData?[i]) : (referenceData?[i]);
         if (lms != null) {
           line0.add(FlSpot(i.toDouble(), lms.standardDeviation(0).toDouble()));
           line2.add(FlSpot(i.toDouble(), lms.standardDeviation(2).toDouble()));
           lineMinus2.add(FlSpot(i.toDouble(), lms.standardDeviation(-2).toDouble()));
           line3.add(FlSpot(i.toDouble(), lms.standardDeviation(3).toDouble()));
           lineMinus3.add(FlSpot(i.toDouble(), lms.standardDeviation(-3).toDouble()));
         }
       }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.only(right: 18, top: 18, bottom: 12),
      child: LineChart(
        LineChartData(
          minX: minX, maxX: maxX,
          minY: minY, maxY: maxY,
          gridData: const FlGridData(show: true, drawVerticalLine: true, horizontalInterval: 10, verticalInterval: 12),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (val, meta) => Text("${val.toInt()}", style: const TextStyle(color: Colors.white54, fontSize: 8)),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(color: Colors.white54, fontSize: 8)),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.white10)),
          lineBarsData: [
            LineChartBarData(spots: line3, color: Colors.redAccent.withValues(alpha: 0.5), isCurved: true, dotData: const FlDotData(show: false), barWidth: 1),
            LineChartBarData(spots: line2, color: Colors.orangeAccent.withValues(alpha: 0.5), isCurved: true, dotData: const FlDotData(show: false), barWidth: 1),
            LineChartBarData(spots: line0, color: Colors.greenAccent.withValues(alpha: 0.8), isCurved: true, dotData: const FlDotData(show: false), barWidth: 2),
            LineChartBarData(spots: lineMinus2, color: Colors.orangeAccent.withValues(alpha: 0.5), isCurved: true, dotData: const FlDotData(show: false), barWidth: 1),
            LineChartBarData(spots: lineMinus3, color: Colors.redAccent.withValues(alpha: 0.5), isCurved: true, dotData: const FlDotData(show: false), barWidth: 1),
            LineChartBarData(
              spots: [FlSpot(xValue, yValue)],
              color: Colors.cyanAccent,
              dotData: FlDotData(
                show: true,
                getDotPainter: (s, p, b, i) => FlDotCirclePainter(radius: 4, color: Colors.cyanAccent, strokeWidth: 1, strokeColor: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
