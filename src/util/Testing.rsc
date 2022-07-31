module util::Testing

import IO;

public bool runAndReportTest(bool () testFunction) {
	bool testResult = testFunction();
	print(testFunction);
	print(" =\> ");
	println(testResult);
	return testResult;
}

public bool runAndReportMultipleTests(list[bool ()] testFunctions) {
  list[bool] testRun = ([] | it + runAndReportTest(t) | bool () t <- testFunctions);
  return (true | it && res | bool res <- testRun);
}
