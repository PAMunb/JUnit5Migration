#!/usr/bin/python3

import sys, os, getopt
import logging 
import git
from datetime import datetime


currentDateAndTime = datetime.now()


usage = 'migrate.py -i <input_dir> '
branch = 'junit5-migration'


def main(argv):
    cwd = os.getcwd()

    input_dir = ''
    max_files = '0'

    opts, args = getopt.getopt(argv, "hi:m:", ["input_dir=", "max_files="])

    for opt, arg in opts:
        if opt == '-h':
            print(usage)
        elif opt in ('-i', '--input_dir'):
            input_dir = arg
        elif opt in ('-m', '--max_files'):
            max_files = arg
        else:
            print(usage)
    
    logging.info(f"Loading and checking the {input_dir} git repository")

    # repo = git.Repo(input_dir)

    # if not (branch in [r.name for r in repo.references]):
    #     repo.git.branch(branch)
        
    # repo.git.checkout(branch)

    logging.info("Executing the migrations")
    currentTime = currentDateAndTime.strftime("%y%m%d%H%M%S")

    os.system(f"java -Xmx4G -Xss1G -jar rascal-shell-stable.jar lang::java::transformations::junit::MainProgram -path {input_dir} -maxFilesOpt {max_files} > output/log-{currentTime}")

    os.chdir(input_dir)

    logging.info("Formating the source code") 

    os.system(f"git diff -U0 HEAD^ | {cwd}/google-java-format-diff.py -p1 -i --google-java-format-jar {cwd}/google-format.jar")
    
    logging.info("done")

if __name__ == "__main__":
    main(sys.argv[1:])


    
