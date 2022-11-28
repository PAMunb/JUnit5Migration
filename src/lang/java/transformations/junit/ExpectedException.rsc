module lang::java::transformations::junit::ExpectedException

import lang::java::\syntax::Java18; 

import IO;

public CompilationUnit executeExpectedExceptionTransformation(CompilationUnit unit) {
	if(verifyExpectedException(unit)) {
		unit = top-down visit(unit) {
			case (Imports)`<ImportDeclaration* imports>` => updateImports(imports)
			
			case (MethodDeclaration)`@Test(expected = <TypeName exception>.class) public void <Identifier name>() <Throws t> { <BlockStatements stmts> }` => 
			     (MethodDeclaration)`@Test
			                        'public void <Identifier name>() <Throws t> { 
			                        '      Assertions.assertThrows(<TypeName exception>.class, () -\> {
			                        '         <BlockStatements stmts>  }); 
			                        '    }
			                        '    
			                        '    `
			                      
			case (MethodDeclaration)`@Test(expected = <TypeName exception>.class) public void <Identifier name>()  { <BlockStatements stmts> }` => 
			    (MethodDeclaration)`@Test
			                       '  public void <Identifier name>() { 
			                       '      Assertions.assertThrows(<TypeName exception>.class, () -\> {
			                       '         <BlockStatements stmts>  }); 
			                       '    }
			                       '    
			                       '  `                      
		}	
	}
	return unit;
}

private Imports updateImports(ImportDeclaration* imports) {
   return (Imports)`<ImportDeclaration* imports> 
                   ' 
                   '// JUnit5 migration 
                   'import static org.junit.jupiter.api.Assertions.assertThrows;`; 
} 

public bool verifyExpectedException(CompilationUnit unit) {
	top-down visit(unit) {
		case (MethodDeclaration)`@Test(expected = <TypeName _>.class) 
		                        'public void <Identifier _>() <Throws _> { 
		                        '  <BlockStatements _> 
		                        '}`: return true;
		                        
		case (MethodDeclaration)`@Test(expected = <TypeName _>.class) 
		                        'public void <Identifier _>()  { 
		                        '  <BlockStatements _> 
		                        '}`: return true;                        
	}
	return false; 
}
