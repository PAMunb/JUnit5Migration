module lang::java::transformations::junit::TestSuite

import ParseTree;

import lang::java::\syntax::Java18;
import lang::java::transformations::junit::AssertAll;
import lang::java::transformations::junit::ConditionalAssertion;
import lang::java::transformations::junit::ExpectedException;
import lang::java::transformations::junit::ExpectedTimeout;
import lang::java::transformations::junit::SimpleAnnotations;
import IO;

str code1() =
 "import org.junit.Test;
 '
 'public class ExpectExceptionTest {
 '   @Test(expected = Exception.class)
 '   public void test() throws Exception {
 ' 	    m();
 '   }
 '
 '   private void m() throws Exception {
 '  	throw new Exception();
 '   }
 '
 '}";

 str code2() =
 "import org.junit.Test;
 '
 'public class ExpectTimeoutTest {
 '   @Test(timeout = 1)
 '   public void test() throws Exception {
 ' 	    m();
 '   }
 '
 '   private void m() throws Exception {
 '  	throw new Exception();
 '   }
 '
 '}";

str code3() =
 "// source: JetBrains
 '// (https://blog.jetbrains.com/idea/2020/08/migrating-from-junit-4-to-junit-5/)
 '
 'public class JUnit4To5 {
 '  @BeforeClass
 '  public static void beforeClass() throws Exception {
 '        System.out.println(\"JUnit4To5.beforeClass\");
 '  }
 '
 '  @Before
 '  public void before() throws Exception {
 '     System.out.println(\"JUnit4To5.before\");
 '  }
 '
 '  @Test
 '  public void shouldMigrateASimpleTest() {
 '      Assert.assertEquals(\"expected\", \"expected\");
 '  }
 '
 '  @Test
 '  @Ignore
 '  public void shouldMigrateIgnoreTestToDisabledTest() {
 '  }
 '
 '  @Test
 '  public void shouldStillSupportHamcrestMatchers() {
 '      assertThat(1, equalTo(1));
 '  }
 '
 '  @Test
 '  public void shouldStillSupportAssume() {
 '      Assume.assumeTrue(javaVersion() \> 8);
 '  }
 '
 '  @After
 '  public void after() throws Exception {
 '      System.out.println(\"JUnit4To5.after\");
 '  }
 '
 '  @AfterClass
 '  public static void afterClass() throws Exception {
 '      System.out.println(\"JUnit4To5.afterClass\");
 '  }
 '
 '  private int javaVersion() {
 '      return 14;
 '  }
 '}";

str code4() =
"public class TestSuite {
'  @Test(expected = IllegalArgumentException.class)
'  public void exceptionTest1()
'  {
'    g.addVertex(v1);
'    dinic = new DinicMFImpl\<\>(g);
'    double flow = dinic.getMaximumFlowValue(v1, v1);
'    System.out.println(flow);
'  }
'}";

str code5() =
"public class TestSuite {
'  @Test
'  public void conditionalAssertionWSingleStatement() {
'    if(true) {
'		  Assert.assertEquals(\"expected\", \"expected\");
'	   }
'  }

'  public void conditionalAssertionWMutilpleStatements() {
'    if(true) {
'		  Assert.assertEquals(\"expected\", \"expected\");
'		  Assert.assertEquals(\"something\", \"something\");
'	   }
'  }
'}";


