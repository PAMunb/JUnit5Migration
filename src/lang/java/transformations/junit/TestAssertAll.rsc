module lang::java::transformations::junit::TestAssertAll

import ParseTree;
import lang::java::\syntax::Java18;
import lang::java::transformations::junit::AssertAll;
import util::Testing;

test bool main() {
  list[bool ()] tests = [
    testAssertAll,
    testAssertAllGroupedStatements
  ];

  return runAndReportMultipleTests(tests);
}

str code1() =
"public class TestSuite {
'  @Test
'  public void multipleAssertionsTest() {
'	  	Assert.assertEquals(\"expected\", \"expected\");
'	  	Assert.assertEquals(\"something\", \"something\");
'	  	Assert.assertEquals(\"another thing\", \"another thing\");
'	  	Assert.assertEquals(\"thing number 3\", \"thing number 3\");
'  }
'}";

str expectedCode1() =
"public class TestSuite {
'  @Test
'  public void multipleAssertionsTest() {
'     Assertions.assertAll(
'	  	  () -\> Assert.assertEquals(\"expected\", \"expected\"),
'	  	  () -\> Assert.assertEquals(\"something\", \"something\"),
'	  	  () -\> Assert.assertEquals(\"another thing\", \"another thing\"),
'	  	  () -\> Assert.assertEquals(\"thing number 3\", \"thing number 3\")
'     );
'  }
'}";

test bool testAssertAll() {
  original = parse(#CompilationUnit, code1());
  expected = parse(#CompilationUnit, expectedCode1());
  res = executeAssertAllTransformation(original);
  return res == expected;
}

str code2() =
"public class TestSuite {
'  @Test
'  public void multipleAssertionsTest() {
'	  	Assert.assertEquals(\"expected\", \"expected\");
'	  	Assert.assertEquals(\"something\", \"something\");
'     someStatement();
'	  	Assert.assertEquals(\"another thing\", \"another thing\");
'	  	Assert.assertEquals(\"thing number 3\", \"thing number 3\");
'  }
'}";

str expectedCode2() =
"public class TestSuite {
'  @Test
'  public void multipleAssertionsTest() {
'     Assertions.assertAll(
'	  	  () -\> Assert.assertEquals(\"expected\", \"expected\"),
'	  	  () -\> Assert.assertEquals(\"something\", \"something\")
'     );
'     someStatement();
'     Assertions.assertAll(
'	  	  () -\> Assert.assertEquals(\"another thing\", \"another thing\"),
'	  	  () -\> Assert.assertEquals(\"thing number 3\", \"thing number 3\")
'     );
'  }
'}";

test bool testAssertAllGroupedStatements() {
  original = parse(#CompilationUnit, code2());
  expected = parse(#CompilationUnit, expectedCode2());
  res = executeAssertAllTransformation(original);
  return res == expected;
}
