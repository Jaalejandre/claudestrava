import re

# Reading the file to check line 286-287
with open('/root/JarvisVault/03 Projects/GromacsMexicano/phase4_cuda_pinned/src/main.cu', 'r') as f:
    lines = f.readlines()
    for i in range(280, 300):
        print(f"{i+1}: {lines[i].strip()}")

