#!/usr/bin/python3
import requests, re, sys
requests.packages.urllib3.disable_warnings()
try:
    from requests.packages.urllib3.exceptions import InsecureRequestWarning
    from requests.packages.urllib3.exceptions import SubjectAltNameWarning
    requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
    requests.packages.urllib3.disable_warnings(SubjectAltNameWarning)
except ImportError:
    if gInteractive:
        print("WARNING: Your version of requests includes an older urllib3. If you are using '-i' you will still get warnings.")

#r = requests.get("http://pbps.totalnetsolutions.net", verify=False)

rx=re.compile('''https*://(?!www.w3.org)[^'">]*''', flags=re.U&re.I)

done={}

def printall(groups):
    global done
    if type(groups) == type([]):
        for group in groups:
            if not group in done:
                print(group)
                if rx.match(group):
                    done[group]=True
                    r=requests.get(group, verify=False)
                    if r.url != group:
                        print(r.url)
                    j=rx.findall(r.text)
                    printall(j)
    else:
        print("wasn't passed a list, continuing.")
print(sys.argv[1:])
printall(sys.argv[1:])

