module lang::java::transformations::junit::SimpleAnnotations

import lang::java::\syntax::Java18; 

public CompilationUnit executeSimpleAnnotationsTransformation(CompilationUnit unit) {
	if(verifySimpleAnnotations(unit)) {
		unit = top-down visit(unit) {
			case (MethodModifier)`@BeforeClass` => (MethodModifier)`@BeforeAll`
			case (MethodModifier)`@Before` => (MethodModifier)`@BeforeEach`
			case (MethodModifier)`@After` => (MethodModifier)`@AfterEach`
			case (MethodModifier)`@AfterClass` => (MethodModifier)`@AfterAll`
			case (MethodModifier)`@Ignore` => (MethodModifier)`@Disabled`	
		}	
	}
	return unit;
}

public bool verifySimpleAnnotations(CompilationUnit cu) {
	top-down-break visit(cu) {
		case (MethodModifier)`@BeforeClass`: return true;
		case (MethodModifier)`@Before`: return true;
		case (MethodModifier)`@After`: return true;
		case (MethodModifier)`@Ignore`: return true;
		case (MethodModifier)`@Test`: return true;
    case (MethodInvocation) `Assertions.<Identifier _>(<ArgumentList _>)` : return true;
		case (Annotation) `@ParameterizedTest`: return true;
    case (Annotation) `@RepeatedTest(<IntegerLiteral _>)`: return true;
    case (Annotation) `@EnableIf(<StringLiteral _>)`: return true;
    case (FormalParameter) `@TempDir File tempDir`: return true;
	}
	return false; 
}
