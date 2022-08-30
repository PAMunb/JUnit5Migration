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
  	descendingInclusiveForStatementRepeatedTest,
    transformsForWithMultipleAssertions,
    transformsWhenThereAreOtherStatements
  ];

  return runAndReportMultipleTests(tests);
}

test bool extractForStatementDataTest() {
  Statement forStatement = (Statement)
                                `for (int i = 0; i \< 5; i++) {
                                '  Assertions.assertEquals("expected", "expected");
                                '}`;
  MethodBody body = (MethodBody) `{
                                 '  <Statement forStatement>
                                 '}`;

  Identifier identifierI = parse(#Identifier, "i");
  ForStatementData expect = forStatementData(
    (identifierI: 0),
    parse(#StatementExpressionList, "i++"),
    [identifierI],
    [<identifierI, "\<", parse(#IntegerLiteral, "5")>],
    parse(#Statement, "{\n  Assertions.assertEquals(\"expected\", \"expected\");\n}")
  );


  ForStatementData res = unwrap(extractForStatementData(body));

  return expect == res;
}

str code1() =
"public class TestSuite {
'  @Test
'  public void multipleAssertionsTest() {
'     for (int i = 2; i \< 5; i++) {
'	  	  Assertions.assertEquals(\"expected\", \"expected\");
'     }
'  }
'}";

str expectedCode1() =
"public class TestSuite {
'  @RepeatedTest(3)
'  public void multipleAssertionsTest() {
'	   Assertions.assertEquals(\"expected\", \"expected\");
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
'	  	  Assertions.assertEquals(\"expected\", \"expected\");
'     }
'  }
'}";

str expectedCode2() =
"public class TestSuite {
'  @RepeatedTest(4)
'  public void multipleAssertionsTest() {
'	   Assertions.assertEquals(\"expected\", \"expected\");
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
'	  	  Assertions.assertEquals(\"expected\", \"expected\");
'     }
'  }
'}";

str expectedCode3() =
"public class TestSuite {
'  @RepeatedTest(6)
'  public void multipleAssertionsTest() {
'	   Assertions.assertEquals(\"expected\", \"expected\");
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
'	  	  Assertions.assertEquals(\"expected\", \"expected\");
'     }
'  }
'}";

str expectedCode4() =
"public class TestSuite {
'  @RepeatedTest(7)
'  public void multipleAssertionsTest() {
'	   Assertions.assertEquals(\"expected\", \"expected\");
'  }
'}";

test bool descendingInclusiveForStatementRepeatedTest() {
  original = parse(#CompilationUnit, code4());
  expected = parse(#CompilationUnit, expectedCode4());
  res = executeRepeatedTestTransformation(original);

  return expected == res;
}

str code5() =
"public class TestSuite {
'  @Test
'  public void multipleAssertionsTest() {
'     for (int i = 7; i \>= 1; i--) {
'	  	  Assertions.assertEquals(\"expected\", \"expected\");
'	  	  Assertions.assertTrue(true);
'	  	  Assertions.assertNull(null);
'     }
'  }
'}";

str expectedCode5() =
"public class TestSuite {
'  @RepeatedTest(7)
'  public void multipleAssertionsTest() {
'	   Assertions.assertEquals(\"expected\", \"expected\");
'	   Assertions.assertTrue(true);
'	   Assertions.assertNull(null);
'  }
'}";

test bool transformsForWithMultipleAssertions() {
  original = parse(#CompilationUnit, code5());
  expected = parse(#CompilationUnit, expectedCode5());
  res = executeRepeatedTestTransformation(original);

  return expected == res;
}

str code6() =
"public class TestSuite {
'  @Test
'  public void multipleAssertionsTest() {
'     for (int i = 7; i \>= 1; i--) {
'	  	  Assertions.assertEquals(\"expected\", \"expected\");
'	  	  AClass.someSideEffect();
'	  	  Assertions.assertNull(null);
'     }
'  }
'}";

str expectedCode6() =
"public class TestSuite {
'  @RepeatedTest(7)
'  public void multipleAssertionsTest() {
'	   Assertions.assertEquals(\"expected\", \"expected\");
'	   AClass.someSideEffect();
'	   Assertions.assertNull(null);
'  }
'}";

test bool transformsWhenThereAreOtherStatements() {
  original = parse(#CompilationUnit, code6());
  expected = parse(#CompilationUnit, expectedCode6());
  res = executeRepeatedTestTransformation(original);

  return res == expected;
}
