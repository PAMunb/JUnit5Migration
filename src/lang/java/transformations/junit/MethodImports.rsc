module lang::java::transformations::junit::MethodImports

import IO;
import ParseTree;
import lang::java::\syntax::Java18; 

public CompilationUnit executeMethodImportsTransformation(CompilationUnit unit) {
	if(verifyMethodImports(unit)) {
		unit = top-down visit(unit) {
			case (ImportDeclaration) `import static org.junit.Assert.assertEquals;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertEquals;`
			case (ImportDeclaration) `import static org.junit.Assert.assertTrue;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertTrue;`
			case (ImportDeclaration) `import static org.junit.Assert.assertNotNull;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertNotNull;`
			case (ImportDeclaration) `import static org.junit.Assert.*;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.*;`
			case (ImportDeclaration) `import org.junit.*;` => (ImportDeclaration) `import org.junit.jupiter.api.*;`
		}	
	}
	return unit;
}

public bool verifyMethodImports(CompilationUnit cu) {
	top-down-break visit(cu) {
		case (ImportDeclaration) `import static org.junit.Assert.assertEquals;`: return true;
		case (ImportDeclaration) `import static org.junit.Assert.assertTrue;`: return true;
		case (ImportDeclaration) `import static org.junit.Assert.assertNotNull;`: return true;
		case (ImportDeclaration) `import static org.junit.Assert.*;`: return true;
		case (ImportDeclaration) `import org.junit.*;`: return true;
	}
	return false; 
}
