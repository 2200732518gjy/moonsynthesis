///|
fn regression_fixture() -> Array[Study] raise SynthesisError {
  [study("a", 0.0, 1.0), study("b", 2.0, 1.0), study("c", 4.0, 1.0)]
}

///|
test "REML equal variances has exact nonnegative sample variance solution" {
  let s = regression_fixture()
  assert_true((tau_reml(s) - 3.0).abs() < 1.0e-9)
  let fit = analyze(s, model=REML, inference=Normal)
  assert_true((fit.pool.estimate - 2.0).abs() < 1.0e-12)
  assert_true((fit.pool.variance - 4.0 / 3.0).abs() < 1.0e-9)
  assert_true(tau_reml([study("a", 1.0, 1.0), study("b", 1.0, 1.0)]) == 0.0)
}

///|
test "linear fit uses residual df and conservative HK not k minus one" {
  let s = regression_fixture()
  let fit = meta_regression(s, [[0.0], [1.0], [2.0]], ["dose"])
  assert_true(fit.tau2() == 0.0)
  assert_eq(fit.residual_df(), 1)
  let beta = fit.coefficients()
  assert_true(beta[0].estimate.abs() < 1.0e-10)
  assert_true((beta[1].estimate - 2.0).abs() < 1.0e-10)
  assert_true(beta[1].confidence.upper > 10.0)
  let pred = fit.predict([1.0])
  assert_true((pred.estimate - 2.0).abs() < 1.0e-10)
  assert_true(pred.prediction is None)
  beta.clear()
  assert_eq(fit.coefficients().length(), 2)
}

///|
test "moderator design rejects rank errors and forged dimensions" {
  let s = regression_fixture()
  for
    rows in [[[0.0], [0.0], [0.0]], [[0.0], [1.0]], [[0.0], [1.0], [1.0 / 0.0]]] {
    let rejected = try {
      ignore(meta_regression(s, rows, ["x"]))
      false
    } catch {
      _ => true
    }
    assert_true(rejected)
  }
  let rejected = try {
    ignore(meta_regression(s, [[0.0, 0.0], [1.0, 2.0], [2.0, 4.0]], ["x", "y"]))
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
}

///|
test "regression protocol is atomic and keeps version one compatible" {
  let v1 = process_json(
    "{\"version\":1,\"model\":\"reml\",\"studies\":[{\"id\":\"a\",\"effect\":0,\"variance\":1},{\"id\":\"b\",\"effect\":2,\"variance\":1}]}",
  )
  assert_true(v1.contains("\"ok\":true"))
  let base = "{\"version\":2,\"studies\":[{\"id\":\"a\",\"effect\":0,\"variance\":1},{\"id\":\"b\",\"effect\":2,\"variance\":1},{\"id\":\"c\",\"effect\":4,\"variance\":1}],\"names\":[\"dose\"],\"moderators\":[[0],[1],[2]]"
  assert_true(
    process_json(base + ",\"predict\":[[1]]}").contains("\"ok\":true"),
  )
  let bad = process_json(base + ",\"predict\":[[1,2]]}")
  assert_true(bad.contains("\"ok\":false"))
  assert_true(!bad.contains("\"results\""))
}

///|
test "REML intercept is invariant to study permutation and effect translation" {
  let s = [
    study("a", -0.2, 0.03),
    study("b", 0.7, 0.2),
    study("c", 1.4, 0.05),
    study("d", 0.4, 0.08),
  ]
  let original = analyze(s, model=REML, inference=Normal)
  let reverse = analyze([s[3], s[2], s[1], s[0]], model=REML, inference=Normal)
  let shifted = s.map(a => study(a.id, a.effect + 5.0, a.variance))
  let translated = analyze(shifted, model=REML, inference=Normal)
  assert_true((original.pool.tau2 - reverse.pool.tau2).abs() < 1.0e-9)
  assert_true((original.pool.tau2 - translated.pool.tau2).abs() < 1.0e-9)
  assert_true(
    (translated.pool.estimate - original.pool.estimate - 5.0).abs() < 1.0e-9,
  )
}

///|
test "multiple numeric moderators and recoding preserve predictions" {
  let s = [
    study("a", 0.1, 0.2),
    study("b", 0.8, 0.3),
    study("c", -0.4, 0.1),
    study("d", 1.3, 0.15),
    study("e", 0.5, 0.25),
    study("f", 1.9, 0.2),
  ]
  let x = [
    [0.0, 0.0],
    [1.0, 0.0],
    [0.0, 1.0],
    [1.0, 1.0],
    [2.0, 0.0],
    [2.0, 1.0],
  ]
  let fit = meta_regression(s, x, ["dose", "group"], inference=Normal)
  let changed = x.map(fn(row) { [row[0] * 10.0 + 100.0, row[1]] })
  let recoded = meta_regression(s, changed, ["dose", "group"], inference=Normal)
  assert_eq(fit.residual_df(), 3)
  assert_true((fit.tau2() - recoded.tau2()).abs() < 1.0e-9)
  let a = fit.predict([0.5, 1.0])
  let b = recoded.predict([105.0, 1.0])
  assert_true((a.estimate - b.estimate).abs() < 1.0e-9)
  assert_true((a.standard_error - b.standard_error).abs() < 1.0e-9)
  assert_true(a.prediction is Some(_))
}

///|
test "rank deficiency detected even when residual degrees of freedom exist" {
  let s = [
    study("a", 0.0, 1.0),
    study("b", 1.0, 1.0),
    study("c", 2.0, 1.0),
    study("d", 3.0, 1.0),
    study("e", 4.0, 1.0),
  ]
  for second in [[0.0, 2.0, 4.0, 6.0, 8.0], [0.0, 2.0, 4.0, 6.0, 8.0 + 1.0e-12]] {
    let x = Array::makei(5, i => [i.to_double(), second[i]])
    let bad = try {
      ignore(meta_regression(s, x, ["x", "twice-x"]))
      false
    } catch {
      _ => true
    }
    assert_true(bad)
  }
}

///|
test "regression validates alpha, names, prediction and finite arithmetic" {
  let s = regression_fixture()
  for alpha in [0.0, 0.8, 0.0 / 0.0] {
    let bad = try {
      ignore(meta_regression(s, [[0.0], [1.0], [2.0]], ["x"], alpha~))
      false
    } catch {
      _ => true
    }
    assert_true(bad)
  }
  let fit = meta_regression(s, [[0.0], [1.0], [2.0]], ["x"])
  for row in [[], [1.0, 2.0], [1.0 / 0.0]] {
    let bad = try {
      ignore(fit.predict(row))
      false
    } catch {
      _ => true
    }
    assert_true(bad)
  }
  assert_true(
    process_json("{\"version\":2,\"names\":[],\"names\":[]}").contains(
      "\"ok\":false",
    ),
  )
}
