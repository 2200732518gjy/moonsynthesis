test "protocol strict decoding and model defaults" {
  let good = "{\"version\":1,\"model\":\"fixed\",\"studies\":[{\"id\":\"a\",\"effect\":1,\"variance\":1},{\"id\":\"b\",\"effect\":2,\"variance\":1}]}"
  let r = parse_request(good)
  assert_true(r.model == Fixed)
  assert_true(r.inference == Normal)
  assert_eq(r.outputs[0], "summary")
  let bad = ["{}", "[]", "{\"version\":1,\"version\":1}", good.replace(old="\"version\":1", new="\"version\":1,\"typo\":true"),
    good.replace(old="\"variance\":1", new="\"variance\":null"), good.replace(old="\"version\":1", new="\"version\":1.5")]
  for text in bad {
    let rejected = try { ignore(parse_request(text)); false } catch { _ => true }
    assert_true(rejected)
  }
}
