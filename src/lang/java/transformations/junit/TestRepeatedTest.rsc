module lang::java::transformations::junit::TestRepeatedTest

import Map;
import ParseTree;
import Set;
import lang::java::\syntax::Java18;
import lang::java::transformations::junit::RepeatedTest;
import util::MaybeManipulation;
import util::Testing;

test bool main() {
  list[bool ()] tests = [
    extractForStatementDataTest,
  	ascendingExclusiveForStatementRepeatedTest,
  	ascendingInclusiveForStatementRepeatedTest,
  	descendingExclusiveForStatementRepeatedTest,
  	descendingInclusiveForStatementRepeatedTest
  ];

  return runAndReportMultipleTests(tests);
}

test bool extractForStatementDataTest() {
  ForStatement forStatement = (ForStatement)
                                `for (int i = 0; i \< 5; i++) {
                                '  Assert.assertEquals("expected", "expected");
                                '}`;

  Identifier identifierI = parse(#Identifier, "i");
  ForStatementData expect = forStatementData(
    (identifierI: 0),
    parse(#StatementExpressionList, "i++"),
    [identifierI],
    [<identifierI, "\<", parse(#IntegerLiteral, "5")>],
    parse(#Statement, "{\n  Assert.assertEquals(\"expected\", \"expected\");\n}")
  );


  ForStatementData res = unwrap(extractForStatementData(forStatement));

  return expect == res;
}

str code1() =
"public class TestSuite {
'  @Test
'  public void multipleAssertionsTest() {
'     for (int i = 2; i \< 5; i++) {
'	  	  Assert.assertEquals(\"expected\", \"expected\");
'     }
'  }
'}";

str expectedCode1() =
"public class TestSuite {
'  @Test
'  @RepeatedTest(3)
'  public void multipleAssertionsTest() {
'	   Assert.assertEquals(\"expected\", \"expected\");
'  }
'}";

test bool ascendingExclusiveForStatementRepeatedTest() {
  original = parse(#CompilationUnit, code1());
  expected = parse(#CompilationUnit, expectedCode1());
  res = executeRepeatedTestTransformation(original);

  return expected == res;
}

str code2() =
"public class TestSuite {
'  @Test
'  public void multipleAssertionsTest() {
'     for (int i = 2; i \<= 5; i++) {
'	  	  Assert.assertEquals(\"expected\", \"expected\");
'     }
'  }
'}";

str expectedCode2() =
"public class TestSuite {
'  @Test
'  @RepeatedTest(4)
'  public void multipleAssertionsTest() {
'	   Assert.assertEquals(\"expected\", \"expected\");
'  }
'}";

test bool ascendingInclusiveForStatementRepeatedTest() {
  original = parse(#CompilationUnit, code2());
  expected = parse(#CompilationUnit, expectedCode2());
  res = executeRepeatedTestTransformation(original);

  return expected == res;
}

str code3() =
"public class TestSuite {
'  @Test
'  public void multipleAssertionsTest() {
'     for (int i = 7; i \> 1; i--) {
'	  	  Assert.assertEquals(\"expected\", \"expected\");
'     }
'  }
'}";

str expectedCode3() =
"public class TestSuite {
'  @Test
'  @RepeatedTest(6)
'  public void multipleAssertionsTest() {
'	   Assert.assertEquals(\"expected\", \"expected\");
'  }
'}";

test bool descendingExclusiveForStatementRepeatedTest() {
  original = parse(#CompilationUnit, code3());
  expected = parse(#CompilationUnit, expectedCode3());
  res = executeRepeatedTestTransformation(original);

  return expected == res;
}

str code4() =
"public class TestSuite {
'  @Test
'  public void multipleAssertionsTest() {
'     for (int i = 7; i \>= 1; i--) {
'	  	  Assert.assertEquals(\"expected\", \"expected\");
'     }
'  }
'}";

str expectedCode4() =
"public class TestSuite {
'  @Test
'  @RepeatedTest(7)
'  public void multipleAssertionsTest() {
'	   Assert.assertEquals(\"expected\", \"expected\");
'  }
'}";

test bool descendingInclusiveForStatementRepeatedTest() {
  original = parse(#CompilationUnit, code4());
  expected = parse(#CompilationUnit, expectedCode4());
  res = executeRepeatedTestTransformation(original);

  return expected == res;
}
