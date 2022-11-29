import csv
import git
import os
import stat
import shutil

def change_permissions_recursive(path, mode):
    for root, dirs, files in os.walk(path, topdown=False):
        for dir in [os.path.join(root,d) for d in dirs]:
            os.chmod(dir, mode)
    for file in [os.path.join(root, f) for f in files]:
            os.chmod(file, mode)

change_permissions_recursive('dataset', 0o777)

cwd = os.getcwd()
# print(cwd)
clear = []
count = 1
with open("results.csv",newline='') as f:
    projects = csv.reader(f, delimiter=',')
    for project in projects:
        if project[0] == "name":
            continue
        print(count)
        orgName = project[0].split("/")
        name = orgName[1]
        git_url = "https://github.com/"+project[0]+".git"
        # print(git_url)
        path = cwd+"/dataset/"+name.strip()
        
        try:
            if os.path.isdir(path):
                if not os.access(path, os.W_OK):
                    os.chmod(path, stat.S_IWUSR)
                    shutil.rmtree(path)
                    print("cloning: " + name.strip())
                    git.Git("dataset/").clone(git_url.strip())
                else:
                    shutil.rmtree(path)
                    print("cloning: " + git_url.strip())
                    git.Git("dataset/").clone(git_url.strip())
            else:
                print("cloning: " + git_url.strip())
                git.Git("dataset/").clone(git_url.strip())
            count = count + 1
        except Exception as e:
            print(e)
            print(path)
            clear.append(name.strip())
            if os.path.isdir(path):
                os.chmod(path, stat.S_IWUSR)
                shutil.rmtree(path)
    print(clear)
