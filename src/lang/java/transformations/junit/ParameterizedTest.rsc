module lang::java::transformations::junit::ParameterizedTest

import List;
import ParseTree;
import lang::java::\syntax::Java18;
import lang::java::manipulation::AssertionStatement;
import lang::java::manipulation::TestMethod;
import util::Maybe;
import util::MaybeManipulation;

data Argument = argument(str argType, Expression expression);

public CompilationUnit executeParameterizedTestTransformation(CompilationUnit unit) {
  unit = top-down visit(unit) {
    case MethodDeclaration method => parameterizeTest(method)
                                      when (isMethodATest(method) && 
                                              testHasMultipleStatements(extractMethodBody(method)) &&
                                              allStatementsAreTheSameAssertion(extractMethodBody(method)))
  }

  return unit;
}

private MethodDeclaration parameterizeTest(MethodDeclaration method) {
  list[ArgumentList] args = [];

  switch(extractAssertionsArguments(extractMethodBody(method))) {
    case just(argList): args = argList;
    case nothing(): return method;
  }

  list[list[Argument]] invocationArgs = [];
  switch(extractArguments(args)) {
    case just(arguments): invocationArgs = arguments;
    case nothing(): return method;
  }

  if(!allArgumentsHaveSameType(invocationArgs)) return method;

  return refactorTest(method, invocationArgs);
}

private MethodDeclaration refactorTest(MethodDeclaration method, list[list[Argument]] invocationArgs) {
  list[FormalParameter] methodParams = [];
  str assertionArgs = "";
  int i = 0;
  for(Argument arg <- head(invocationArgs)) {
    str argName = "arg<i>";
    methodParams += parse(#FormalParameter, "<arg.argType> <argName>");
    assertionArgs += "<argName>, ";
    i += 1;
  }
  method = (method | addMethodParameter(it, param) | FormalParameter param <- methodParams);

  ArgumentList assertionArgList = parse(#ArgumentList, assertionArgs[..-2]);
  MethodInvocation assertionWithParameterizedArgs = top-down-break visit(
      extractFirstMethodInvocation(extractMethodBody(method))
    ) {
    case ArgumentList _ => assertionArgList
  };

  MethodBody refactoredBody = (MethodBody) `{
                                           '  <MethodInvocation assertionWithParameterizedArgs>;
                                           '}`;

  return addParameterizedTestAnnotation(replaceMethodBody(method, refactoredBody), invocationArgs);;
}

private MethodDeclaration addParameterizedTestAnnotation(
    MethodDeclaration method,
    list[list[Argument]] arguments
  ) {
  str argsAsString = "\n";
  for(list[Argument] args <- arguments) {
    argsAsString += 
      ("\"" | it + unparse(arg.expression) + ", " | Argument arg <- args)[..-2] + 
      "\",\n";
  }

  Annotation csvSource = parse(#Annotation, "@CsvSource({<argsAsString[..-2]>})");
  method = addMethodAnnotation(method, csvSource);
  method = unwrap(
          replaceMethodAnnotation(
            method,
            (Annotation) `@Test`,
            (Annotation) `@ParameterizedTest`
          )
        );
  return method;
}

private MethodInvocation extractFirstMethodInvocation(MethodBody body) {
  top-down visit(body) {
    case MethodInvocation m : return m;
  }
}

private bool allArgumentsHaveSameType(list[list[Argument]] args) {
  list[Argument] firstArgList = head(args);
  for(list[Argument] argList <- tail(args)) {
    int i = 0;
    for(Argument arg <- argList) {
      if(arg.argType != firstArgList[i].argType) return false;
      i += 1;
    }
  }

  return true;
}

private Maybe[list[list[Argument]]] extractArguments(list[ArgumentList] args) {
  if(isEmpty(args)) return nothing();

  list[list[Argument]] invocationArgs = [];
  for(ArgumentList argList <- args) {
    list[Argument] argsListArguments = [];

    top-down-break visit(argList) {
      case Expression e : {
        switch(extractArgumentType(e)) {
          case just(t) : argsListArguments += argument(t, e);
          case nothing() : return nothing();
        }
      }
    }

    if(!isEmpty(invocationArgs)) {
      if(size(head(invocationArgs)) != size(argsListArguments) || isEmpty(argsListArguments)) {
        return nothing();
      }
    }

    invocationArgs += [argsListArguments];
  }

  return just(invocationArgs);
}

private Maybe[str] extractArgumentType(Expression ex) {
  top-down-break visit(ex) {
    case IntegerLiteral i : if(equalUnparsed(ex, i)) return just("int");
    case StringLiteral s : if(equalUnparsed(ex, s)) return just("String");
    case BooleanLiteral b : if(equalUnparsed(ex, b)) return just("boolean");
  }

  return nothing();
}

private bool equalUnparsed(&A argument, &B literal) {
  return unparse(argument) == unparse(literal);
}

private Maybe[list[ArgumentList]] extractAssertionsArguments(MethodBody body) {
  list[ArgumentList] args = [];

  top-down visit(body) {
    case MethodInvocation m : top-down visit(m) {
      case ArgumentList argList : args += argList;
    }
  }

  if(isEmpty(args)) return nothing();

  return just(args);
}

private bool testHasMultipleStatements(MethodBody body) {
  int statementCount = 0;

  top-down visit(body) {
    case Statement s : {
      statementCount += 1;
      if(statementCount > 1) return true;
    }
  }

  return false;
}

private bool allStatementsAreTheSameAssertion(MethodBody body) {
  Maybe[Statement] firstAssertion = nothing();
  top-down visit(body) {
    case Statement s : {
      if(!isStatementAnAssertion(s)) return false;

      switch(firstAssertion) {
        case just(firstAssert): if(!statementsAreTheSameAssertion(s, firstAssert)) {
          return false;
        }
        case nothing(): firstAssertion = just(s);
      }
    }
  }

  return true;
}

private bool statementsAreTheSameAssertion(Statement a, Statement b) {
  Maybe[MethodInvocation] methodA = nothing();
  top-down-break visit(a) {
    case MethodInvocation m : methodA = just(m);
  }
  if(isNothing(methodA)) return false;

  Maybe[MethodInvocation] methodB = nothing();
  top-down-break visit(b) {
    case MethodInvocation m : methodB = just(m);
  }
  if(isNothing(methodB)) return false;

  MethodInvocation arglessMethodA = top-down-break visit(unwrap(methodA)) {
                                      case ArgumentList _ => (ArgumentList) `sameArg`
                                    };
  MethodInvocation arglessMethodB = top-down-break visit(unwrap(methodB)) {
                                      case ArgumentList _ => (ArgumentList) `sameArg`
                                    };

  return arglessMethodA == arglessMethodB;
}
