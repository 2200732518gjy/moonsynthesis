///| Reporting software converts event summaries and emits exchangeable reports.
fn main raise {
  let studies = [
    @synthesis.log_risk_ratio("study-1", { events: 8, total: 80 }, { events: 15, total: 75 }),
    @synthesis.log_risk_ratio("study-2", { events: 12, total: 100 }, { events: 19, total: 95 }),
    @synthesis.log_risk_ratio("study-3", { events: 0, total: 60 }, { events: 5, total: 65 }, correction=@synthesis.HalfIfZero),
  ]
  println(@synthesis.render_csv(studies))
  let plot = @synthesis.render_forest(studies, title="Log risk ratios")
  assert_true(plot.contains("<svg"))
  let fit = @synthesis.analyze(studies)
  println(@synthesis.exponentiate_interval(fit.confidence).to_json().stringify())
}
