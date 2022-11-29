import sys, os, getopt
from bs4 import BeautifulSoup
import xmlformatter

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

    if isFile == True:

        # Reading the data inside the xml file to a variable under the name  data
        with open(pomXml, 'r') as f:
            data = f.read() 

        # Passing the stored data inside the beautifulsoup parser 
        bs_data = BeautifulSoup(data, 'xml')

        # Finding all instances of tag   
        b_unique = bs_data.find_all('dependency')

        for event in b_unique:
            if 'junit' in event.select_one('groupId').text or 'junit' in event.select_one('artifactId').text:
                result = event.find('groupId')
                result.string.replace_with('org.junit.jupiter')
                result = event.find('artifactId')
                result.string.replace_with('junit-jupiter-engine')
                result = event.find('version')
                result.string.replace_with('5.4.0')
                # print(event)
                break


        with open(pomXml, 'w', encoding='utf-8') as f:
            f.write(str(bs_data))
        
        formatter = xmlformatter.Formatter(indent="1", indent_char="\t", encoding_output="UTF-8", preserve=["literal"])
        formatter.format_file(pomXml)
            
    else:
        sys.exit(0)