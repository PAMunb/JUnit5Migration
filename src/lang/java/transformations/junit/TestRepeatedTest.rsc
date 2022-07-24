module lang::java::transformations::junit::TestRepeatedTest

import ParseTree; 

import lang::java::\syntax::Java18; 
import lang::java::transformations::junit::RepeatedTest; 
import util::Maybe;
import IO;

str code1() = 
"public class TestSuite { 
'  @Test
'  public void multipleAssertionsTest() {
'     for (int i = 0; i \< 5; i++) {
'	  	  Assert.assertEquals(\"expected\", \"expected\");
'     }
'  } 
'}"; 

str expectedCode1() = 
"public class TestSuite { 
'  @Test
'  @RepeatedTest(5)
'  public void multipleAssertionsTest() {
'	   Assert.assertEquals(\"expected\", \"expected\");
'  } 
'}"; 

test bool extractForStatementDataTest() {
  ForStatement forStatement = (ForStatement) 
                                `for (int i = 0; i \< 5; i++) {
                                '  Assert.assertEquals("expected", "expected");
                                '}`;

  ForStatementData expect = forStatementData(
    [parse(#Identifier, "i")],
    [<parse(#Identifier, "i"), "\<", parse(#IntegerLiteral, "5")>],
    parse(#Statement, "{\n  Assert.assertEquals(\"expected\", \"expected\");\n}")
  );
  
  ForStatementData res;
  switch(extractForStatementData(forStatement)) {
    case just(extractedData): { res = extractedData; } 
  }

  return expect == res;
}

test bool experiment() {
  original = parse(#CompilationUnit, code1());
  expected = parse(#CompilationUnit, expectedCode1());
  res = executeRepeatedTestTransformation(original);

  return expected == res;
}
