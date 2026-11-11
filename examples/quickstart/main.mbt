///|
/// Review analysts combine independent continuous outcomes without raw records.
fn main raise {
  let trials = [
    @synthesis.mean_difference("A", { n: 40, mean: 4.2, sd: 1.5, }, {
      n: 40,
      mean: 3.6,
      sd: 1.4,
    }),
    @synthesis.mean_difference("B", { n: 55, mean: 5.0, sd: 1.9, }, {
      n: 50,
      mean: 4.1,
      sd: 1.6,
    }),
    @synthesis.mean_difference("C", { n: 35, mean: 3.5, sd: 1.2, }, {
      n: 38,
      mean: 3.3,
      sd: 1.3,
    }),
  ]
  let result = @synthesis.analyze(trials)
  println(result.to_json().stringify())
  assert_eq(result.count, 3)
  assert_true(result.pool.estimate() > 0.0)
}
