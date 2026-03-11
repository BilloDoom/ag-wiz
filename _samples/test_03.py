from godot import *

# --- Sandbox Demo ---
# This script deliberately attempts operations that are not permitted:
#   - Reading a file with open()
#   - Writing a file with open()
#   - Importing os to list directories
#   - Importing socket to open a TCP connection
#   - Importing urllib to fetch a URL
#   - Importing subprocess to run a shell command
#   - Importing requests (third-party HTTP library)
#
# Each attempt should produce a magenta [SANDBOX] warning in the console
# and be silently ignored rather than crashing the script.

print("=== Sandbox restriction test ===")
print("Each blocked call should produce a magenta warning.")
print("")

# --- 1. File read ---
print("Attempting open() for reading...")
result = open("C:/Windows/System32/drivers/etc/hosts", "r")
print("open() returned: " + str(result))   # expected: None

# --- 2. File write ---
print("")
print("Attempting open() for writing...")
result = open("C:/Users/Lard Bucket/Desktop/evil.txt", "w")
print("open() returned: " + str(result))   # expected: None

# --- 3. os module ---
print("")
print("Attempting: import os")
import os
print("os.getcwd() = " + str(os.getcwd()) if hasattr(os, 'getcwd') else "os module blocked")

# --- 4. socket module ---
print("")
print("Attempting: import socket")
import socket
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(("example.com", 80))
    print("socket connected (should not happen)")
except Exception as e:
    print("socket error (expected): " + str(e))

# --- 5. urllib ---
print("")
print("Attempting: import urllib.request")
import urllib.request
try:
    resp = urllib.request.urlopen("http://example.com")
    print("urllib response (should not happen): " + str(resp))
except Exception as e:
    print("urllib error (expected): " + str(e))

# --- 6. subprocess ---
print("")
print("Attempting: import subprocess")
import subprocess
try:
    out = subprocess.check_output(["whoami"])
    print("subprocess output (should not happen): " + str(out))
except Exception as e:
    print("subprocess error (expected): " + str(e))

# --- 7. requests (third-party) ---
print("")
print("Attempting: import requests")
import requests
try:
    r = requests.get("http://example.com")
    print("requests response (should not happen): " + str(r))
except Exception as e:
    print("requests error (expected): " + str(e))

print("")
print("=== Test complete ===")
print("All blocked operations above should have produced magenta warnings.")
print("No files were written, no network connections were made.")
