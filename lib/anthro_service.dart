import 'package:growth_standards/growth_standards.dart';

class AnthroResult {
  final double zWeightForAge;
  final double zHeightForAge;
  final double zBmiForAge;
  final double zWeightForHeight;
  final String diagnosis;
  final String muacDiagnosis;

  AnthroResult({
    required this.zWeightForAge,
    required this.zHeightForAge,
    required this.zBmiForAge,
    required this.zWeightForHeight,
    required this.diagnosis,
    required this.muacDiagnosis,
  });
}

class AnthroService {
  
  static AnthroResult calculate(int ageInMonths, double weightKg, double heightCm, String genderStr, {double? muacCm}) {
    Sex sex = (genderStr.toLowerCase() == 'm' || genderStr.toLowerCase() == 'masculino' || genderStr.toLowerCase() == 'male')
        ? Sex.male
        : Sex.female;

    final age = Age.byMonthsAgo(ageInMonths);
    final weight = Mass$Kilogram(weightKg);
    final height = Length$Centimeter(heightCm);
    
    double zWfa = double.nan;
    double zHfa = double.nan;
    double zBmi = double.nan;
    double zWfh = double.nan;

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

        final bmiVal = weightKg / ((heightCm / 100) * (heightCm / 100));
        final bmiMeasurement = WHOGrowthStandardsBodyMassIndexMeasurement(
          bmiVal,
          age: age,
        );
        final bmi = WHOGrowthStandardsBodyMassIndexForAge(
          sex: sex,
          bodyMassIndexMeasurement: bmiMeasurement,
        );
        zBmi = bmi.zScore().toDouble();

        // Peso para la Talla (WFH) - Disponible para 0-5 años (o hasta 120cm)
        if (ageInMonths < 24) {
           final wfl = WHOGrowthStandardsWeightForLength(sex: sex, age: age, weight: weight, length: height, measure: LengthHeightMeasurementPosition.recumbent);
           zWfh = wfl.zScore().toDouble();
        } else {
           final wfh = WHOGrowthStandardsWeightForHeight(sex: sex, age: age, weight: weight, height: height, measure: LengthHeightMeasurementPosition.standing);
           zWfh = wfh.zScore().toDouble();
        }

      } else {
        // WHO Growth Reference 5-19 años
        if (ageInMonths <= 120) {
          final wfa = WHOGrowthReferenceWeightForAge(sex: sex, age: age, weight: weight);
          zWfa = wfa.zScore().toDouble();
        }

        final hfa = WHOGrowthReferenceHeightForAge(sex: sex, age: age, lengthHeight: height);
        zHfa = hfa.zScore().toDouble();

        final bmiVal = weightKg / ((heightCm / 100) * (heightCm / 100));
        final bmiMeasurement = WHOGrowthReferenceBodyMassIndexMeasurement(
          bmiVal,
        );
        final bmi = WHOGrowthReferenceBodyMassIndexForAge(
          sex: sex,
          age: age,
          bodyMassIndexMeasurement: bmiMeasurement,
        );
        zBmi = bmi.zScore().toDouble();
        // WFH no se usa típicamente en >5 años (se prefiere IMC)
      }
    } catch (e) {
      print("Error calculating Anthro Z-scores: $e");
    }

    String diagnosis = _diagnose(zWfa, zHfa, zBmi, zWfh, ageInMonths);
    if (diagnosis.startsWith("Datos insuficientes") && muacCm != null) {
      diagnosis = "Cribado por MUAC";
    }

    String muacDiagnosis = "";
    if (muacCm != null && ageInMonths >= 6 && ageInMonths <= 59) {
      if (muacCm < 11.5) {
        muacDiagnosis = "🔴 PELIGRO: Desnutrición Aguda Severa (MUAC < 11.5 cm)";
      } else if (muacCm < 12.5) {
        muacDiagnosis = "🟡 PRECAUCIÓN: Desnutrición Aguda Moderada (MUAC < 12.5 cm)";
      } else {
        muacDiagnosis = "🟢 Normal: Sin riesgo de desnutrición aguda según MUAC";
      }
    }

    return AnthroResult(
      zWeightForAge: zWfa.isNaN ? 0.0 : zWfa,
      zHeightForAge: zHfa.isNaN ? 0.0 : zHfa,
      zBmiForAge: zBmi.isNaN ? 0.0 : zBmi,
      zWeightForHeight: zWfh.isNaN ? 0.0 : zWfh,
      diagnosis: diagnosis,
      muacDiagnosis: muacDiagnosis,
    );
  }

  static String _diagnose(double zWfa, double zHfa, double zBmi, double zWfh, int ageInMonths) {
    if (zBmi.isNaN && zWfh.isNaN) return "Datos insuficientes para el diagnóstico.";

    // Priorizar WFH para desnutrición aguda en <5 años si está disponible
    double acuteIndicator = (ageInMonths <= 60 && !zWfh.isNaN) ? zWfh : zBmi;

    if (ageInMonths <= 60) {
      if (acuteIndicator > 3) return "Obesidad";
      if (acuteIndicator > 2) return "Sobrepeso";
      if (acuteIndicator > 1) return "Riesgo de sobrepeso";
      if (acuteIndicator < -3) return "Desnutrición aguda severa";
      if (acuteIndicator < -2) return "Desnutrición aguda moderada";
      if (zHfa < -2) return "Desnutrición crónica (Talla baja)";
      return "Crecimiento Normal";
    } else {
      if (zBmi > 2) return "Obesidad";
      if (zBmi > 1) return "Sobrepeso";
      if (zBmi < -3) return "Delgadez severa";
      if (zBmi < -2) return "Delgadez";
      if (zHfa < -2) return "Retraso en el crecimiento";
      return "Crecimiento Normal";
    }
  }
}
