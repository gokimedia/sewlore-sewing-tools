using Sewlore.SvgMeasurementMarks;

var output = args.Length == 1 ? args[0] : "generated";
Directory.CreateDirectory(output);
var a4 = new SvgSheet(new Length(210, MeasurementUnit.Millimetre), new Length(297, MeasurementUnit.Millimetre), "A4 calibration and measurement references");
a4.AddCalibrationSquare(15, 15, new Length(5, MeasurementUnit.Centimetre))
  .AddCalibrationSquare(80, 15, new Length(1, MeasurementUnit.Inch))
  .AddRuler(15, 90, new Length(150, MeasurementUnit.Millimetre), new Length(5, MeasurementUnit.Millimetre), 2)
  .AddRuler(15, 115, new Length(6, MeasurementUnit.Inch), new Length(0.25m, MeasurementUnit.Inch), 4)
  .AddMeasurementLabel(15, 145, new Length(10, MeasurementUnit.Centimetre), "Specimen baseline");
File.WriteAllText(Path.Combine(output, "a4-reference.svg"), a4.ToSvg());
var letter = new SvgSheet(new Length(8.5m, MeasurementUnit.Inch), new Length(11, MeasurementUnit.Inch), "Letter vertical ruler and inch calibration");
letter.AddCalibrationSquare(15, 15, new Length(2, MeasurementUnit.Inch))
      .AddRuler(90, 15, new Length(8, MeasurementUnit.Inch), new Length(0.5m, MeasurementUnit.Inch), 2, RulerOrientation.Vertical);
File.WriteAllText(Path.Combine(output, "letter-reference.svg"), letter.ToSvg());
Console.WriteLine("Generated two native SVG documents. Print at actual size; measure the calibration square before use.");
