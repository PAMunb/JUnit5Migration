module lang::java::transformations::junit::AssertAll

import ParseTree;
import lang::java::\syntax::Java18;
import lang::java::manipulation::AssertionStatement;
import lang::java::manipulation::TestMethod;
import util::Maybe;
import util::MaybeManipulation;

public CompilationUnit executeAssertAllTransformation(CompilationUnit unit) {
  unit = top-down visit(unit) {
    case MethodDeclaration method => declareTestWithAssertAll(method)
                             when isMethodATest(method) && hasSequentialAssertions(method)
  }

  return unit;
}

public MethodDeclaration declareTestWithAssertAll(MethodDeclaration method) {
  list[BlockStatement] refactoredStatements = [];
  list[BlockStatement] assertionGroup = [];
  Maybe[BlockStatement] previousStmt = nothing();

  top-down-break visit(extractMethodBody(method)) {
    case BlockStatement s : {
      if(isStatementAnAssertion(s)) {
        assertionGroup += s;
      } else {
        if(isSomething(previousStmt) && isStatementAnAssertion(unwrap(previousStmt))) {
          if(size(assertionGroup) > 1) {
            refactoredStatements += buildAssertAll(assertionGroup);
          } else if (size(assertionGroup) == 1) {
            refactoredStatements += head(assertionGroup);
          }
          assertionGroup = [];
        }
        refactoredStatements += s;
      }
      previousStmt = just(s);
    }
  }

  if(size(assertionGroup) > 1) {
    refactoredStatements += buildAssertAll(assertionGroup);
  } else if (size(assertionGroup) == 1) {
    refactoredStatements += head(assertionGroup);
  }

  str methodBody = ("{\n" | it + unparse(s) + "\n" | BlockStatement s <- refactoredStatements) + "}";

  return replaceMethodBody(method, parse(#MethodBody, methodBody));
}

private BlockStatement buildAssertAll(list[BlockStatement] assertionGroup) {
  LambdaBody firstAssertion = parse(#LambdaBody, unparse(head(assertionGroup))[..-1]);
  str assertAllInvocationArguments = unparse((Expression) `() -\> <LambdaBody firstAssertion>`);

  for (BlockStatement assertionStmt <- tail(assertionGroup)) {
    assertion = parse(#LambdaBody, unparse(assertionStmt)[..-1]);
    assertAllInvocationArguments += ",\n<unparse((Expression) `() -\> <LambdaBody assertion>`)>";
  }

  ArgumentList lambdas = parse(#ArgumentList, assertAllInvocationArguments);
  return (BlockStatement) `Assertions.assertAll(
                          ' <ArgumentList lambdas>
                          ');`;
}

public bool hasSequentialAssertions(MethodDeclaration method) {
  MethodBody methodBody;
  top-down-break visit(method) {
    case MethodBody b : methodBody = b;
  }

  int assertionCount = 0;
  top-down-break visit(methodBody) {
    case BlockStatement s: if(isStatementAnAssertion(s)) {
        assertionCount += 1;
      } else {
        if(assertionCount != 0) return assertionCount > 1;
      }
  }

  return assertionCount > 1;
}
