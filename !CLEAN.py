import os
import shutil

os.chdir(os.path.dirname(os.path.abspath(__file__)))
shutil.rmtree('ToasterOS-work', ignore_errors=True)
shutil.rmtree('pi-gen/stage6', ignore_errors=True)
shutil.rmtree("pi-gen/work")
shutil.move("pi-gen/stg5","pi-gen/stage5")