///|
/// Study-level meta-regression for a synthetic measurement synthesis task.
fn main raise {
  let studies = [
    @synthesis.study("a", 0.1, 0.2),
    @synthesis.study("b", 0.8, 0.3),
    @synthesis.study("c", -0.4, 0.1),
    @synthesis.study("d", 1.3, 0.15),
    @synthesis.study("e", 0.5, 0.25),
    @synthesis.study("f", 1.9, 0.2),
  ]
  let fit = @synthesis.meta_regression(
    studies,
    [[0.0, 0.0], [1.0, 0.0], [0.0, 1.0], [1.0, 1.0], [2.0, 0.0], [2.0, 1.0]],
    ["dose", "group"],
    inference=@synthesis.Normal,
  ) catch {
    _ => abort("invalid example dataset")
  }
  println(fit.to_json().stringify())
  let prediction = fit.predict([0.5, 1.0]) catch {
    _ => abort("invalid prediction")
  }
  println(prediction.to_json().stringify())
}
