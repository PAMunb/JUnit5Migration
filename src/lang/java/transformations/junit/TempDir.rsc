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
  bool tempDirUsed = false;
  method = top-down visit(method) {
    case (MethodInvocation) `File.createTempFile(<ArgumentList args>)`: {
      tempDirUsed = true;
      insert((MethodInvocation) `tempDir.createTempFile(<ArgumentList args>)`);
    }
  }

  if(tempDirUsed) method = addMethodParameter(method, (FormalParameter) `@TempDir File tempDir`);

  return method;
}
