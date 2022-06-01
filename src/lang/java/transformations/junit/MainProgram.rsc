module lang::java::transformations::junit::MainProgram

import IO; 
import List; 
import ParseTree; 
import String; 

import util::IOUtil;

import lang::java::\syntax::Java18;
import lang::java::transformations::junit::ExpectedException;
import lang::java::transformations::junit::ExpectedTimeout;
import lang::java::transformations::junit::SimpleAnnotations;
 

public void main(str path = "", str maxFilesOpt = "", str transformations = "all") {
    loc base = |file:///| + path; 
    
    if( (path == "") || (! exists(base)) || (! isDirectory(base)) ) {
       println("Invalid path <path>"); 
       return; 
    }
    
    int maxFiles = 0;
    
    if(maxFilesOpt != "") {
		maxFiles = toInt(maxFilesOpt);     
    } 
    
	list[loc] allFiles = findAllFiles(base, "java"); 
	
	int errors = 0; 
	
	int ee = 0; 
	int to = 0; 
	int sa = 0;
	
	for(loc f <- allFiles) {
	  try {  
	      str content = readFile(f);  
		  CompilationUnit unit = parse(#CompilationUnit, content);
		  
		  if(verifyExpectedException(unit)) {
		  	unit = executeExpectedExceptionTransformation(unit); 
		  	ee = ee + 1; 
		  }
		  
		  if(verifyTimeOut(unit)) {
		  	unit = executeExpectedTimeoutTransformation(unit);
		  	to = to + 1; 
		  } 
		  
		  if(verifySimpleAnnotations(unit)) {
		    unit = executeSimpleAnnotationsTransformation(unit);
		  	sa = sa + 1; 
		  }
		  
		  writeFile(f, unit);  
		  
		  if( (maxFiles) > 0 && (to + ee >= maxFiles) ) {
		     break; 
		  } 
		  
	  }
	  catch: {
			errors = errors + 1; 
	  }		 
	}

	println("ExpectedException rule: <ee> transformation(s)"); 
	println("ExpectedTimeout rule: <to> transformation(s)"); 
	println("SimpleAnnotations rule: <sa> transformation(s)"); 
	
	
	println("Files with error: <errors>");	
	println("Number of files: <size(allFiles)>");  
}