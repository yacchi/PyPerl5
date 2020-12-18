import os
import re

DEFINE_DIRECTIVE = re.compile(r"^#define\s+(\w+)\s+(.*)$")

VERSION = ""

with open(os.path.join(os.path.dirname(__file__), "src", "config.h")) as f:
    for line in f.readlines():
        m = DEFINE_DIRECTIVE.match(line)
        if m:
            key, value = m.groups()
            if key == "VERSION":
                VERSION = value.strip('"')

if __name__ == '__main__':
    print("VERSION: {}".format(VERSION))
