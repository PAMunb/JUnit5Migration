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
            conditionalMethods += <transformedMethodData[1], transformedMethodData[2]>;
            insert(transformedMethodData[0]);
          }
          case nothing(): fail;
        }
      }
    }
  }

  return (unit |
            declareNewMethod(t.condition, t.name, it) |
            tuple[Identifier name, Expression condition] t <- conditionalMethods);
}

private Maybe[tuple[MethodDeclaration declaration, Identifier enablerName, Expression condition]] applyTransformation(MethodDeclaration method) {
  Identifier testName = extractMethodName(method);

  top-down-break visit(extractMethodBody(method)) {
    case (MethodBody) `{
                      '  if(<Expression condition>) <Statement statement>
                      '}` : {
      if(!isStatementABlock(statement)) fail;
      str conditionalMethodName = "<unparse(testName)>Condition";
      StringLiteral conditionalMethodNameLiteral = parse(#StringLiteral, "\"<conditionalMethodName>\"");
      Annotation enablerAnnotation = (Annotation) `@EnableIf(<StringLiteral conditionalMethodNameLiteral>)`;
      MethodBody refactoredBody = parse(#MethodBody, unparse(statement));
      MethodDeclaration transformedMethod = replaceMethodBody(
                                              addMethodAnnotation(method, enablerAnnotation),
                                              refactoredBody
                                            );
      return just(<transformedMethod, parse(#Identifier, conditionalMethodName), condition>);
    }
    case MethodBody _: return nothing();
  }

  return nothing();
}

private bool isStatementABlock(Statement statement) {
  top-down visit(statement) {
    case StatementWithoutTrailingSubstatement s : top-down visit(s) {
      case Block b : return true;
      case EmptyStatement _ : return false;
      case ExpressionStatement _ : return false;
      case AssertStatement _ : return false;
      case SwitchStatement _ : return false;
      case DoStatement _ : return false;
      case BreakStatement _ : return false;
      case ContinueStatement _ : return false;
      case ReturnStatement _ : return false;
      case SynchronizedStatement _ : return false;
      case ThrowStatement _ : return false;
      case TryStatement _ : return false;
    }
    case LabeledStatement _ : return false;
    case IfThenStatement _ : return false;
    case IfThenElseStatement _ : return false;
    case WhileStatement _ : return false;
    case ForStatement _ : return false;
  }
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
