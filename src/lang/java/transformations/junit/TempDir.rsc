module lang::java::transformations::junit::TempDir

import ParseTree;
import lang::java::\syntax::Java18;
import lang::java::manipulation::TestMethod;
import util::Maybe;

public CompilationUnit executeTempDirTransformation(CompilationUnit unit) {
  unit = top-down visit(unit) {
    case MethodDeclaration method => replaceTempFilesWithTempDir(method)
                                          when isMethodATest(method)
  }

  return unit;
}

private MethodDeclaration replaceTempFilesWithTempDir(MethodDeclaration method) {
  bool tempFilesUsed = false;

  BlockStatements statements;
  switch(extractBlockStatements(method)) {
    case just(stmts): statements = stmts;
    case nothing(): return method;
  }

  statements = top-down visit(statements) {
    case (MethodInvocation) `File.createTempFile(<ArgumentList args>)`: {
      tempFilesUsed = true;
      insert((MethodInvocation) `tempDir.createTempFile(<ArgumentList args>)`);
    }
  }

  method = top-down-break visit(method) {
    case BlockStatements b => statements
  }

  method = top-down-break visit(method) {
    case MethodDeclarator declarator => addTempDirAnnotation(declarator)
  }

  return method;
}

private MethodDeclarator addTempDirAnnotation(MethodDeclarator declarator) {
  FormalParameter tempDirAnnotation = (FormalParameter) `@TempDir File tempDir`;

  declarator = top-down-break visit(declarator) {
    case (MethodDeclarator) `<Identifier i> ()`: {
      insert((MethodDeclarator) `<Identifier i> (<FormalParameter tempDirAnnotation>)`);
    }
    case (MethodDeclarator) `<Identifier i> (<FormalParameter param>)`: {
      insert((MethodDeclarator) `<Identifier i> (<FormalParameter tempDirAnnotation>, <FormalParameter param>)`);
    }
  }

  return declarator;
}

private Maybe[BlockStatements] extractBlockStatements(MethodDeclaration method) {
  top-down visit(method) {
    case (MethodDeclaration) `@Test
                             'public void <MethodDeclarator _d> {
                             '  <BlockStatements testStatements>
                             '}`: return just(testStatements);
  }

  return nothing();
}
