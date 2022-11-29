import os

ExpectedTimeout = []
ParameterizedTest = []
RepeatedTest = []
SimpleAnnotations = []
ExpectedException = []
TempDir = []
AssertAll = []
ConditionalAssertion = []
TotalTransformations = []
FileErrors = 0
TotalProjectsWithoutTransformations = 0

def Average(lst):
    return sum(lst)/len(lst)

path_of_the_directory = 'output/'
start = ('log-')
for log in os.listdir(path_of_the_directory):
    if log.startswith(start):
        # print(log)
        file = open("output/"+log, 'r')

        for line in file:
            if line.startswith('ExpectedTimeout'):
                # print("{}".format(line.strip()))
                ExpectedTimeout.append(int(line.strip().replace("ExpectedTimeout rule: ", "").replace(" transformation(s)","")))
            elif line.startswith('ParameterizedTest'):
                # print("{}".format(line.strip()))
                ParameterizedTest.append(int(line.strip().replace("ParameterizedTest rule: ", "").replace(" transformation(s)","")))
            elif line.startswith('RepeatedTest'):
                # print("{}".format(line.strip()))
                RepeatedTest.append(int(line.strip().replace("RepeatedTest rule: ", "").replace(" transformation(s)","")))
            elif line.startswith('SimpleAnnotations'):
                # print("{}".format(line.strip()))
                SimpleAnnotations.append(int(line.strip().replace("SimpleAnnotations rule: ", "").replace(" transformation(s)","")))
            elif line.startswith('ExpectedException'):
                # print("{}".format(line.strip()))
                ExpectedException.append(int(line.strip().replace("ExpectedException rule: ", "").replace(" transformation(s)","")))
            elif line.startswith('TempDir'):
                # print("{}".format(line.strip()))
                TempDir.append(int(line.strip().replace("TempDir rule: ", "").replace(" transformation(s)","")))
            elif line.startswith('AssertAll'):
                # print("{}".format(line.strip()))
                AssertAll.append(int(line.strip().replace("AssertAll rule: ", "").replace(" transformation(s)","")))
            elif line.startswith('ConditionalAssertion'):
                # print("{}".format(line.strip()))
                ConditionalAssertion.append(int(line.strip().replace("ConditionalAssertion rule: ", "").replace(" transformation(s)","")))
            elif line.startswith('Total'):
                # print("{}".format(line.strip()))
                aux = int(line.strip().replace("Total transformations applied: ", ""))
                if aux == 0:
                    TotalProjectsWithoutTransformations += 1
                TotalTransformations.append(aux)
            elif line.startswith('Files with error'):
                # print("{}".format(line.strip()))
                FileErrors += int(line.strip().replace("Files with error: ", ""))

        file.close()

print("-----Total by kind of transformations--------")        
print("ExpectedTimeout: {}".format(sum(ExpectedTimeout)))
print("ParameterizedTest: {}".format(sum(ParameterizedTest)))
print("RepeatedTest: {}".format(sum(RepeatedTest)))
print("SimpleAnnotations: {}".format(sum(SimpleAnnotations)))
print("ExpectedException: {}".format(sum(ExpectedException)))
print("TempDir: {}".format(sum(TempDir)))
print("AssertAll: {}".format(sum(AssertAll)))
print("ConditionalAssertion: {}".format(sum(ConditionalAssertion)))

print("-----Averages--------")
print("Average by projects: {}".format(round(Average(TotalTransformations),2)))

print("Average of ExpectedTimeout: {}".format(round(Average(ExpectedTimeout),2)))
print("Average of ParameterizedTest: {}".format(round(Average(ParameterizedTest),2)))
print("Average of RepeatedTest: {}".format(round(Average(RepeatedTest),2)))
print("Average of SimpleAnnotations: {}".format(round(Average(SimpleAnnotations),2)))
print("Average of ExpectedException: {}".format(round(Average(ExpectedException),2)))
print("Average of TempDir: {}".format(round(Average(TempDir),2)))
print("Average of AssertAll: {}".format(round(Average(AssertAll),2)))
print("Average of ConditionalAssertion: {}".format(round(Average(ConditionalAssertion),2)))

print("-----Totals--------")
print("Total of Transformations: {}".format(sum(TotalTransformations)))
print("Total files with errors: {}".format(FileErrors))
print("Total of projects without any transformations: {}".format(TotalProjectsWithoutTransformations))

