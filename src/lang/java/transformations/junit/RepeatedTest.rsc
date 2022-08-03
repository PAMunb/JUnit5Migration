module lang::java::transformations::junit::RepeatedTest

import Map;
import ParseTree;
import Set;
import String;
import lang::java::\syntax::Java18;
import lang::java::manipulation::AssertionStatement;
import lang::java::manipulation::TestMethod;
import util::Math;
import util::Maybe;
import util::MaybeManipulation;
import IO;

data ForStatementData = forStatementData(
    map[Identifier, int] forInitValues,
    StatementExpressionList forUpdateExpression,
    list[Identifier] forUpdateIdentifiers,
    list[tuple[Identifier id, str op, IntegerLiteral vl]] forConditionParts,
    Statement statement
);

public CompilationUnit executeRepeatedTestTransformation(CompilationUnit unit) {
  unit = top-down visit(unit) {
    case MethodDeclaration method : {
                               switch(extractForStatementData(extractMethodBody(method))) {
                                 case just(forStmtData): {
                                   if(isTransformationApplyable(forStmtData) && isSomething(resolveIterationCount(forStmtData))) {
                                     insert(declareTestWithRepeatedTest(method, forStmtData));
                                   }
                                 }
                                 case nothing(): fail;
                               }
                             }
  }

  return unit;
}

