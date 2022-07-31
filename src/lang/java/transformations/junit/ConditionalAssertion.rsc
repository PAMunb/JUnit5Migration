module lang::java::transformations::junit::ConditionalAssertion

import ParseTree;
import lang::java::\syntax::Java18; 
import lang::java::manipulation::TestMethod;
import util::Maybe;

public CompilationUnit executeConditionalAssertionTransformation(CompilationUnit unit) {
  list[tuple[Identifier name, Expression condition]] conditionalMethods = [];

  unit = top-down visit(unit) {
    case MethodDeclaration method: {
      if(isMethodATest(method)) {
        switch(applyTransformation(method)) {
          case just(transformedMethodData): {
            conditionalMethods = conditionalMethods + <transformedMethodData[1], transformedMethodData[2]>;
            insert(transformedMethodData[0]);
          }
          case nothing(): fail;
        }
      }
    }
  }
  
  return (unit | 
            declareNewMethod(t.condition, t.name, unit) | 
            tuple[Identifier name, Expression condition] t <- conditionalMethods);
}

private Maybe[tuple[MethodDeclaration declaration, Identifier enablerName, Expression condition]] applyTransformation(MethodDeclaration method) {
  Identifier testName = extractMethodName(method);

  top-down-break visit(extractMethodBody(method)) {
    case (MethodBody) `{
                      '  if(<Expression condition>) {
                      '    Assert.assertEquals(<Expression ex1>, <Expression ex2>);
                      '  }
                      '}` : {
      str conditionalMethodName = "<unparse(testName)>Condition";
      StringLiteral conditionalMethodNameLiteral = parse(#StringLiteral, "\"<conditionalMethodName>\"");
      Annotation enablerAnnotation = (Annotation) `@EnableIf(<StringLiteral conditionalMethodNameLiteral>)`;
      MethodBody refactoredBody = (MethodBody) `{
                                               '  Assert.assertEquals(<Expression ex1>, <Expression ex2>);
                                               '}`;
      MethodDeclaration transformedMethod = replaceMethodBody(
                                              addMethodAnnotation(method, enablerAnnotation), 
                                              refactoredBody
                                            );
      return just(<transformedMethod, parse(#Identifier, conditionalMethodName), condition>);
    }
    case MethodBody _: fail;
  }

  return nothing();
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
