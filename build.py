import os
import shutil
import sys
try:
    shutil.rmtree("iso")
except FileNotFoundError:
    pass
   
result = os.system("docker build --platform linux/arm64 -t toasteros-buildimage .")
if result != 0:
    print("Docker build failed.")
    sys.exit(1)

os.system("docker run --name toasteros-build -t toasteros-buildimage")
os.system("docker cp toasteros-build:/home/build/iso ./iso")
os.system("docker rm toasteros-build")

try:
    if sys.argv[1] == "deploy":
        os.system("deploy.py")
except Exception:
    pass
