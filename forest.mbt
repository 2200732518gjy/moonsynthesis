///| Reject XML 1.0 forbidden controls and escape every text-node metacharacter.
fn xml_text(value : String) -> String raise SynthesisError {
  let output = StringBuilder()
  for c in value {
    let n = c.to_int()
    if (n < 32 && n != 9 && n != 10 && n != 13) || n == 65534 || n == 65535 {
      raise Invalid("label contains XML-forbidden character")
    }
    match c {
      '&' => output.write_string("&amp;")
      '<' => output.write_string("&lt;")
      '>' => output.write_string("&gt;")
      '"' => output.write_string("&quot;")
      '\'' => output.write_string("&apos;")
      _ => output.write_char(c)
    }
  }
  output.to_string()
}

///| Bounds include every study interval, the pooled interval and the null.
/// Coordinates use a normalized intermediate to avoid multiplying huge values.
fn forest_coordinate(value : Double, lower : Double, span : Double) -> Double raise SynthesisError {
  let result = 250.0 + (value - lower) / span * 600.0
  require_finite(result, "forest coordinate")
  result
}

///|
fn svg_line(output : StringBuilder, x1 : Double, x2 : Double, y : Double, color : String) -> Unit {
  output.write_string("<line x1=\"" + x1.to_string() + "\" x2=\"" + x2.to_string() +
    "\" y1=\"" + y.to_string() + "\" y2=\"" + y.to_string() + "\" stroke=\"" + color + "\"/>")
}

///|
fn svg_label(output : StringBuilder, label : String, x : Double, y : Double) -> Unit raise SynthesisError {
  output.write_string("<text x=\"" + x.to_string() + "\" y=\"" + y.to_string() + "\" font-size=\"12\">" + xml_text(label) + "</text>")
}

///| A standalone passive SVG on the additive input scale; no scripts, links,
/// external fonts, event handlers or user-controlled markup are generated.
/// Long labels remain in <title> while the visible label uses an ID sequence.
pub fn render_forest(studies : Array[Study], model~ : Model = PM,
  inference~ : Inference = ModifiedHK, alpha~ : Double = 0.05,
  title~ : String = "Independent-study synthesis") -> String raise SynthesisError {
  if title.length() > 256 { raise Invalid("forest title exceeds 256 characters") }
  let fit = analyze(studies, model~, inference~, alpha~)
  let rows = summarize_studies(studies, model~, inference~, alpha~)
  let mut lower = fit.confidence.lower.min(0.0)
  let mut upper = fit.confidence.upper.max(0.0)
  for row in rows {
    lower = lower.min(row.confidence.lower)
    upper = upper.max(row.confidence.upper)
  }
  let raw_span = upper - lower
  require_finite(raw_span, "forest span")
  if raw_span <= 0.0 { raise Invalid("forest requires a positive representable span") }
  let padding = raw_span * 0.05
  lower = lower - padding
  upper = upper + padding
  let span = upper - lower
  require_finite(lower, "forest bound")
  require_finite(upper, "forest bound")
  require_finite(span, "forest span")
  let height = 150 + rows.length() * 28
  let output = StringBuilder()
  output.write_string("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"900\" height=\"" + height.to_string() +
    "\" viewBox=\"0 0 900 " + height.to_string() + "\" role=\"img\">")
  output.write_string("<title>" + xml_text(title) + "</title><rect width=\"900\" height=\"100%\" fill=\"white\"/>")
  svg_label(output, title, 16.0, 24.0)
  svg_label(output, "Study / additive effect with confidence interval", 16.0, 46.0)
  let null_x = forest_coordinate(0.0, lower, span)
  output.write_string("<line x1=\"" + null_x.to_string() + "\" x2=\"" + null_x.to_string() +
    "\" y1=\"55\" y2=\"" + (height - 65).to_string() + "\" stroke=\"#888\" stroke-dasharray=\"4 4\"/>")
  for i in 0..<rows.length() {
    let row = rows[i]
    let y = 72.0 + i.to_double() * 28.0
    output.write_string("<g><title>" + xml_text(row.id + " / " + row.group) + "</title>")
    let label = if row.id.length() <= 24 { row.id } else { "Study " + (i + 1).to_string() }
    svg_label(output, label, 16.0, y + 4.0)
    let x1 = forest_coordinate(row.confidence.lower, lower, span)
    let x2 = forest_coordinate(row.confidence.upper, lower, span)
    let x = forest_coordinate(row.effect, lower, span)
    svg_line(output, x1, x2, y, "#245e9b")
    let size = 3.0 + row.weight.sqrt() * 10.0
    output.write_string("<rect x=\"" + (x - size / 2.0).to_string() + "\" y=\"" + (y - size / 2.0).to_string() +
      "\" width=\"" + size.to_string() + "\" height=\"" + size.to_string() + "\" fill=\"#245e9b\"/></g>")
  }
  let y = 80.0 + rows.length().to_double() * 28.0
  svg_label(output, "Pooled", 16.0, y + 4.0)
  let x = forest_coordinate(fit.pool.estimate, lower, span)
  let x1 = forest_coordinate(fit.confidence.lower, lower, span)
  let x2 = forest_coordinate(fit.confidence.upper, lower, span)
  output.write_string("<polygon fill=\"#a34420\" points=\"" + x1.to_string() + "," + y.to_string() + " " +
    x.to_string() + "," + (y - 7.0).to_string() + " " + x2.to_string() + "," + y.to_string() + " " +
    x.to_string() + "," + (y + 7.0).to_string() + "\"/>")
  svg_line(output, 250.0, 850.0, y + 20.0, "#333")
  svg_label(output, lower.to_string(), 250.0, y + 40.0)
  svg_label(output, upper.to_string(), 735.0, y + 40.0)
  output.write_string("</svg>")
  output.to_string()
}
