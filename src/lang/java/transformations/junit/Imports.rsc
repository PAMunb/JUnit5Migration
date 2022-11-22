module lang::java::transformations::junit::Imports

import ParseTree;
import lang::java::\syntax::Java18; 

public CompilationUnit executeImportsTransformation(CompilationUnit unit) {
	if(verifyImports(unit)) {
		unit = top-down visit(unit) {
			case (Imports)`<ImportDeclaration* imports>` => updateImports(imports)
			case (MethodInvocation) `Assert.<Identifier methodName>(<ArgumentList argumentList>)` => (MethodInvocation) `Assertions.<Identifier methodName>(<ArgumentList argumentList>)`
		}	
	}
	return unit;
}

private Imports updateImports(ImportDeclaration* imports) {
	imports = top-down visit(imports) {
		case (ImportDeclaration) `import org.junit.*;` => (ImportDeclaration) `import org.junit.jupiter.api.*;`
		case (ImportDeclaration) `import org.junit.Test;` => (ImportDeclaration) `import org.junit.jupiter.api.Test;`
		case (ImportDeclaration) `import org.junit.BeforeClass;` => (ImportDeclaration) `import org.junit.jupiter.api.BeforeAll;`
		case (ImportDeclaration) `import org.junit.Before;` => (ImportDeclaration) `import org.junit.jupiter.api.BeforeEach;`
		case (ImportDeclaration) `import org.junit.After;` => (ImportDeclaration) `import org.junit.jupiter.api.AfterEach;`
		case (ImportDeclaration) `import org.junit.AfterClass;` => (ImportDeclaration) `import org.junit.jupiter.api.AfterAll;`
		case (ImportDeclaration) `import org.junit.Ignore;` => (ImportDeclaration) `import org.junit.jupiter.api.Disabled;`
		case (ImportDeclaration) `import static org.junit.Assert.assertArrayEquals;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertArrayEquals;`
		case (ImportDeclaration) `import static org.junit.Assert.assertEquals;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertEquals;`
		case (ImportDeclaration) `import static org.junit.Assert.assertFalse;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertFalse;`
		case (ImportDeclaration) `import static org.junit.Assert.assertNotNull;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertNotNull;`
		case (ImportDeclaration) `import static org.junit.Assert.assertNotSame;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertNotSame;`
		case (ImportDeclaration) `import static org.junit.Assert.assertNull;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertNull;`
		case (ImportDeclaration) `import static org.junit.Assert.assertSame;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertSame;`
		case (ImportDeclaration) `import static org.junit.Assert.assertTrue;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.assertTrue;`
		case (ImportDeclaration) `import static org.junit.Assert.fail;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.fail;`
		case (ImportDeclaration) `import static org.junit.Assert.*;` => (ImportDeclaration) `import static org.junit.jupiter.api.Assertions.*;`
	}

	return parse(#Imports, unparse(imports));
}

public bool verifyImports(CompilationUnit cu) {
	top-down-break visit(cu) {
		case (ImportDeclaration) `import org.junit.*;`: return true;
		case (ImportDeclaration) `import org.junit.Test;`: return true;
		case (ImportDeclaration) `import org.junit.BeforeClass;`: return true;
		case (ImportDeclaration) `import org.junit.Before;`: return true;
		case (ImportDeclaration) `import org.junit.After;`: return true;
		case (ImportDeclaration) `import org.junit.AfterClass;`: return true;
		case (ImportDeclaration) `import org.junit.Ignore;`: return true;
		case (ImportDeclaration) `import static org.junit.Assert.assertArrayEquals;`: return true;
		case (ImportDeclaration) `import static org.junit.Assert.assertEquals;`: return true;
		case (ImportDeclaration) `import static org.junit.Assert.assertFalse;`: return true;
		case (ImportDeclaration) `import static org.junit.Assert.assertNotNull;`: return true;
		case (ImportDeclaration) `import static org.junit.Assert.assertNotSame;`: return true;
		case (ImportDeclaration) `import static org.junit.Assert.assertNull;`: return true;
		case (ImportDeclaration) `import static org.junit.Assert.assertSame;`: return true;
		case (ImportDeclaration) `import static org.junit.Assert.assertTrue;`: return true;
		case (ImportDeclaration) `import static org.junit.Assert.fail;`: return true;
		case (ImportDeclaration) `import static org.junit.Assert.*;`: return true;
	}
	return false; 
}