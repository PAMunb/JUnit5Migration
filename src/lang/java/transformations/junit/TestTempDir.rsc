module lang::java::transformations::junit::TestTempDir

import ParseTree;
import lang::java::\syntax::Java18;
import lang::java::transformations::junit::TempDir;
import util::Testing;

test bool main() {
  list[bool ()] tests = [
    basicTempFileUsageTest,
    addTempDirAnnotationWithAnotherParameter,
    addTempDirAnnotationWithOtherParameters
  ];

  return runAndReportMultipleTests(tests);
}


str code1() =
"public class TestSuite {
'  @Test
'  public void tempFileTest() {
'    File x = File.createTempFile(\"temp\", null);
'  }
'}";

str expectedCode1() =
"public class TestSuite {
'  @Test
'  public void tempFileTest(@TempDir File tempDir) {
'    File x = tempDir.createTempFile(\"temp\", null);
'  }
'}";

test bool basicTempFileUsageTest() {
  original = parse(#CompilationUnit, code1());
  expected = parse(#CompilationUnit, expectedCode1());
  res = executeTempDirTransformation(original);

  return expected == res;
}

str code2() =
"public class TestSuite {
'  @Test
'  public void tempFileTest(int a) {
'    File x = File.createTempFile(\"temp\", null);
'  }
'}";

str expectedCode2() =
"public class TestSuite {
'  @Test
'  public void tempFileTest(int a, @TempDir File tempDir) {
'    File x = tempDir.createTempFile(\"temp\", null);
'  }
'}";

test bool addTempDirAnnotationWithAnotherParameter() {
  original = parse(#CompilationUnit, code2());
  expected = parse(#CompilationUnit, expectedCode2());
  res = executeTempDirTransformation(original);

  return expected == res;
}

str code3() =
"public class TestSuite {
'  @Test
'  public void tempFileTest(int a, str b, int c) {
'    File x = File.createTempFile(\"temp\", null);
'  }
'}";

str expectedCode3() =
"public class TestSuite {
'  @Test
'  public void tempFileTest(int a, str b, int c, @TempDir File tempDir) {
'    File x = tempDir.createTempFile(\"temp\", null);
'  }
'}";

test bool addTempDirAnnotationWithOtherParameters() {
  original = parse(#CompilationUnit, code3());
  expected = parse(#CompilationUnit, expectedCode3());
  res = executeTempDirTransformation(original);

  return expected == res;
}
