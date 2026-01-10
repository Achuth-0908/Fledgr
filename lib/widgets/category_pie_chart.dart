import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> data;
  final Map<String, String> catNames;

  const CategoryPieChart({
    super.key,
    required this.data,
    required this.catNames,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0.0, (a, b) => a + b);

    final List<Color> colors = Colors.primaries;
    final entries = data.entries.toList(); // 👈 stable order

    final sections = List.generate(entries.length, (index) {
      final e = entries[index];
      final percent = total == 0 ? 0 : (e.value / total) * 100;
      final color = colors[index % colors.length];

      return PieChartSectionData(
        value: e.value,
        title: "${percent.toStringAsFixed(0)}%",
        color: color,
        radius: 55,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 220, // chart stays fixed
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 35,
              sectionsSpace: 2,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // LEGEND — grows as needed
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: List.generate(entries.length, (index) {
            final e = entries[index];
            final color = colors[index % colors.length];

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(catNames[e.key] ?? e.key),
              ],
            );
          }),
        ),
      ],
    );
  }
}
