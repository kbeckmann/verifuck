#!/usr/bin/env python2

lines = open("/dev/stdin", "r").read().split("\n")
for line in lines:
    if line and line[0] != '#':
        for x in line:
            if x == "#":
                break
            if x in ["+", "-", ">", "<", ".", ",", "[", "]"]:
                datah = x.encode('hex')
                print(datah)

print("0")
print("@ff") # change to last position in rom
print("0")

