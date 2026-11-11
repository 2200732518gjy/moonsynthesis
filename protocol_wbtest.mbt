///|
test "batch outputs are complete and errors have a stable envelope" {
  let s = [
    study("a", 0.0, 1.0, group="x"),
    study("b", 1.0, 1.0, group="x"),
    study("c", 3.0, 1.0, group="y"),
    study("d", 4.0, 1.0, group="y"),
  ]
  let result = execute({
    studies: s,
    model: PM,
    inference: ModifiedHK,
    alpha: 0.05,
    outputs: [
      "summary", "studies", "leave-one-out", "cumulative", "subgroups", "csv", "svg",
    ],
  }).stringify()
  for
    key in [
      "summary", "studies", "leave-one-out", "cumulative", "subgroups", "csv", "svg",
    ] {
    assert_true(result.contains("\"" + key + "\":"))
  }
  assert_true(process_json("[]").contains("\"ok\":false"))
  let bad = try {
    ignore(
      execute({
        studies: s,
        model: PM,
        inference: Normal,
        alpha: 0.05,
        outputs: ["path"],
      }),
    )
    false
  } catch {
    _ => true
  }
  assert_true(bad)
}
