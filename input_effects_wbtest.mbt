///|
test "protocol converts arm summaries and rejects mixed effect families" {
  let text = "{\"version\":1,\"studies\":[{\"kind\":\"md\",\"id\":\"a\",\"treatment\":{\"n\":10,\"mean\":3,\"sd\":1},\"control\":{\"n\":10,\"mean\":1,\"sd\":1}},{\"kind\":\"md\",\"id\":\"b\",\"treatment\":{\"n\":20,\"mean\":4,\"sd\":2},\"control\":{\"n\":20,\"mean\":2,\"sd\":2}}]}"
  let r = parse_request(text)
  assert_eq(r.studies[0].effect, 2.0)
  assert_true((r.studies[0].variance - 0.2).abs() < 1.0e-12)
  let mixed = text.replace(old="\"kind\":\"md\"", new="\"kind\":\"hedges-g\"")
  let bad = try {
    ignore(parse_request(mixed))
    false
  } catch {
    _ => true
  }
  assert_true(bad)
  let fractional = text.replace(old="\"n\":10", new="\"n\":10.5")
  let bad = try {
    ignore(parse_request(fractional))
    false
  } catch {
    _ => true
  }
  assert_true(bad)
}
