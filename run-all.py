import csv
import git
import os
import stat


cwd = os.getcwd()
with open("results.csv",newline='') as f:
    projects = csv.reader(f, delimiter=',')
    for project in projects:
        if project[0] == "name":
            continue
        orgName = project[0].split("/")
        name = orgName[1]
        path = cwd+"/dataset/"+name.strip()
        print("Migration : "+name)
        os.system(f"python3 driver.py -i {path} -m 100")
os.system(f"python3 log-inspec.py")