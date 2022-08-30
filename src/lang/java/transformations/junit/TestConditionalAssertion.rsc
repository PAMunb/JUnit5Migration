module lang::java::transformations::junit::TestConditionalAssertion

import ParseTree;
import lang::java::\syntax::Java18;
import lang::java::transformations::junit::ConditionalAssertion;
import util::Testing;

test bool main() {
  list[bool ()] tests = [
    testConditionalAssertion,
    testConditionalAssertionWithPrecedingStatements,
    testConditionalAssertionWithMultipleAssertions
  ];

  return runAndReportMultipleTests(tests);
}

str code1() =
"public class TestSuite {
'  @Test
'  public void conditionalAssertionWSingleStatement() {
'    if(true) {
'		  Assert.assertEquals(\"expected\", \"expected\");
'	   }
'  }
'}";

str expectedCode1() =
"public class TestSuite {
'  @Test
'  @EnableIf(\"conditionalAssertionWSingleStatementCondition\")
'  public void conditionalAssertionWSingleStatement() {
'	   Assert.assertEquals(\"expected\", \"expected\");
'  }
'
'  public boolean conditionalAssertionWSingleStatementCondition() {
'    return true;
'  }
'
'}";

test bool testConditionalAssertion() {
  original = parse(#CompilationUnit, code1());
  expected = parse(#CompilationUnit, expectedCode1());
  res = executeConditionalAssertionTransformation(original);
  return res == expected;
}

str code2() =
"public class TestSuite {
'  @Test
'  public void conditionalTestWithPrecedingStatements() {
'     someMethod();
'	  	if(true) {
'	  	  Assert.assertEquals(\"something\", \"something\");
'     }
'  }
'}";

test bool testConditionalAssertionWithPrecedingStatements() {
  original = parse(#CompilationUnit, code2());
  res = executeConditionalAssertionTransformation(original);
  return res == original;
}

str code3() =
"public class TestSuite {
'  @Test
'  public void conditionalAssertionWSingleStatement() {
'    if(true) {
'		  Assert.assertEquals(\"expected\", \"expected\");
'	   }
'  }
'
'  @Test
'  public void conditionalAssertionWMultipleStatements() {
'    if(true) {
'		  Assert.assertEquals(\"expected\", \"expected\");
'		  Assert.assertEquals(\"something\", \"something\");
'	   }
'  }
'}";

str expectedCode3() =
"public class TestSuite {
'  @Test
'  @EnableIf(\"conditionalAssertionWSingleStatementCondition\")
'  public void conditionalAssertionWSingleStatement() {
'	   Assert.assertEquals(\"expected\", \"expected\");
'  }
'
'  @Test
'  @EnableIf(\"conditionalAssertionWMultipleStatementsCondition\")
'  public void conditionalAssertionWMultipleStatements() {
'		 Assert.assertEquals(\"expected\", \"expected\");
'		 Assert.assertEquals(\"something\", \"something\");
'  }
'
'  public boolean conditionalAssertionWSingleStatementCondition() {
'    return true;
'  }

'  public boolean conditionalAssertionWMultipleStatementsCondition() {
'    return true;
'  }
'}";

test bool testConditionalAssertionWithMultipleAssertions() {
  original = parse(#CompilationUnit, code3());
  expected = parse(#CompilationUnit, expectedCode3());
  res = executeConditionalAssertionTransformation(original);
  return res == expected;
}
