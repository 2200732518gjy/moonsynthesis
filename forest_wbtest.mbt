///|
test "forest escapes hostile text and rejects forbidden XML controls" {
  let s = [study("<script>&\"'", -1.0, 1.0), study("safe", 2.0, 1.0)]
  let svg = render_forest(s, title="<Title>")
  assert_true(svg.contains("&lt;script&gt;&amp;&quot;&apos;"))
  assert_true(!svg.contains("<script>"))
  assert_true(svg.has_prefix("<svg xmlns="))
  assert_true(svg.has_suffix("</svg>"))
  let bad = try {
    ignore(render_forest(s, title="bad\u0001"))
    false
  } catch {
    _ => true
  }
  assert_true(bad)
}
