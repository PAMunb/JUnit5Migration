module util::MaybeManipulation

import util::Maybe;

public &A unwrap(Maybe[&A] opt) {
  switch(opt) {
    case just(x): return x;
  }
}

public bool isSomething(Maybe[&A] opt) {
  return opt != nothing();
}

public bool isNothing(Maybe[&A] opt) {
  return opt == nothing();
}
