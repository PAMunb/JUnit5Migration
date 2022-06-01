module lang::java::transformations::junit::SimpleAnnotations

import lang::java::\syntax::Java18; 

public CompilationUnit executeSimpleAnnotationsTransformation(CompilationUnit cu) {
	if(verify(cu)) {
		cu = top-down visit(cu) {
			case (Imports)`<ImportDeclaration* imports>` => updateImports(imports)
			case (MethodModifier)`@BeforeClass` => (MethodModifier)`@BeforeAll`
			case (MethodModifier)`@Before` => (MethodModifier)`@BeforeEach`
			case (MethodModifier)`@After` => (MethodModifier)`@AfterEach`
			case (MethodModifier)`@AfterClass` => (MethodModifier)`@AfterAll`
			case (MethodModifier)`@Ignore` => (MethodModifier)`@Disabled`	
		}	
	}
	return cu;
}

private Imports updateImports(ImportDeclaration* imports) {
   return (Imports)`<ImportDeclaration* imports> 
                   ' 
                   '// JUnit5 migration
                   'import org.junit.jupiter.api.*;`; 
} 

public bool verify(CompilationUnit cu) {
	top-down-break visit(cu) {
		case (MethodModifier)`@BeforeClass`: return true;  
		case (MethodModifier)`@Before`: return true;  
		case (MethodModifier)`@After`: return true;  
		case (MethodModifier)`@Ignore`: return true;  
	}
	return false; 
}
