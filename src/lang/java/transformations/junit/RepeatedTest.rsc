module lang::java::transformations::junit::RepeatedTest

import ParseTree;
import lang::java::\syntax::Java18; 
import util::Maybe;
import IO;

data ForStatementData = forStatementData(
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
                                   if(isTransformationApplyable(forStmtData)) {
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
  IntegerLiteral iterationCount = resolveIterationCount(f);

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

private IntegerLiteral resolveIterationCount(ForStatementData f) {
  return head(f.forConditionParts).vl;
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
            `for(<ForInit _>; <Expression ex>; <ForUpdate fu>) <Statement stmt>` : {
              forStmtData = just(forStatementData(
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

private list[tuple[Identifier, str, IntegerLiteral]] extractForConditionParts(Expression ex) {
  list[tuple[Identifier, str, IntegerLiteral]] forConditionParts = [];

  top-down visit(ex) {
    case (RelationalExpression) `<RelationalExpression leftExpr> \< <ShiftExpression rightExp>`: {
      switch(extractIdentifierFromExpression(leftExpr)) {
        case just(identifier): {
          if (unparse(identifier) == unparse(leftExpr)) top-down visit(rightExp) {
            case IntegerLiteral intl: {
              if(unparse(intl) == unparse(rightExp)) 
                forConditionParts = forConditionParts + <identifier, "\<", intl>; 
            }
          }
        } 
      }
    }
  }

  return forConditionParts;
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
