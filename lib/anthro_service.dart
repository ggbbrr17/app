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

class AdultResult {
  final double bmi;
  final String diagnosis;

  AdultResult({
    required this.bmi,
    required this.diagnosis,
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
      10: [20.0, 25.0, 30.0],
      11: [20.1, 25.1, 30.1],
      12: [20.2, 25.2, 30.2],
      13: [20.3, 25.3, 30.3],
      14: [20.4, 25.4, 30.4],
      15: [20.5, 25.5, 30.5],
      16: [20.6, 25.6, 30.6],
      17: [20.7, 25.7, 30.7],
      18: [20.8, 25.8, 30.8],
      19: [21.0, 26.0, 31.0],
      20: [21.1, 26.1, 31.1],
      21: [21.3, 26.3, 31.3],
      22: [21.5, 26.5, 31.5],
      23: [21.7, 26.6, 31.6],
      24: [21.8, 26.7, 31.7],
      25: [22.0, 26.8, 31.8],
      26: [22.2, 26.9, 31.9],
      27: [22.4, 27.0, 32.0],
      28: [22.6, 27.0, 32.1],
      29: [22.8, 27.1, 32.2],
      30: [23.0, 27.1, 32.3],
      31: [23.2, 27.2, 32.4],
      32: [23.5, 27.2, 32.5],
      33: [23.7, 27.3, 32.6],
      34: [23.9, 27.4, 32.7],
      35: [24.1, 27.5, 32.8],
      36: [24.3, 27.6, 32.9],
      37: [24.5, 27.7, 33.0],
      38: [24.7, 27.8, 33.1],
      39: [24.9, 27.9, 33.2],
      40: [25.0, 28.0, 33.3],
      41: [25.0, 28.0, 33.3],
      42: [25.0, 28.0, 33.3],
    };

    final cuts = atalahTable[weeks]!;
    if (bmi < cuts[0]) return "Bajo Peso (Gestante)";
    if (bmi < cuts[1]) return "Peso Normal (Gestante)";
    if (bmi < cuts[2]) return "Sobrepeso (Gestante)";
    return "Obesidad (Gestante)";
  }

  static AdultResult calculateAdult(double weightKg, double heightCm) {
    double bmi = weightKg / ((heightCm / 100) * (heightCm / 100));
    String diagnosis = _diagnoseAdult(bmi);
    return AdultResult(bmi: bmi, diagnosis: diagnosis);
  }

  static String _diagnoseAdult(double bmi) {
    if (bmi < 16.0) return "Delgadez Severa (Adulto)";
    if (bmi < 17.0) return "Delgadez Moderada (Adulto)";
    if (bmi < 18.5) return "Delgadez Aceptable (Adulto)";
    if (bmi < 25.0) return "Peso Normal (Adulto)";
    if (bmi < 30.0) return "Sobrepeso (Adulto)";
    if (bmi < 35.0) return "Obesidad Grado I (Adulto)";
    if (bmi < 40.0) return "Obesidad Grado II (Adulto)";
    return "Obesidad Grado III (Mórbida) (Adulto)";
  }

  static AnthroResult calculate(int ageInMonths, double weightKg, double heightCm, String genderStr, {double? muacCm}) {
    if (ageInMonths < 0 || ageInMonths > 228) return AnthroResult(zWeightForAge: -5, zHeightForAge: -5, zBmiForAge: -5, zWeightForHeight: -5, diagnosis: "Edad fuera de rango (0-19 años)", muacDiagnosis: "");
    if (weightKg < 0.5 || weightKg > 200) return AnthroResult(zWeightForAge: -5, zHeightForAge: -5, zBmiForAge: -5, zWeightForHeight: -5, diagnosis: "Peso fuera de rango realista (0.5-200kg)", muacDiagnosis: "");
    if (heightCm < 30 || heightCm > 250) return AnthroResult(zWeightForAge: -5, zHeightForAge: -5, zBmiForAge: -5, zWeightForHeight: -5, diagnosis: "Talla fuera de rango realista (30-250cm)", muacDiagnosis: "");

    Sex sex = (genderStr.toLowerCase().contains('m') || genderStr.toLowerCase().contains('masculino') || genderStr.toLowerCase().contains('niño'))
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
      return v.isNaN ? -99.0 : v;
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
    if (zBmi.isNaN && zWfh.isNaN && zHfa.isNaN) return "Datos insuficientes para el diagnóstico clínico.";

    List<String> findings = [];
    
    // 1. ANÁLISIS DE CRECIMIENTO LINEAL (Talla para la Edad - Desnutrición Crónica)
    if (!zHfa.isNaN) {
      if (zHfa < -3) {
        findings.add("⚠️ TALLA BAJA SEVERA (Desnutrición Crónica Grave)");
      } else if (zHfa < -2) {
        findings.add("⚠️ TALLA BAJA (Desnutrición Crónica)");
      } else if (zHfa < -1) {
        findings.add("Riesgo de Talla Baja");
      } else {
        findings.add("Talla adecuada para la edad");
      }
    }

    // 2. ANÁLISIS DE PESO Y PROPORCIONALIDAD (Peso/Talla o IMC)
    double acuteIndicator = (ageInMonths <= 60 && !zWfh.isNaN) ? zWfh : zBmi;
    String acuteLabel = (ageInMonths <= 60 && !zWfh.isNaN) ? "Peso/Talla" : "IMC/Edad";

    if (!acuteIndicator.isNaN) {
      if (acuteIndicator < -3) {
        findings.add("🚨 DESNUTRICIÓN AGUDA SEVERA");
      } else if (acuteIndicator < -2) {
        findings.add("⚠️ DESNUTRICIÓN AGUDA MODERADA");
      } else if (acuteIndicator < -1) {
        findings.add("Riesgo de desnutrición aguda");
      } else if (acuteIndicator > 3) {
        // Explicación especial para casos de Talla Baja Extrema (como el caso de Pedro)
        if (zHfa < -3) {
          findings.add("❗ IMC ELEVADO debido a Talla Baja Extrema (No necesariamente Obesidad primaria)");
        } else {
          findings.add("⚠️ OBESIDAD");
        }
      } else if (acuteIndicator > 2) {
        findings.add("⚠️ SOBREPESO");
      } else if (acuteIndicator > 1) {
        findings.add("Riesgo de Sobrepeso");
      } else {
        findings.add("Peso adecuado para la talla");
      }
    }

    // 3. ANÁLISIS DE PESO PARA LA EDAD (Indicador global)
    if (!zWfa.isNaN) {
      if (zWfa < -3) findings.add("Bajo Peso Severo para la edad");
      else if (zWfa < -2) findings.add("Bajo Peso para la edad");
    }

    // Generar resumen profesional
    if (findings.isEmpty) return "Crecimiento Normal";
    
    return findings.join("\n• ");
  }
}
