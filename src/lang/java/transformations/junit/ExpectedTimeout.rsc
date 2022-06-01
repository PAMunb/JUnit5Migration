module lang::java::transformations::junit::ExpectedTimeout

import lang::java::\syntax::Java18; 

public CompilationUnit executeExpectedTimeoutTransformation(CompilationUnit unit) {
	if(verifyTimeOut(unit)) {
		unit = top-down visit(unit) {
			case (Imports)`<ImportDeclaration* imports>` => updateImports(imports)
			
			case (MethodDeclaration)`@Test(timeout = <ConditionalExpression exp>) 
		                            'public void <Identifier name>() <Throws t> { 
		                            '  <BlockStatements stmts> 
		                            '}` =>
		                             
			     (MethodDeclaration)`@Test
			                        'public void <Identifier name>() <Throws t> { 
			                        '      Assertions.assertTimeout(Duration.ofMillis(<ConditionalExpression exp>), () -\> {
			                        '         <BlockStatements stmts>   }); 
			                        '    }
			                        '    
			                        '    `
			                        
			case (MethodDeclaration)`@Test(timeout = <ConditionalExpression exp>) 
		                            'public void <Identifier name>()  { 
		                            '  <BlockStatements stmts> 
		                            '}` =>
		                             
			     (MethodDeclaration)`@Test 
			                        'public void <Identifier name>() { 
			                        '      Assertions.assertTimeout(Duration.ofMillis(<ConditionalExpression exp>), () -\> {
			                        '         <BlockStatements stmts>   }); 
			                        '    }
			                        '    
			                        '    `                        
		}	
	}
	return unit;
}

private Imports updateImports(ImportDeclaration* imports) {
   return (Imports)`<ImportDeclaration* imports> 
                   ' 
                   '// JUnit5 migration
                   'import java.time.Duration; 
                   'import org.junit.jupiter.api.Assertions.assertTimeout;`; 
} 

public bool verifyTimeOut(CompilationUnit unit) {
	top-down visit(unit) {
		case (MethodDeclaration)`@Test(timeout = <ConditionalExpression _>) 
		                        'public void <Identifier _>() <Throws _> { 
		                        '  <BlockStatements _> 
		                        '}`: return true;
		                       
		case (MethodDeclaration)`@Test(timeout = <ConditionalExpression _>) 
		                        'public void <Identifier _>() { 
		                        '  <BlockStatements _> 
		                        '}`: return true;                        
	}
	return false; 
}
