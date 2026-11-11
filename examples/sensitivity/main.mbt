///|
/// A measurement platform evaluates stability across independent replications.
fn main raise {
  let studies = [
    @synthesis.study("replication-1", 0.1, 0.02, group="lab-a"),
    @synthesis.study("replication-2", 0.2, 0.03, group="lab-a"),
    @synthesis.study("replication-3", 0.5, 0.04, group="lab-b"),
    @synthesis.study("replication-4", 0.8, 0.06, group="lab-b"),
  ]
  let response = @synthesis.execute({
    studies,
    model: @synthesis.PM,
    inference: @synthesis.ModifiedHK,
    alpha: 0.05,
    outputs: ["summary", "leave-one-out", "cumulative", "subgroups"],
  })
  println(response.stringify())
  assert_eq(@synthesis.leave_one_out(studies).length(), 4)
  assert_eq(@synthesis.cumulative(studies).length(), 3)
}
