import sys, os, getopt
from bs4 import BeautifulSoup
import xmlformatter
import html


def main(argv):
    cwd = os.getcwd()

    pomXml = ''

    opts, args = getopt.getopt(argv, "i:", ["input_dir="])

    for opt, arg in opts:
        if opt in ('-i', '--input_dir'):
            pomXml = arg.strip()
        else:
            sys.exit(0)     

    isFile = os.path.isfile(pomXml)

    # print(isFile)

    if isFile == True:

        # Reading the data inside the xml file to a variable under the name  data
        with open(pomXml, 'r') as f:
            data = f.read() 

        # Passing the stored data inside the beautifulsoup parser 
        bs_data = BeautifulSoup(data, 'xml')

        # Finding all instances of tag   
        b_unique = bs_data.find_all('dependency')

        # print(b_unique)

        for event in b_unique:
            if event.select_one('version').text.startswith('4') and ('junit' in event.select_one('groupId').text or 'junit' in event.select_one('artifactId').text):

                dependencies = event.parent
                dependencies.append(html.unescape("\n<dependency>\n<groupId>org.junit.jupiter</groupId>\n<artifactId>junit-jupiter-api</artifactId>\n <version>5.9.1</version>\n<scope>test</scope>\n</dependency>"))
                dependencies.append(html.unescape('\n<dependency>\n<groupId>org.junit.jupiter</groupId>\n<artifactId>junit-jupiter-engine</artifactId>\n <version>5.9.1</version>\n<scope>test</scope>\n</dependency>'))
                dependencies.append(html.unescape('\n<dependency>\n<groupId>org.junit.vintage</groupId>\n<artifactId>junit-vintage-engine</artifactId>\n <version>5.9.1</version>\n<scope>test</scope>\n</dependency>'))
                event.decompose()
                break


        with open(pomXml, 'w', encoding='utf-8') as f:
            f.write(str(bs_data).replace("&lt;","<").replace("&gt;",">"))
        
        os.system(f"xmlformat --overwrite {pomXml}")
            
    else:
        sys.exit(0)