module lang::java::transformations::junit::ConditionalAssertion

import lang::java::\syntax::Java18; 
import ParseTree;
import IO;

public CompilationUnit executeConditionalAssertionTransformation(CompilationUnit unit) {
  list[tuple[str, Expression]] conditionalMethods = [];

  unit = top-down visit(unit) {
    case (MethodDeclaration) `@Test
                             'public void <Identifier testName>() {
                             '  if(<Expression condition>) {
                             '    Assert.assertEquals(<Expression ex1>, <Expression ex2>);
                             '  }
                             '}` : {
                                str conditionalMethodName = unparse(testName) + "Condition";
                                conditionalMethods = conditionalMethods + <conditionalMethodName, condition>;
                                insert((MethodDeclaration) `@Test
                                                           'public void <Identifier testName>() {
                                                           '  Assert.assertEquals(<Expression ex1>, <Expression ex2>);
                                                           '}`);
                               }
  }
  
  for(tuple[str, Expression] t <- conditionalMethods) {
    unit = declareNewMethod(t[1], parse(#Identifier, t[0]), unit);
  }

  return unit;
}

public CompilationUnit declareNewMethod(Expression expression, Identifier methodName, CompilationUnit unit) {
  print("Method: ");
  println(methodName);
  MethodDeclaration conditionalMethod = (MethodDeclaration) `public boolean <Identifier methodName>() {
                                                            '  return <Expression expression>;
                                                            '}`;
   unit = top-down visit(unit) {
      case (ClassBodyDeclaration) `<ClassBodyDeclaration declarations>` => (ClassBodyDeclaration) `<ClassBodyDeclaration declarations>
                                                                                                     '<MethodDeclaration conditionalMethod>`
    }
    return unit;
}

public bool isStatementConditionalAssertion(BlockStatements s) {
  top-down visit(s) {
    case (Statement) `if(<Expression _>) {
                     '  <AssertStatement _>
                     '}` : return true;
    case (Statement) `if(<Expression _>) {
                     '  <AssertStatement _>
                     '}` : return true;
  }

  return false;
}
