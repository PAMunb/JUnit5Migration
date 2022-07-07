module lang::java::transformations::junit::ConditionalAssertion

import lang::java::\syntax::Java18; 
import ParseTree;

public CompilationUnit executeConditionalAssertionTransformation(CompilationUnit unit) {
  list[tuple[Identifier, Expression]] conditionalMethods = [];

  unit = top-down visit(unit) {
    case (MethodDeclaration) `@Test
                             'public void <Identifier testName>() {
                             '  if(<Expression condition>) {
                             '    Assert.assertEquals(<Expression ex1>, <Expression ex2>);
                             '  }
                             '}` : {
                                str conditionalMethodName = unparse(testName) + "Condition";
                                conditionalMethods = conditionalMethods + <parse(#Identifier, conditionalMethodName), condition>;
                                StringLiteral conditionalMethodNameLiteral = parse(#StringLiteral, "\"<conditionalMethodName>\"");
                                insert((MethodDeclaration) `@Test
                                                           '@EnableIf(<StringLiteral conditionalMethodNameLiteral>)
                                                           'public void <Identifier testName>() {
                                                           '  Assert.assertEquals(<Expression ex1>, <Expression ex2>);
                                                           '}`);
                               }
  }
  
  for(tuple[Identifier, Expression] t <- conditionalMethods) {
    unit = declareNewMethod(t[1], t[0], unit);
  }

  return unit;
}

private CompilationUnit declareNewMethod(Expression expression, Identifier methodName, CompilationUnit unit) {
  MethodDeclaration conditionalMethod = (MethodDeclaration) `public boolean <Identifier methodName>() {
                                                            '  return <Expression expression>;
                                                            '}`;
  unit = top-down visit(unit) {
      case (ClassBody) `{ <ClassBodyDeclaration* declarations> }` =>  (ClassBody) `{ 
                                                                      '   <ClassBodyDeclaration* declarations> 
                                                                      '   <MethodDeclaration conditionalMethod>
                                                                      '}`                                                                                                 
  }
  return unit;
}

public bool isStatementConditionalAssertion(BlockStatements s) {
  top-down visit(s) {
    case (Statement) `if(<Expression _>) {
                     '   Assert.assertEquals(<Expression _>, <Expression _>);
                     '}` : return true; 
  }

  return false;
}
