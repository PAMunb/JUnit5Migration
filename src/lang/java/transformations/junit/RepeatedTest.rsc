module lang::java::transformations::junit::RepeatedTest

import Map; 
import ParseTree;
import Set;
import String;
import lang::java::\syntax::Java18;
import util::Math;
import util::Maybe;

data ForStatementData = forStatementData(
    map[Identifier, int] forInitValues,
    StatementExpressionList forUpdateExpression, 
    list[Identifier] forUpdateIdentifiers, 
    list[tuple[Identifier id, str op, IntegerLiteral vl]] forConditionParts,
    Statement statement
);

public CompilationUnit executeRepeatedTestTransformation(CompilationUnit unit) {
  unit = top-down visit(unit) {
    case (MethodDeclaration) `@Test
                             'public void <Identifier testName>() {
                             '  <ForStatement forStmt>
                             '}`: {
                               switch(extractForStatementData(forStmt)) {
                                 case just(forStmtData): {
                                   if(isTransformationApplyable(forStmtData) && resolveIterationCount(forStmtData) != nothing()) {
                                     insert(declareTestWithRepeatedTest(testName, forStmtData));
                                   }
                                 }
                               }
                             }
  }

  return unit;
}

public MethodDeclaration declareTestWithRepeatedTest(Identifier testName, ForStatementData f) {
  Statement statement = f.statement;
  IntegerLiteral iterationCount = parse(#IntegerLiteral, toString(unwrap(resolveIterationCount(f))));

  bottom-up-break visit(statement) {
    case Block b: return buildRefactoredTest(testName, b, iterationCount);
  };
}

private MethodDeclaration buildRefactoredTest(
                                              Identifier testName, 
                                              Block b, 
                                              IntegerLiteral iterationCount
                                             ) {
  return (MethodDeclaration) `@Test
                             '@RepeatedTest(<IntegerLiteral iterationCount>)
                             'public void <Identifier testName>() <Block b>`;
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
  top-down visit(f.statement) {
    case (Statement) 
      `{
      ' <Statement _>
      '}` : {};
    case (Statement) `Assert.assertEquals(<Expression _> , <Expression _>);`: assertionCount += 1;
    case Statement s: {
      return false; 
    }
  }

  return assertionCount > 0;
}

private bool conditionUsesSingleUpdateIdentifier(ForStatementData f) {
  return size(f.forConditionParts) == 1 &&
          size(f.forUpdateIdentifiers) == 1 &&
          head(f.forConditionParts)[0] == head(f.forUpdateIdentifiers);
}

public Maybe[ForStatementData] extractForStatementData(ForStatement forStatement) {
  Maybe[ForStatementData] forStmtData = nothing();

  top-down visit(forStatement) {
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
    // case (ForStatement) 
            // `for(<ForInit _>; Expression _; ForUpdate fu) <StatementNoShortIf stmt>`: {
            // }
  }

  return forStmtData;
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

      if(identifier != nothing() && v != nothing() && 
          unparse(unwrap(identifier)) == unparse(id) && unparse(unwrap(v)) == unparse(val)) {
        values += (unwrap(identifier) : unwrap(v));
      }
    }
    case (LocalVariableDeclaration) `<UnannType t> <VariableDeclaratorList declarations>` : {
      top-down visit(t) {
        case IntegralType itT : {
          str its = unparse(itT);
          if(!(its == "int" || its == "short")) fail;
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

          if(v != nothing() && identifier != nothing() && identifierCount == 1) {
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

private &A unwrap(Maybe[&A] opt) {
  switch(opt) {
    case just(x): return x;
  }
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
