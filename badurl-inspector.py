#!/usr/bin/python3
import requests, re, sys
r = requests.get("http://tnurl.net/bhje")

rx=re.compile('''https*:[^'">]*''', flags=re.U&re.I)

done={}

def printall(groups):
    global done
    if type(groups) == type([]):
        for group in groups:
            if not group in done:
                print(group)
                if rx.match(group):
                    done[group]=True
                    r=requests.get(group)
                    j=rx.findall(r.text)
                    printall(j)
    else:
        print("wasn't passed a list, continuing.")
print(sys.argv)
printall(sys.argv)

