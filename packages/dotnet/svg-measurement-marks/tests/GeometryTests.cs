using System;
using System.Globalization;
using System.Linq;
using System.Xml;
using System.Xml.Linq;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Sewlore.SvgMeasurementMarks;

namespace Sewlore.SvgMeasurementMarks.Tests;

[TestClass]
public class GeometryTests
{
    private static readonly XNamespace Svg = "http://www.w3.org/2000/svg";
    private static SvgSheet Sheet() => new(new Length(210, MeasurementUnit.Millimetre), new Length(297, MeasurementUnit.Millimetre));

    [TestMethod]
    public void EquivalentUnitsHaveExactlyEqualPhysicalLengths()
    {
        Assert.AreEqual(new Length(25.4m, MeasurementUnit.Millimetre), new Length(2.54m, MeasurementUnit.Centimetre));
        Assert.AreEqual(new Length(1m, MeasurementUnit.Inch), new Length(25.4m, MeasurementUnit.Millimetre));
        Assert.AreEqual(254m, new Length(10m, MeasurementUnit.Inch).Millimetres);
    }

    [TestMethod]
    public void PhysicalViewportAndViewBoxUseTheSameMillimetreCoordinates()
    {
        var doc = XElement.Parse(new SvgSheet(new Length(8.5m, MeasurementUnit.Inch), new Length(11m, MeasurementUnit.Inch)).ToSvg());
        Assert.AreEqual("215.9mm", (string?)doc.Attribute("width"));
        Assert.AreEqual("279.4mm", (string?)doc.Attribute("height"));
        Assert.AreEqual("0 0 215.9 279.4", (string?)doc.Attribute("viewBox"));
    }

    [TestMethod]
    public void InchSquareDimensionsRepresentExactlyOneInch()
    {
        var doc = XElement.Parse(Sheet().AddCalibrationSquare(10, 10, new Length(1, MeasurementUnit.Inch)).ToSvg());
        var rect = doc.Descendants(Svg + "rect").Single();
        Assert.AreEqual("25.4", (string?)rect.Attribute("width"));
        Assert.AreEqual("25.4", (string?)rect.Attribute("height"));
    }

    [TestMethod]
    public void RulerIncludesPartialEndpointWithoutOvershooting()
    {
        var doc = XElement.Parse(Sheet().AddRuler(10, 30, new Length(27, MeasurementUnit.Millimetre), new Length(10, MeasurementUnit.Millimetre), 2).ToSvg());
        var ticks = doc.Descendants(Svg + "line").Where(x=>x.Attribute("data-position-mm") != null).ToArray();
        CollectionAssert.AreEqual(new[] {"0", "10", "20", "27"}, ticks.Select(x=>(string)x.Attribute("data-position-mm")!).ToArray());
        Assert.AreEqual("37", (string?)ticks.Last().Attribute("x1"));
    }

    [TestMethod]
    public void MixedUnitTicksNormalizeExactly()
    {
        var doc = XElement.Parse(Sheet().AddRuler(10, 30, new Length(2, MeasurementUnit.Inch), new Length(12.7m, MeasurementUnit.Millimetre), 2).ToSvg());
        CollectionAssert.AreEqual(new[] {"0", "12.7", "25.4", "38.1", "50.8"}, doc.Descendants(Svg + "line").Where(x=>x.Attribute("data-position-mm") != null).Select(x=>(string)x.Attribute("data-position-mm")!).ToArray());
        CollectionAssert.AreEqual(new[] {"0", "1", "2"}, doc.Descendants(Svg + "text").Select(x=>x.Value).ToArray());
    }

    [TestMethod]
    public void VerticalRulerChangesDirectionWithoutChangingScale()
    {
        var doc = XElement.Parse(Sheet().AddRuler(10, 10, new Length(3, MeasurementUnit.Centimetre), new Length(1, MeasurementUnit.Centimetre), 1, RulerOrientation.Vertical).ToSvg());
        var ticks = doc.Descendants(Svg + "line").Where(x=>x.Attribute("data-position-mm") != null).ToArray();
        Assert.AreEqual("40", (string?)ticks.Last().Attribute("y1"));
        Assert.AreEqual("10", (string?)ticks.Last().Attribute("x1"));
    }

