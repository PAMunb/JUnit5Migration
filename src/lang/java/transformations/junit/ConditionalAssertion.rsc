module lang::java::transformations::junit::ConditionalAssertion

import lang::java::\syntax::Java18; 
import IO;

public CompilationUnit executeConditionalAssertionTransformation(CompilationUnit unit) {
  unit = top-down visit(unit) {
    case (MethodDeclaration) `@Test
                             'public void <Identifier testName>() {
                             '  if(<Expression condition>) {
                             '    Assert.assertEquals(<Expression ex1>, <Expression ex2>);
                             '  }
                             '}` : {
                               if(isStatementConditionalAssertion(s)) {
                                insert((MethodDeclaration) `@Test
                                                    'public void <Identifier testName>() {
                                                    '  Assert.assertEquals(<Expression ex1>, <Expression ex2>);
                                                    '}`);
                                // declareNewMethod(condition, unit);
                               }
                             }
  }
  return unit;
}

public CompilationUnit declareNewMethod(Expression expression, CompilationUnit unit) {
  MethodDeclaration conditionalMethod = (MethodDeclaration) `public boolean testCondition() {
                                                           '  return <Expression condition>;
                                                           '}`;
   unit = top-down visit(unit) {
      case (ClassBodyDeclaration*) `<ClassBodyDeclaration* declarations>` => (ClassBodyDeclaration*) `<ClassBodyDeclaration* declarations>
                                                                                                     '<MethodDeclaration conditionalMethod>`;
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
