#!/usr/bin/python3
import requests, re, sys
requests.packages.urllib3.disable_warnings()

gInteractive=True
if not (sys.stdout.isatty() and sys.stdin.isatty()):
    #Are in some kind of pipeline, so disabling interactive input.
    gInteractive=False

try:
    from requests.packages.urllib3.exceptions import InsecureRequestWarning
    from requests.packages.urllib3.exceptions import SubjectAltNameWarning
    requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
    requests.packages.urllib3.disable_warnings(SubjectAltNameWarning)
except ImportError:
    if gInteractive:
        print("WARNING: Your version of requests includes an older urllib3. If you are using '-i' you will still get warnings.")

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
                    r=None
                    try:
                        r=requests.get(group, verify=False)
                    except ConnectionResetError:
                        print("Connection reset connecting to group!")
                        done[group]=True
                    except ConnectionError:
                        print("Generic connection error connecting to {0}!".format(group))
                        done[group]=True
                    if r:
                        if r.url != group:
                            print(r.url)
                        j=rx.findall(r.text)
                        printall(j)
    else:
        print("wasn't passed a list, continuing.")
print(sys.argv[1:])
printall(sys.argv[1:])

