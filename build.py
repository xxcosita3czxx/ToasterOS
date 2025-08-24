import os
import shutil
try:
    shutil.rmtree("iso")
except FileNotFoundError:
    pass

os.system("docker build -t toasteros-buildimage .")
os.system("docker run --name toasteros-build -t toasteros-buildimage")
os.system("docker cp toasteros-build:/home/build/iso ./iso")
os.system("docker rm toasteros-build")