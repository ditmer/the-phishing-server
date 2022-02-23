#!/usr/bin/python3
import crypt
import sys
import os
import string
import getpass


try:
    from secrets import choice as randchoice
except ImportError:
    from random import SystemRandom
    randchoice = SystemRandom().choice

def sha512_crypt(password, salt=None, rounds=None):
    if salt is None:
        salt = ''.join([randchoice(string.ascii_letters + string.digits)
                        for _ in range(20)])

    prefix = '$6$'
    if rounds is not None:
        rounds = max(1000, min(999999999, rounds or 5000))
        prefix += 'rounds={0}$'.format(rounds)
    return crypt.crypt(password, prefix + salt)

try:
    if sys.argv[1]:
        password1 = sys.argv[1]
except:
    password1 = None
    password2 = None

    # Read the password
    while password1 != password2 or password1 == None:
        password1 = getpass.getpass()
        password2 = getpass.getpass("Confirm password: ")
        if (password1 != password2):
            print("\nPassword mismatch, try again.")
    del password2    

print(sha512_crypt(password1))
del password1