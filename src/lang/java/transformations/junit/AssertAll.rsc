module lang::java::transformations::junit::AssertAll

import lang::java::\syntax::Java18;
import ParseTree;

public CompilationUnit executeAssertAllTransformation(CompilationUnit unit) {
  unit = top-down visit(unit) {
    case (MethodDeclaration) `@Test
                             'public void <Identifier testName>() {
                             '  <BlockStatements testStatements>
                             '}` => declareTestWithAssertAll(testName, testStatements)
                             when allStatementsAreAssertions(testStatements)
  }

  return unit;
}

public MethodDeclaration declareTestWithAssertAll(Identifier testName, BlockStatements testStatements) {
  list[Expression] assertionsAsLambdas = [];

  top-down visit(testStatements) {
    case (Statement) `Assert.assertEquals(<Expression a> , <Expression b>);` : {
      Expression expressionAsLambda = (Expression)
                                      `() -\> Assert.assertEquals(<Expression a> , <Expression b>)`;
      assertionsAsLambdas = assertionsAsLambdas + expressionAsLambda;
    }
  };

  ArgumentList argList = buildAssertAllInvocationArguments(assertionsAsLambdas);
  Statement assertAllInvocation = (Statement) `assertAll(<ArgumentList argList>);`;

  return buildRefactoredTest(testName, assertAllInvocation);
}

private MethodDeclaration buildRefactoredTest(Identifier testName, Statement assertAllStatement) {
  return (MethodDeclaration) `@Test
                             'public void <Identifier testName>() {
                             '  <Statement assertAllStatement>
                             '}`;
}

private ArgumentList buildAssertAllInvocationArguments(list[Expression] assertionsAsLambdas) {
  Expression firstAssertionLambda = head(assertionsAsLambdas);
  str assertAllInvocationArguments = unparse(firstAssertionLambda);

  for (Expression argument <- tail(assertionsAsLambdas)) {
    assertAllInvocationArguments = assertAllInvocationArguments + ", <unparse(argument)>";
  }

  return parse(#ArgumentList, assertAllInvocationArguments);;
}

public bool allStatementsAreAssertions(BlockStatements testStatements) {
  int assertionCount = 0;
  top-down visit(testStatements) {
    case (Statement) `Assert.assertEquals(<Expression _> , <Expression _>);` : assertionCount += 1;
    case (Statement) `<Statement _>`: return false;
  }

  return assertionCount > 0;
}
