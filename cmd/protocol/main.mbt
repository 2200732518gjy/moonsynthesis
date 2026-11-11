///|
/// The last argument is one JSON document. Host adapters provide bounded IO.
fn main {
  let args = @env.args()
  let text = if args.length() > 0 { args[args.length() - 1] } else { "" }
  println(@synthesis.process_json(text))
}
