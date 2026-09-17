import re

with open('/root/JarvisVault/03 Projects/GromacsMexicano/phase4_cuda_pinned/src/main.cu', 'r') as f:
    lines = f.readlines()
    
# Looking for division operations in the loop (around line 280+)
for i in range(275, 300):
    if '/' in lines[i]:
        print(f"{i+1}: {lines[i].strip()}")