public MethodDeclaration declareTestWithRepeatedTest(MethodDeclaration method, ForStatementData f) {
  IntegerLiteral iterationCount = parse(#IntegerLiteral, toString(unwrap(resolveIterationCount(f))));
  Annotation repeatedTestAnnotation = (Annotation) `@RepeatedTest(<IntegerLiteral iterationCount>)`;
  MethodBody newBody = parse(#MethodBody, unparse(f.statement));

  return replaceMethodBody(addMethodAnnotation(method, repeatedTestAnnotation), newBody);
}

private Maybe[int] resolveIterationCount(ForStatementData f) {
  tuple[Identifier id, str op, IntegerLiteral vl] forCondition = head(f.forConditionParts);

  if(forCondition.id notin f.forInitValues) {
    return nothing();
  }
str updateExpression = unparse(f.forUpdateExpression);
  str id = unparse(head(f.forUpdateIdentifiers));

  int count = toInt(unparse(forCondition.vl)) - f.forInitValues[forCondition.id];
  if(count < 0) count *= -1;


  switch(forCondition.op) {
    case "\<": {
      list[str] recognizedUpdates = ["<id>++", "<id> += 1", "<id>+=1"];
      if(updateExpression in recognizedUpdates) return just(count);
    }
    case "\<=": {
      list[str] recognizedUpdates = ["<id>++", "<id> += 1", "<id>+=1"];
      if(updateExpression in recognizedUpdates) return just(count + 1);
    }
    case "\>": {
      list[str] recognizedUpdates = ["<id>--", "<id> -= 1", "<id>-=1"];
      if(updateExpression in recognizedUpdates) return just(count);
    }
    case "\>=": {
      list[str] recognizedUpdates = ["<id>--", "<id> -= 1", "<id>-=1"];
      if(updateExpression in recognizedUpdates) return just(count + 1);
    }
  }

  return nothing();
}

private bool isTransformationApplyable(ForStatementData forStmtData) {
  return !statementUsesForUpdateIdentifier(forStmtData) &&
          statementRepeatsAssertionsOnly(forStmtData) &&
          conditionUsesSingleUpdateIdentifier(forStmtData);
}

private bool statementUsesForUpdateIdentifier(ForStatementData f) {
  top-down visit(f.statement) {
    case (Identifier) `<Identifier i>`: if(i in f.forUpdateIdentifiers) return true;
  }

  return false;
}

private list[Identifier] extractIdentifiers(StatementExpressionList expressions) {
  list[Identifier] identifiers = [];

  top-down visit(expressions) {
    case (Identifier) `<Identifier i>`: identifiers = identifiers + i;
  }

  return identifiers;
}

private bool statementRepeatsAssertionsOnly(ForStatementData f) {
  int assertionCount = 0;
  top-down-break visit(f.statement) {
    case Block b : top-down visit(b) {
      case BlockStatement bs : {
        if(isStatementAnAssertion(bs)) {
          assertionCount += 1;
        } else {
          return false;
        }
      }
    }
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

  return assertionCount > 0;
}

private bool conditionUsesSingleUpdateIdentifier(ForStatementData f) {
  return size(f.forConditionParts) == 1 &&
          size(f.forUpdateIdentifiers) == 1 &&
          head(f.forConditionParts)[0] == head(f.forUpdateIdentifiers);
}

public Maybe[ForStatementData] extractForStatementData(MethodBody methodBody) {
  Maybe[ForStatement] forStatement = extractForStatement(methodBody);
  if(isNothing(forStatement)) return nothing();

  Maybe[ForStatementData] forStmtData = nothing();

  top-down visit(unwrap(forStatement)) {
    case (ForStatement)
            `for(<ForInit fi>; <Expression ex>; <ForUpdate fu>) <Statement stmt>` : {
              forStmtData = just(forStatementData(
                  extractForInitValues(fi),
                  parse(#StatementExpressionList, unparse(fu)),
                  extractIdentifiers(parse(#StatementExpressionList, unparse(fu))),
                  extractForConditionParts(ex),
                  stmt
                  ));
            }
  }

  return forStmtData;
}

private Maybe[ForStatement] extractForStatement(MethodBody methodBody) {
  top-down visit(methodBody) {
    case (MethodBody) `{
                      ' <ForStatement f>
                      '}` : return just(f);
  }

  return nothing();
}

private map[Identifier, int] extractForInitValues(ForInit fi) {
  map[Identifier, int] values = ( );

  top-down visit(fi) {
    case (StatementExpression) `<LeftHandSide id> = <Expression val>`: {
      Maybe[Identifier] identifier = nothing();

      top-down visit(id) {
        case Identifier i: identifier = i;
      };

      Maybe[int] v = nothing();

      top-down visit(val) {
        case IntegerLiteral intl: v = intl;
      };

      if(isSomething(identifier) && isSomething(v) &&
          unparse(unwrap(identifier)) == unparse(id) && unparse(unwrap(v)) == unparse(val)) {
        values += (unwrap(identifier) : unwrap(v));
      }
    }
    case (LocalVariableDeclaration) `<UnannType t> <VariableDeclaratorList declarations>` : {
      top-down visit(t) {
        case IntegralType iType : {
          str iTypeStr = unparse(iType);
          if(!(iTypeStr == "int" || iTypeStr == "short")) fail;
        }
      }

      top-down visit(declarations) {
        case (VariableDeclarator) `<VariableDeclaratorId id> = <VariableInitializer i>`: {
          Maybe[int] v = nothing();

          top-down visit(i) {
            case IntegerLiteral intl: if(unparse(intl) == unparse(i)) {
              v = just(toInt(unparse(intl)));
            }
          }

          Maybe[Identifier] identifier = nothing();
          int identifierCount = 0;

          top-down visit(id) {
            case Identifier i: {
              identifier = just(i);
              identifierCount += 1;
            }
          }

          if(isSomething(v) && isSomething(identifier) && identifierCount == 1) {
            values += (unwrap(identifier) : unwrap(v));
          }
        }
      }
    }
  }


  return values;
}

private list[tuple[Identifier, str, IntegerLiteral]] extractForConditionParts(Expression ex) {
  list[tuple[Identifier, str, IntegerLiteral]] forConditionParts = [];

  top-down-break visit(ex) {
    case (RelationalExpression) `<RelationalExpression l> \< <ShiftExpression r>`: {
      if(relExpContainsIdentifierOnly(l) && sftExpContainsIntegerOnly(r)) {
        forConditionParts = forConditionParts + [<
          unwrap(extractIdentifierFromExpression(l)), "\<", unwrap(extractIntegerFromExpression(r))
         >];
      }
    }
    case (RelationalExpression) `<RelationalExpression l> \<= <ShiftExpression r>`: {
      if(relExpContainsIdentifierOnly(l) && sftExpContainsIntegerOnly(r)) {
        forConditionParts = forConditionParts + [<
          unwrap(extractIdentifierFromExpression(l)), "\<=", unwrap(extractIntegerFromExpression(r))
         >];
      }
    }
    case (RelationalExpression) `<RelationalExpression l> \> <ShiftExpression r>`: {
      if(relExpContainsIdentifierOnly(l) && sftExpContainsIntegerOnly(r)) {
        forConditionParts = forConditionParts + [<
          unwrap(extractIdentifierFromExpression(l)), "\>", unwrap(extractIntegerFromExpression(r))
         >];
      }
    }
    case (RelationalExpression) `<RelationalExpression l> \>= <ShiftExpression r>`: {
      if(relExpContainsIdentifierOnly(l) && sftExpContainsIntegerOnly(r)) {
        forConditionParts = forConditionParts + [<
          unwrap(extractIdentifierFromExpression(l)), "\>=", unwrap(extractIntegerFromExpression(r))
         >];
      }
    }
  }

  return forConditionParts;
}

private bool relExpContainsIdentifierOnly(RelationalExpression e) {
  switch(extractIdentifierFromExpression(e)) {
    case just(identifier): return unparse(identifier) == unparse(e);
  }

  return false;
}

private Maybe[IntegerLiteral] extractIntegerFromExpression(ShiftExpression e) {
  Maybe[IntegerLiteral] extractedInteger = nothing();

  top-down visit(e) {
    case IntegerLiteral intl: extractedInteger = just(intl);
  }

  return extractedInteger;
}

private bool sftExpContainsIntegerOnly(ShiftExpression e) {
  switch(extractIntegerFromExpression(e)) {
    case just(intl): return unparse(intl) == unparse(e);
  }

  return false;
}

private Maybe[Identifier] extractIdentifierFromExpression(RelationalExpression ex) {
  Maybe[Identifier] identifierInExpression = nothing();

  top-down visit(ex) {
    case Identifier i: {
      identifierInExpression = just(i);
    }
  };

  return identifierInExpression;
}
