module lang::java::transformations::junit::AssertAll

import lang::java::\syntax::Java18; 
import ParseTree;

public CompilationUnit executeAssertAllTransformation(CompilationUnit unit) {
  list[tuple[Identifier, Expression]] conditionalMethods = [];

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

  BlockStatements assertions = top-down visit(testStatements) {
    case (Statement) `Assert.assertEquals(<Expression a> , <Expression b>);` : {
      Expression expressionAsLambda = (Expression) `() -\> Assert.assertEquals(<Expression a> , <Expression b>)`;
      assertionsAsLambdas = assertionsAsLambdas + expressionAsLambda; 
    }
  };

  Expression firstAssertion = head(assertionsAsLambdas);
  str assertAllArguments = unparse(firstAssertion);

  for (Expression argument <- tail(assertionsAsLambdas)) {
    assertAllArguments = assertAllArguments + ", <unparse(argument)>";
  }
  ArgumentList argList = parse(#ArgumentList, assertAllArguments);
  Statement assertAllInvocation = (Statement) `assertAll(<ArgumentList argList>);`;

  MethodDeclaration newTest = (MethodDeclaration) `@Test
                                                  'public void <Identifier testName>() {
                                                  '  <Statement assertAllInvocation>
                                                  '}`;

  return newTest;
}

public bool allStatementsAreAssertions(BlockStatements testStatements) {
  int assertionCount = 0;
  top-down visit(testStatements) {
    case (Statement) `Assert.assertEquals(<Expression _> , <Expression _>);` : assertionCount += 1;
    case (Statement) `<Statement _>`: return false;
  }

  return assertionCount > 0;
}
