module lang::java::transformations::junit::AssertAll

import ParseTree;
import lang::java::\syntax::Java18;
import lang::java::manipulation::AssertionStatement;
import lang::java::manipulation::TestMethod;

public CompilationUnit executeAssertAllTransformation(CompilationUnit unit) {
  unit = top-down visit(unit) {
    case MethodDeclaration method => declareTestWithAssertAll(method)
                             when isMethodATest(method) && allStatementsAreAssertions(method)
  }

  return unit;
}

public MethodDeclaration declareTestWithAssertAll(MethodDeclaration method) {
  list[Expression] assertionsAsLambdas = [];

  top-down visit(method) {
    case Statement s : {
      if(isStatementAnAssertion(s)) {
        LambdaBody assertion = parse(#LambdaBody, unparse(s)[..-1]);
        assertionsAsLambdas += (Expression) `() -\> <LambdaBody assertion>`;
      }
    }
  }

  Statement assertAll = buildAssertAll(assertionsAsLambdas);
  MethodBody newBody = (MethodBody) `{
                                    ' <Statement assertAll>
                                    '}`;

  return replaceMethodBody(method, newBody);
}

private Statement buildAssertAll(list[Expression] assertionsAsLambdas) {
  Expression firstAssertionLambda = head(assertionsAsLambdas);
  str assertAllInvocationArguments = unparse(firstAssertionLambda);

  for (Expression argument <- tail(assertionsAsLambdas)) {
    assertAllInvocationArguments = assertAllInvocationArguments + ", <unparse(argument)>";
  }

  ArgumentList lambdas = parse(#ArgumentList, assertAllInvocationArguments);
  return (Statement) `Assert.assertAll(
                     ' <ArgumentList lambdas>
                     ');`;
}

public bool allStatementsAreAssertions(MethodDeclaration method) {
  MethodBody methodBody;
  top-down-break visit(method) {
    case MethodBody b : methodBody = b;
  }

  int assertionCount = 0;
  top-down visit(methodBody) {
    case Statement s: if(isStatementAnAssertion(s)) {
        assertionCount += 1;
      } else {
        return false;
      }
  }

  return assertionCount > 0;
}
