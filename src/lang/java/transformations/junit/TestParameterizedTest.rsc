module lang::java::transformations::junit::TestParameterizedTest

import Map;
import ParseTree;
import Set;
import lang::java::\syntax::Java18;
import lang::java::transformations::junit::ParameterizedTest;
import util::MaybeManipulation;
import util::Testing;

test bool main() {
  list[bool ()] tests = [
    parameterizeTest
  ];

  return runAndReportMultipleTests(tests);
}

str code1() =
"public class TestSuite {
'  @Test
'  public void multipleAssertionsTest() {
'	   Assert.assertEquals(1, 1);
'	   Assert.assertEquals(2, 3);
'  }
'}";

str expectedCode1() =
"public class TestSuite {
'  @ParameterizedTest
'  @CsvSource({
'     \"1, 1\",
'     \"2, 3\"
'  })
'  public void multipleAssertionsTest(int arg0, int arg1) {
'	   Assert.assertEquals(arg0, arg1);
'  }
'}";

test bool parameterizeTest() {
  original = parse(#CompilationUnit, code1());
  expected = parse(#CompilationUnit, expectedCode1());
  res = executeParameterizedTestTransformation(original);

  return expected == res;
}
