module lang::java::transformations::junit::TestParameterizedTest

import ParseTree;
import lang::java::\syntax::Java18;
import lang::java::transformations::junit::ParameterizedTest;
import util::Testing;

test bool main() {
  list[bool ()] tests = [
    parameterizeTest,
    parameterizeTestWithMultipleTypes,
    doNotParameterizeTestWhenAssertionsDifferTest,
    doNotParameterizeTestWhenAssertionsUseMethodsTest,
    doNotParameterizeTestWhenAssertionsUseVariablesTest,
    doNotParameterizeTestWithSingleAssertionTest
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

str code2() =
"public class TestSuite {
'  @Test
'  public void multipleAssertionsTest() {
'	   Assert.assertEquals(1, \"something\", true);
'	   Assert.assertEquals(2, \"yetAnotherThing\", false);
'  }
'}";

str expectedCode2() =
"public class TestSuite {
'  @ParameterizedTest
'  @CsvSource({
'     \"1, \'something\', true\",
'     \"2, \'yetAnotherThing\', false\"
'  })
'  public void multipleAssertionsTest(int arg0, String arg1, boolean arg2) {
'	   Assert.assertEquals(arg0, arg1, arg2);
'  }
'}";

test bool parameterizeTestWithMultipleTypes() {
  original = parse(#CompilationUnit, code2());
  expected = parse(#CompilationUnit, expectedCode2());
  res = executeParameterizedTestTransformation(original);

  return expected == res;
}

str code3() =
"public class TestSuite {
'  @Test
'  public void multipleAssertionsTest() {
'	   Assert.assertEquals(1, 1);
'	   Assert.assertSame(2, 3);
'  }
'}";

test bool doNotParameterizeTestWhenAssertionsDifferTest() {
  original = parse(#CompilationUnit, code3());
  res = executeParameterizedTestTransformation(original);

  return original == res;
}

str code4() =
"public class TestSuite {
'  @Test
'  public void multipleAssertionsTest() {
'	   Assert.assertEquals(something(), 1);
'	   Assert.assertEquals(2, 3);
'  }
'}";

test bool doNotParameterizeTestWhenAssertionsUseMethodsTest() {
  original = parse(#CompilationUnit, code4());
  res = executeParameterizedTestTransformation(original);

  return original == res;
}

str code5() =
"public class TestSuite {
'  @Test
'  public void multipleAssertionsTest() {
'    int x = 5;
'	   Assert.assertEquals(x, 1);
'	   Assert.assertEquals(2, 3);
'  }
'}";

test bool doNotParameterizeTestWhenAssertionsUseVariablesTest() {
  original = parse(#CompilationUnit, code5());
  res = executeParameterizedTestTransformation(original);

  return original == res;
}

str code6() =
"public class TestSuite {
'  @Test
'  public void multipleAssertionsTest() {
'	   Assert.assertEquals(2, 3);
'  }
'}";

test bool doNotParameterizeTestWithSingleAssertionTest() {
  original = parse(#CompilationUnit, code6());
  res = executeParameterizedTestTransformation(original);

  return original == res;
}
