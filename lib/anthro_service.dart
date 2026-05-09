import 'package:growth_standards/growth_standards.dart';

class AnthroResult {
  final double zWeightForAge;
  final double zHeightForAge;
  final double zBmiForAge;
  final String diagnosis;

  AnthroResult({
    required this.zWeightForAge,
    required this.zHeightForAge,
    required this.zBmiForAge,
    required this.diagnosis,
  });
}

class AnthroService {
  
  static AnthroResult calculate(int ageInMonths, double weightKg, double heightCm, String genderStr) {
    Sex sex = (genderStr.toLowerCase() == 'm' || genderStr.toLowerCase() == 'masculino' || genderStr.toLowerCase() == 'male')
        ? Sex.male
        : Sex.female;

    final age = Age.byMonthsAgo(ageInMonths);
    final weight = Mass.kilogram(weightKg);
    final height = Length.centimeter(heightCm);
    
    double zWfa = double.nan;
    double zHfa = double.nan;
    double zBmi = double.nan;

    try {
      if (ageInMonths <= 60) {
        // WHO Growth Standards 0-5 años
        final wfa = WHOGrowthStandardsWeightForAge(sex: sex, age: age, weight: weight);
        zWfa = wfa.zScore().toDouble();

        final lfa = WHOGrowthStandardsLengthForAge(
          sex: sex, 
          age: age, 
          lengthHeight: height, 
          measure: ageInMonths < 24 ? LengthHeightMeasurementPosition.recumbent : LengthHeightMeasurementPosition.standing
        );
        zHfa = lfa.zScore().toDouble();

        final bmiVal = BodyMassIndex(mass: weight, length: height);
        final bmi = WHOGrowthStandardsBodyMassIndexForAge(sex: sex, age: age, bmi: bmiVal);
        zBmi = bmi.zScore().toDouble();

      } else {
        // WHO Growth Reference 5-19 años
        if (ageInMonths <= 120) {
          final wfa = WHOGrowthReferenceWeightForAge(sex: sex, age: age, weight: weight);
          zWfa = wfa.zScore().toDouble();
        }

        final hfa = WHOGrowthReferenceHeightForAge(sex: sex, age: age, lengthHeight: height);
        zHfa = hfa.zScore().toDouble();

        final bmiVal = BodyMassIndex(mass: weight, length: height);
        final bmi = WHOGrowthReferenceBodyMassIndexForAge(sex: sex, age: age, bmi: bmiVal);
        zBmi = bmi.zScore().toDouble();
      }
    } catch (e) {
      print("Error calculating Anthro Z-scores: \$e");
    }

    String diagnosis = _diagnose(zWfa, zHfa, zBmi, ageInMonths);

    return AnthroResult(
      zWeightForAge: zWfa.isNaN ? 0.0 : zWfa,
      zHeightForAge: zHfa.isNaN ? 0.0 : zHfa,
      zBmiForAge: zBmi.isNaN ? 0.0 : zBmi,
      diagnosis: diagnosis,
    );
  }

  static String _diagnose(double zWfa, double zHfa, double zBmi, int ageInMonths) {
    if (zBmi.isNaN) return "Datos insuficientes para el diagnóstico completo.";

    if (ageInMonths <= 60) {
      // 0-5 años
      if (zBmi > 3) return "Obesidad";
      if (zBmi > 2) return "Sobrepeso";
      if (zBmi > 1) return "Riesgo de sobrepeso";
      if (zBmi < -3) return "Desnutrición aguda severa";
      if (zBmi < -2) return "Desnutrición aguda moderada";
      return "Crecimiento Normal";
    } else {
      // 5-19 años
      if (zBmi > 2) return "Obesidad";
      if (zBmi > 1) return "Sobrepeso";
      if (zBmi < -3) return "Delgadez severa";
      if (zBmi < -2) return "Delgadez";
      return "Crecimiento Normal";
    }
  }
}
