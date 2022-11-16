## JUnit 5 migrations with Docker

A set of Rascal transformations for helping
developers to migrate JUnit 4 test cases to JUnit 5.

### Requirements

   * Docker version >= 20.10.21

### Build and run

   * Clone this repository (`git clone git@github.com:PAMunb/JUnit5Migration.git`)
   * Change to the JUnit5Migration/docker folder (`cd JUnit5Migration/docker`)
   * Execute these commands in your terminal:

```shell
$ docker build -t jm5 -f Dockerfile.jm .

$ docker run --name junit5 -w /home/JUnit5Migration/ -it -v [LOCATION_OF_DATASET_IN_YOUR_HOST]:/home/dataset -v [LOCATION_OF_OUTPUT_DIRECTORY_IN_YOUR_HOST]:/home/JUnit5Migration/output jm5 python3 driver.py -i /home/dataset/[NAME_OF_PROJECT_DIRECTORY]/ -m 10
```