    [TestMethod]
    public void LabelsCannotInjectSvgElementsOrUrls()
    {
        const string hostile = "</text><script>alert('x')</script> & <a href='https://bad.invalid'>";
        var svg = Sheet().AddMeasurementLabel(10, 50, new Length(50, MeasurementUnit.Millimetre), hostile).ToSvg();
        var doc = XElement.Parse(svg);
        Assert.AreEqual(0, doc.Descendants(Svg + "script").Count());
        Assert.AreEqual(0, doc.Descendants(Svg + "a").Count());
        Assert.AreEqual(hostile + " - 50 mm", doc.Descendants(Svg + "text").Single().Value);
    }

    [TestMethod]
    public void TurkishCultureCannotIntroduceDecimalCommas()
    {
        var before = CultureInfo.CurrentCulture;
        try {
            CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo("tr-TR");
            var svg = Sheet().AddCalibrationSquare(10.5m, 11.2m, new Length(2.5m, MeasurementUnit.Centimetre)).ToSvg();
            StringAssert.Contains(svg, "x=\"10.5\"");
            Assert.IsFalse(svg.Contains("10,5"));
        } finally { CultureInfo.CurrentCulture = before; }
    }

    [TestMethod]
    public void InvalidLengthsAndUnitsAreRejected()
    {
        Assert.ThrowsExactly<ArgumentOutOfRangeException>(()=>new Length(-1, MeasurementUnit.Millimetre));
        Assert.ThrowsExactly<ArgumentOutOfRangeException>(()=>new Length(1, (MeasurementUnit)99));
        Assert.ThrowsExactly<ArgumentOutOfRangeException>(()=>new Length(decimal.MaxValue, MeasurementUnit.Inch));
        Assert.ThrowsExactly<ArgumentOutOfRangeException>(()=>new SvgSheet(new Length(0, MeasurementUnit.Millimetre), new Length(10, MeasurementUnit.Millimetre)));
    }

    [TestMethod]
    public void InvalidGeometryDoesNotMutateExistingSheet()
    {
        var sheet = Sheet().AddCalibrationSquare(10, 10, new Length(10, MeasurementUnit.Millimetre));
        var before = sheet.ToSvg();
        Assert.ThrowsExactly<ArgumentOutOfRangeException>(()=>sheet.AddCalibrationSquare(0, 0, new Length(10, MeasurementUnit.Millimetre)));
        Assert.ThrowsExactly<ArgumentOutOfRangeException>(()=>sheet.AddRuler(10, 30, new Length(1, MeasurementUnit.Millimetre), new Length(0.000001m, MeasurementUnit.Millimetre)));
        Assert.ThrowsExactly<ArgumentOutOfRangeException>(()=>sheet.AddMeasurementLabel(200, 30, new Length(50, MeasurementUnit.Millimetre), "Too wide"));
        Assert.AreEqual(before, sheet.ToSvg());
    }

    [TestMethod]
    public void XMLControlCharactersAreRejected()
    {
        Assert.ThrowsExactly<XmlException>(()=>new SvgSheet(new Length(50, MeasurementUnit.Millimetre), new Length(50, MeasurementUnit.Millimetre), "bad\u0001"));
    }

    [TestMethod]
    public void MeasurementEndpointsHaveTheRequestedPhysicalSeparation()
    {
        var doc = XElement.Parse(Sheet().AddMeasurementLabel(20, 80, new Length(2, MeasurementUnit.Inch), "Test baseline").ToSvg());
        var baseline = doc.Descendants(Svg + "line").First();
        var span = decimal.Parse((string)baseline.Attribute("x2")!, CultureInfo.InvariantCulture) - decimal.Parse((string)baseline.Attribute("x1")!, CultureInfo.InvariantCulture);
        Assert.AreEqual(50.8m, span);
    }

    [TestMethod]
    public void ExtremelySmallIntervalsAreRejectedWithoutDecimalOverflow()
    {
        Assert.ThrowsExactly<ArgumentOutOfRangeException>(()=>Sheet().AddRuler(10, 30,
            new Length(100, MeasurementUnit.Millimetre), new Length(0.0000000000000000000000000001m, MeasurementUnit.Millimetre)));
    }

    [TestMethod]
    public void VerticalEndpointLabelsRequireStandardTopAndBottomSpace()
    {
        Assert.ThrowsExactly<ArgumentOutOfRangeException>(()=>Sheet().AddRuler(10, 1,
            new Length(20, MeasurementUnit.Millimetre), new Length(5, MeasurementUnit.Millimetre), 2, RulerOrientation.Vertical));
        Assert.ThrowsExactly<ArgumentOutOfRangeException>(()=>Sheet().AddRuler(10, 276,
            new Length(20, MeasurementUnit.Millimetre), new Length(5, MeasurementUnit.Millimetre), 2, RulerOrientation.Vertical));
    }
}
