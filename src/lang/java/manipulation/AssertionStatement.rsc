module lang::java::manipulation::AssertionStatement

import ParseTree;
import String;
import lang::java::\syntax::Java18;
import util::Maybe;

public bool isStatementAnAssertion(BlockStatement statement) {
  top-down visit(statement) {
    case LocalVariableDeclarationStatement _ : return false;
    case ClassDeclaration _ : return false;
    case Statement s : return isStatementAnAssertion(s);
  }

  return false;
}

public bool isStatementAnAssertion(Statement statement) {
  top-down visit(statement) {
    case StatementWithoutTrailingSubstatement s : return isStatementAnAssertion(s);
    case LabeledStatement _ : return false;
    case IfThenStatement _ : return false;
    case IfThenElseStatement _ : return false;
    case WhileStatement _ : return false;
    case ForStatement _ : return false;
  }

  return false;
}

public bool isStatementAnAssertion(StatementWithoutTrailingSubstatement statement) {
  top-down visit(statement) {
    case Block _ : return false;
    case EmptyStatement _ : return false;
    case ExpressionStatement s : return isStatementAnAssertion(s); 
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
    case Assignment _ : return false;
    case PreIncrementExpression _ : return false;
    case PreDecrementExpression _ : return false;
    case PostIncrementExpression _ : return false;
    case PostDecrementExpression _ : return false;
    case MethodInvocation s : return isStatementAnAssertion(s); 
    case ClassInstanceCreationExpression _ : return false;
  }

  return false;
}

public bool isStatementAnAssertion(MethodInvocation statement) {
  top-down visit(statement) {
    case (MethodInvocation) `Assertions.<Identifier methodName>(<ArgumentList _>)` : {
      return methodName in assertionMethods();
    }
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
