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

class GestationalResult {
  final double bmi;
  final String diagnosis;
  final int weeks;

  GestationalResult({
    required this.bmi,
    required this.diagnosis,
    required this.weeks,
  });
}

class AnthroService {
  
  static GestationalResult calculateGestational(int weeks, double weightKg, double heightCm) {
    double bmi = weightKg / ((heightCm / 100) * (heightCm / 100));
    String diagnosis = _diagnoseGestational(weeks, bmi);
    return GestationalResult(bmi: bmi, diagnosis: diagnosis, weeks: weeks);
  }

  static String _diagnoseGestational(int weeks, double bmi) {
    if (weeks < 10) weeks = 10;
    if (weeks > 42) weeks = 42;

    // Tabla de Atalah simplificada (puntos de corte para Bajo Peso, Normal, Sobrepeso)
    // El cuarto rango es Obesidad (> Sobrepeso)
    final Map<int, List<double>> atalahTable = {
      10: [20.2, 25.2, 30.1],
      11: [20.3, 25.3, 30.2],
      12: [20.4, 25.4, 30.3],
      13: [20.6, 25.6, 30.5],
      14: [20.7, 25.7, 30.6],
      15: [20.8, 25.8, 30.7],
      16: [21.0, 25.9, 30.8],
      17: [21.1, 26.1, 30.9],
      18: [21.2, 26.2, 31.0],
      19: [21.4, 26.4, 31.2],
      20: [21.5, 26.5, 31.3],
      21: [21.7, 26.6, 31.5],
      22: [21.8, 26.8, 31.6],
      23: [22.0, 27.0, 31.8],
      24: [22.2, 27.1, 31.9],
      25: [22.4, 27.3, 32.1],
      26: [22.6, 27.4, 32.2],
      27: [22.7, 27.6, 32.4],
      28: [22.9, 27.8, 32.5],
      29: [23.1, 27.9, 32.7],
      30: [23.3, 28.1, 32.8],
      31: [23.5, 28.2, 33.0],
      32: [23.6, 28.4, 33.1],
      33: [23.8, 28.5, 33.3],
      34: [24.0, 28.7, 33.4],
      35: [24.2, 28.8, 33.6],
      36: [24.4, 29.0, 33.7],
      37: [24.5, 29.1, 33.9],
      38: [24.7, 29.3, 34.0],
      39: [24.9, 29.4, 34.2],
      40: [25.0, 29.6, 34.3],
      41: [25.0, 29.6, 34.3],
      42: [25.0, 29.6, 34.3],
    };

    final cuts = atalahTable[weeks]!;
    if (bmi < cuts[0]) return "Bajo Peso (Gestante)";
    if (bmi < cuts[1]) return "Peso Normal (Gestante)";
    if (bmi < cuts[2]) return "Sobrepeso (Gestante)";
    return "Obesidad (Gestante)";
  }

  static AnthroResult calculate(int ageInMonths, double weightKg, double heightCm, String genderStr, {double? muacCm}) {
    Sex sex = (genderStr.toLowerCase() == 'm' || genderStr.toLowerCase() == 'masculino' || genderStr.toLowerCase() == 'male')
        ? Sex.male
        : Sex.female;

    double zWfa = double.nan;
    double zHfa = double.nan;
    double zBmi = double.nan;
    double zWfh = double.nan;

    try {
      // Usar Age(months: ...) para precisión exacta según tablas OMS
      final age = Age.byMonthsAgo(ageInMonths);
      final weight = Mass$Kilogram(weightKg);
      final height = Length$Centimeter(heightCm);
      
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

    // Manejo de valores extremos (NaN suele ocurrir si está fuera de las tablas OMS)
    // En lugar de 0.0 (que es el promedio), usamos valores que indiquen el extremo
    double safeZ(double v) {
      if (v.isNaN) {
        // Si el peso es muy bajo para la edad/talla, asumimos el mínimo de la tabla (-5 o -6)
        // para que no se grafique en el centro (0.0)
        return -5.0; 
      }
      return v;
    }

    return AnthroResult(
      zWeightForAge: safeZ(zWfa),
      zHeightForAge: safeZ(zHfa),
      zBmiForAge: safeZ(zBmi),
      zWeightForHeight: safeZ(zWfh),
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
