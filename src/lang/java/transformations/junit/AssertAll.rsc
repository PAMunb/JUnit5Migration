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
  list[Expression] assertionLambdaGroup = [];
  Maybe[BlockStatement] previousStmt = nothing();

  top-down-break visit(extractMethodBody(method)) {
    case BlockStatement s : {
      if(isStatementAnAssertion(s)) {
        LambdaBody assertion = parse(#LambdaBody, unparse(s)[..-1]);
        assertionLambdaGroup += (Expression) `() -\> <LambdaBody assertion>`;
      } else {
        if(isSomething(previousStmt) && isStatementAnAssertion(unwrap(previousStmt))) {
          if(size(assertionLambdaGroup) > 1) {
            refactoredStatements += buildAssertAll(assertionLambdaGroup);
          } else {
            refactoredStatements += head(assertionLambdaGroup);
          }
          assertionLambdaGroup = [];
        }
        refactoredStatements += s;
      }
      previousStmt = just(s);
    }
  }

  if(size(assertionLambdaGroup) > 1) {
    refactoredStatements += buildAssertAll(assertionLambdaGroup);
  } else {
    refactoredStatements += head(assertionLambdaGroup);
  }

  str methodBody = ("{\n" | it + unparse(s) + "\n" | BlockStatement s <- refactoredStatements) + "}";

  return replaceMethodBody(method, parse(#MethodBody, methodBody));
}

private BlockStatement buildAssertAll(list[Expression] assertionsAsLambdas) {
  Expression firstAssertionLambda = head(assertionsAsLambdas);
  str assertAllInvocationArguments = unparse(firstAssertionLambda);

  for (Expression argument <- tail(assertionsAsLambdas)) {
    assertAllInvocationArguments += ",\n<unparse(argument)>";
  }

  ArgumentList lambdas = parse(#ArgumentList, assertAllInvocationArguments);
  return (BlockStatement) `Assert.assertAll(
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

  return assertionCount > 0;
}
