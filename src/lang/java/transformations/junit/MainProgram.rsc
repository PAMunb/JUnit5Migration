module lang::java::transformations::junit::MainProgram

import IO; 
import List; 
import ParseTree; 
import String; 
import Map;
import Set;

import util::IOUtil;

import lang::java::\syntax::Java18;
import lang::java::transformations::junit::AssertAll;
import lang::java::transformations::junit::ConditionalAssertion;
import lang::java::transformations::junit::ExpectedException;
import lang::java::transformations::junit::ExpectedTimeout;
import lang::java::transformations::junit::ParameterizedTest;
import lang::java::transformations::junit::RepeatedTest;
import lang::java::transformations::junit::SimpleAnnotations;
import lang::java::transformations::junit::TempDir;
import lang::java::transformations::junit::MethodImports;

data Transformation = transformation(str name, CompilationUnit (CompilationUnit) function);

public void main(str path = "", str maxFilesOpt = "", str transformationsToApply = "all") {
    loc base = |cwd:///| + path; 

    if( (path == "") || (! exists(base)) || (! isDirectory(base)) ) {
       println("Invalid path <path>"); 
       return; 
    }

    int maxFiles = 0;

    if(maxFilesOpt != "") {
		maxFiles = toInt(maxFilesOpt);     
    } 

	list[loc] allFiles = findAllTestFiles(base, "java", false); 

	int errors = 0; 

  list[Transformation] transformations = [
    transformation("ExpectedException", expectedExceptionTransform),
    transformation("ExpectedTimeout", expectedTimeoutTransform),
    transformation("AssertAll", executeAssertAllTransformation),
    transformation("ConditionalAssertion", executeConditionalAssertionTransformation),
    transformation("ParameterizedTest", executeParameterizedTestTransformation),
    transformation("RepeatedTest", executeRepeatedTestTransformation),
    transformation("TempDir", executeTempDirTransformation),
    transformation("SimpleAnnotations", simpleAnnotationTransform),
    transformation("MethodImports", methodImportsTransform)
  ];

  map[str, int] transformationCount = initTransformationsCount(transformations);
  int totalTransformationCount = 0;

  try{
      CompilationUnit transformedUnit;
      for(loc f <- allFiles) {
        str content = readFile(f);  
        println(f);
        <transformedUnit, totalTransformationCount, transformationCount> = applyTransformations(
            content, 
            totalTransformationCount, 
            transformationCount,
            transformations
          );
      writeFile(f, transformedUnit); 

        if( (maxFiles) > 0 && (totalTransformationCount >= maxFiles) ) {
          break; 
        } 
      }
  }catch:{
    errors = errors + 1;
  }

	for(str transformationName <- transformationCount) {
    println("<transformationName> rule: <transformationCount[transformationName]> transformation(s)");
  }

	println("Total transformations applied: <totalTransformationCount>");	
	println("Files with error: <errors>");	
	println("Number of files: <size(allFiles)>");  
}

public map[str, int] initTransformationsCount(list[Transformation] transformations) {
  return (( ) | it + (t.name : 0) | Transformation t <- transformations);
}

public tuple[CompilationUnit, int, map[str, int]] applyTransformations(
    str code,
    int totalTransformationCount,
    map[str, int] transformationCount,
    list[Transformation] transformations
  ) {
  CompilationUnit unit = parse(#CompilationUnit, code);

  for(Transformation transformation <- transformations) {
    CompilationUnit transformedUnit = transformation.function(unit);
    if(unit != transformedUnit) {
      println("Transformed! <transformation.name>");
      transformationCount[transformation.name] += 1;
      totalTransformationCount += 1;
    }
    unit = transformedUnit;
  }

  return <unit, totalTransformationCount, transformationCount>;
}

private CompilationUnit expectedExceptionTransform(CompilationUnit c) {
  if(verifyExpectedException(c)) c = executeExpectedExceptionTransformation(c); 
  return c;
}

private CompilationUnit expectedTimeoutTransform(CompilationUnit c) {
  if(verifyTimeOut(c)) c = executeExpectedTimeoutTransformation(c); 
  return c;
}

private CompilationUnit simpleAnnotationTransform(CompilationUnit c) {
  if(verifySimpleAnnotations(c)) c = executeSimpleAnnotationsTransformation(c); 
  return c;
}

private CompilationUnit methodImportsTransform(CompilationUnit c) {
  if(verifyMethodImports(c)) c = executeMethodImportsTransformation(c);
  return c;
}
