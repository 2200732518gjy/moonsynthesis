///|
test "validated study exposes exact independent summary" {
  let s = study("s1", 0.2, 0.04, group="a")
  assert_eq(s.id(), "s1")
  assert_eq(s.effect(), 0.2)
  assert_eq(s.variance(), 0.04)
  assert_eq(s.group(), "a")
}

///|
test "invalid study inputs fail explicitly" {
  let inputs = [
    ("", 0.1, 1.0),
    ("s", 0.0, 0.0),
    ("s", 0.0, -1.0),
    ("s", 1.0 / 0.0, 1.0),
    ("s", 0.0, 0.0 / 0.0),
  ]
  for (id, y, v) in inputs {
    let failed = try {
      ignore(study(id, y, v))
      false
    } catch {
      _ => true
    }
    assert_true(failed)
  }
}

///|
test "dataset rejects duplicate identifiers and cardinality" {
  let s = study("x", 0.0, 1.0)
  assert_true(
    try {
      validate_studies([s, s], 2)
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      validate_studies([s], 2)
      false
    } catch {
      _ => true
    },
  )
}
