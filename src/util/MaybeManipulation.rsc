module util::MaybeManipulation

import util::Maybe;

public &A unwrap(Maybe[&A] opt) {
  switch(opt) {
    case just(x): return x;
  }
}
