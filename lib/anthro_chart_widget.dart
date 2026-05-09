import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:growth_standards/growth_standards.dart';

class AnthroChartWidget extends StatelessWidget {
  final int ageInMonths;
  final double weightKg;
  final String genderStr;
  final String diagnosis;

  const AnthroChartWidget({
    Key? key,
    required this.ageInMonths,
    required this.weightKg,
    required this.genderStr,
    this.diagnosis = "",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Sex sex = (genderStr.toLowerCase() == 'm' || genderStr.toLowerCase() == 'masculino' || genderStr.toLowerCase() == 'male')
        ? Sex.male
        : Sex.female;

    final maxMonths = ageInMonths <= 60 ? 60 : (ageInMonths <= 120 ? 120 : ageInMonths);

    List<FlSpot> line0 = [];
    List<FlSpot> line2 = [];
    List<FlSpot> lineMinus2 = [];
    List<FlSpot> line3 = [];
    List<FlSpot> lineMinus3 = [];

    final standardData = WHOGrowthStandardsWeightForAgeData().data[sex]!;
    final referenceData = WHOGrowthReferenceWeightForAgeData().data[sex];

    for (int i = 0; i <= maxMonths; i++) {
      num val0 = 0, val2 = 0, valM2 = 0, val3 = 0, valM3 = 0;

      if (i <= 60) {
        if (standardData.containsKey(i)) {
          final lms = standardData[i]!.lms;
          val0 = lms.standardDeviation(0);
          val2 = lms.standardDeviation(2);
          valM2 = lms.standardDeviation(-2);
          val3 = lms.standardDeviation(3);
          valM3 = lms.standardDeviation(-3);
        }
      } else if (referenceData != null && referenceData.containsKey(i)) {
        final lms = referenceData[i]!.lms;
        val0 = lms.standardDeviation(0);
        val2 = lms.standardDeviation(2);
        valM2 = lms.standardDeviation(-2);
        val3 = lms.standardDeviation(3);
        valM3 = lms.standardDeviation(-3);
      }

      if (val0 > 0) {
        line0.add(FlSpot(i.toDouble(), val0.toDouble()));
        line2.add(FlSpot(i.toDouble(), val2.toDouble()));
        lineMinus2.add(FlSpot(i.toDouble(), valM2.toDouble()));
        line3.add(FlSpot(i.toDouble(), val3.toDouble()));
        lineMinus3.add(FlSpot(i.toDouble(), valM3.toDouble()));
      }
    }

    // Traffic light logic
    Color diagColor = Colors.greenAccent;
    IconData diagIcon = Icons.check_circle_outline;
    if (diagnosis.toLowerCase().contains("desnutrición") || diagnosis.toLowerCase().contains("severa")) {
      diagColor = Colors.redAccent;
      diagIcon = Icons.warning_amber_rounded;
    } else if (diagnosis.toLowerCase().contains("riesgo") || diagnosis.toLowerCase().contains("moderada") || diagnosis.toLowerCase().contains("sobrepeso")) {
      diagColor = Colors.orangeAccent;
      diagIcon = Icons.error_outline;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (diagnosis.isNotEmpty)
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
                Icon(diagIcon, color: diagColor, size: 42),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    diagnosis,
                    style: TextStyle(color: diagColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
        AspectRatio(
          aspectRatio: 1.5,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.only(right: 18, top: 18, bottom: 12),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true, 
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
                  getDrawingVerticalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text("Edad (meses)", style: TextStyle(color: Colors.white60, fontSize: 10)),
                    sideTitles: SideTitles(showTitles: true, reservedSize: 22, getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(color: Colors.white54, fontSize: 10))),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text("Peso (kg)", style: TextStyle(color: Colors.white60, fontSize: 10)),
                    sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(color: Colors.white54, fontSize: 10))),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.white24)),
                minX: 0,
                maxX: maxMonths.toDouble(),
                lineBarsData: [
                  LineChartBarData(spots: line3, color: Colors.redAccent, isCurved: true, dotData: const FlDotData(show: false), barWidth: 1.5),
                  LineChartBarData(spots: line2, color: Colors.orangeAccent, isCurved: true, dotData: const FlDotData(show: false), barWidth: 1.5),
                  LineChartBarData(spots: line0, color: Colors.greenAccent, isCurved: true, dotData: const FlDotData(show: false), barWidth: 2.5),
                  LineChartBarData(spots: lineMinus2, color: Colors.orangeAccent, isCurved: true, dotData: const FlDotData(show: false), barWidth: 1.5),
                  LineChartBarData(spots: lineMinus3, color: Colors.redAccent, isCurved: true, dotData: const FlDotData(show: false), barWidth: 1.5),
                  // Punto del paciente
                  LineChartBarData(
                    spots: [FlSpot(ageInMonths.toDouble(), weightKg)],
                    color: Colors.cyanAccent,
                    isCurved: false,
                    barWidth: 0,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 5, color: Colors.cyanAccent, strokeWidth: 1, strokeColor: Colors.black
                      )
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
