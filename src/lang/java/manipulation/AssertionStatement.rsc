module lang::java::manipulation::AssertionStatement

import ParseTree;
import String;
import lang::java::\syntax::Java18;
import util::Maybe;

public bool isStatementAnAssertion(Statement statement) {
  top-down visit(statement) {
    case StatementWithoutTrailingSubstatement s : return isStatementAnAssertion(s);
  }

  return false;
}

public bool isStatementAnAssertion(StatementWithoutTrailingSubstatement statement) {
  top-down visit(statement) {
    case ExpressionStatement s : return isStatementAnAssertion(s);
  }

  return false;
}

public bool isStatementAnAssertion(ExpressionStatement statement) {
  top-down visit(statement) {
    case StatementExpression s : return isStatementAnAssertion(s);
  }

  return false;
}

public bool isStatementAnAssertion(StatementExpression statement) {
  top-down visit(statement) {
    case MethodInvocation s : return isStatementAnAssertion(s);
  }

  return false;
}

public bool isStatementAnAssertion(MethodInvocation statement) {
  top-down visit(statement) {
    case (MethodInvocation) `Assert.<Identifier methodName>(<ArgumentList _>)` : {
      return methodName in assertionMethods();
    }
    case (MethodInvocation) `<MethodName methodName>(<ArgumentList _>)` : {
      return parse(#Identifier, unparse(methodName)) in assertionMethods();
    }
  }

  return false;
}

private list[Identifier] assertionMethods() {
  return [
    (Identifier) `assertArrayEquals`,
    (Identifier) `assertEquals`,
    (Identifier) `assertFalse`,
    (Identifier) `assertNotNull`,
    (Identifier) `assertNotSame`,
    (Identifier) `assertNull`,
    (Identifier) `assertSame`,
    (Identifier) `assertThat`,
    (Identifier) `assertTrue`,
    (Identifier) `fail`
  ];
}
