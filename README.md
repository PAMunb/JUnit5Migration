## JUnit 5 migrations

A set of Rascal transformations for helping
developers to migrate JUnit 4 test cases to JUnit 5.

### Requirements

   * Python 3
   * Java 8

### Build and run

   * Clone this repository (`git clone git@github.com:PAMunb/JUnit5Migration.git`)
   * Change to the JUnit5Migration folder (`cd JUnit5Migration`) 
   * Download the Rascal shell (`wget https://update.rascal-mpl.org/console/rascal-shell-stable.jar`)
   * Execute the `driver.py` script:

```shell
$ python3 driver.py -i <PATH_TO_GIT_REPOSITORY> -m <MAX_NUMBER_OF_FILES>
```
