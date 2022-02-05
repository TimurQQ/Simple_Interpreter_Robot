#!/bin/bash

lex prog.l
yacc prog.y
cc y.tab.c
./a.out < $1 $2 $3
python.exe utf-16-fix.py