str code6() =
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
 "import org.junit.Test;
 '
 '// JUnit5 migration
 'import org.junit.jupiter.api.Assertions.assertThrows;
 '
 'public class ExpectExceptionTest {
 '
 '  @Test
 '  public void test() throws Exception  {
 '     Assertions.assertThrows(Exception.class, () -\> {
 '        m();
 '     });
 '  }
 '
 '  private void m() throws Exception {
 '    throw new Exception();
 '  }
 '
 '}";

 str expectedCode2() =
  "import org.junit.Test;
  '
  '// JUnit5 migration
  'import java.time.Duration;
  'import org.junit.jupiter.api.Assertions.assertTimeout;
  '
  'public class ExpectTimeoutTest {
  '
  '  @Test
  '  public void test() throws Exception  {
  '    Assertions.assertTimeout(Duration.ofMillis(1), () -\> {
  '       m();
  '    });
  '  }
  '
  '  private void m() throws Exception {
  '      throw new Exception();
  '  }
  '
  '}";

  str expectedCode3() =
  "// source: JetBrains
  '// (https://blog.jetbrains.com/idea/2020/08/migrating-from-junit-4-to-junit-5/)
  '
  'import org.junit.jupiter.api.*;
  '
  'public class JUnit4To5 {

  '  @BeforeAll
  '  public static void beforeClass() throws Exception {
  '      System.out.println(\"JUnit4To5.beforeClass\");
  '  }
  '
  '  @BeforeEach
  '  public void before() throws Exception {
  '     System.out.println(\"JUnit4To5.before\");
  '  }
  '
  '  @Test
  '  public void shouldMigrateASimpleTest() {
  '     Assert.assertEquals(\"expected\", \"expected\");
  '  }
  '
  '  @Test
  '  @Disabled
  '  public void shouldMigrateIgnoreTestToDisabledTest() {
  '  }
  '
  '  @Test
  '  public void shouldStillSupportHamcrestMatchers() {
  '    assertThat(1, equalTo(1));
  '  }
  '
  '  @Test
  '  public void shouldStillSupportAssume() {
  '    Assume.assumeTrue(javaVersion() \> 8);
  '  }
  '
  '  @AfterEach
  '  public void after() throws Exception {
  '     System.out.println(\"JUnit4To5.after\");
  '  }
  '
  '  @AfterAll
  '  public static void afterClass() throws Exception {
  '    System.out.println(\"JUnit4To5.afterClass\");
  '  }
  '
  '  private int javaVersion() {
  '     return 14;
  '  }
  '}";


  str expectedCode4() =
  "import org.junit.jupiter.api.Assertions.assertThrows;
  '
  'public class TestSuite {
  '
  '  @Test
  '  public void exceptionTest1() {
  '    Assertions.assertThrows(IllegalArgumentException.class, () -\> {
  '       g.addVertex(v1);
  '       dinic = new DinicMFImpl\<\>(g);
  '        double flow = dinic.getMaximumFlowValue(v1, v1);
  '        System.out.println(flow);
  '    });
  '   }
  '
  '}";

str expectedCode5() =
"public class TestSuite {
'  @Test
'  @EnableIf(\"conditionalAssertionWSingleStatementCondition\")
'  public void conditionalAssertionWSingleStatement() {
'	   Assert.assertEquals(\"expected\", \"expected\");
'  }

'  public void conditionalAssertionWMutilpleStatements() {
'    if(true) {
'		  Assert.assertEquals(\"expected\", \"expected\");
'		  Assert.assertEquals(\"something\", \"something\");
'	   }
'  }
'
'  public boolean conditionalAssertionWSingleStatementCondition() {
'    return true;
'  }
'
'}";

str expectedCode6() =
"public class TestSuite {
'  @Test
'  public void multipleAssertionsTest() {
'     assertAll(
'	  	  () -\> Assert.assertEquals(\"expected\", \"expected\"),
'	  	  () -\> Assert.assertEquals(\"something\", \"something\"),
'	  	  () -\> Assert.assertEquals(\"another thing\", \"another thing\"),
'	  	  () -\> Assert.assertEquals(\"thing number 3\", \"thing number 3\")
'     );
'  }
'}";

test bool testExpectException() {
  original = parse(#CompilationUnit, code1());
  expected = parse(#CompilationUnit, expectedCode1());
  res = executeExpectedExceptionTransformation(original);
  return res == expected;
}

test bool testExpectExceptionNoMatch() {
  original = parse(#CompilationUnit, expectedCode1());
  expected = parse(#CompilationUnit, expectedCode1());
  res = executeExpectedExceptionTransformation(original);
  return res == expected;
}

test bool testExpectedTimeout() {
  original = parse(#CompilationUnit, code2());
  expected = parse(#CompilationUnit, expectedCode2());
  res = executeExpectedTimeoutTransformation(original);
  return res == expected;
}

test bool testExpectedTimeoutNoMatch() {
  original = parse(#CompilationUnit, expectedCode2());
  expected = parse(#CompilationUnit, expectedCode2());
  res = executeExpectedTimeoutTransformation(original);
  return res == expected;
}

test bool testSimpleAnnotations() {
  original = parse(#CompilationUnit, code3());
  expected = parse(#CompilationUnit, expectedCode3());
  res = executeSimpleAnnotationsTransformation(original);
  return res == expected;
}


test bool testExpectException2() {
  original = parse(#CompilationUnit, code4());
  expected = parse(#CompilationUnit, expectedCode4());
  res = executeExpectedExceptionTransformation(original);
  return res == expected;
}

test bool testConditionalAssertion() {
  original = parse(#CompilationUnit, code5());
  expected = parse(#CompilationUnit, expectedCode5());
  res = executeConditionalAssertionTransformation(original);
  return res == expected;
}

test bool testAssertAll() {
  original = parse(#CompilationUnit, code6());
  expected = parse(#CompilationUnit, expectedCode6());
  res = executeAssertAllTransformation(original);
  return res == expected;
}
