import os
import shutil

inpt = input("Really wanna clean this dir? (same effect as git reset --hard but on built components) [type 'CLEAN']")

if inpt == "CLEAN":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    shutil.rmtree('ToasterOS-work', ignore_errors=True)
    shutil.rmtree('pi-gen/stage6', ignore_errors=True)
    shutil.rmtree("pi-gen/work", ignore_errors=True)
    try:
        shutil.move("pi-gen/stg5","pi-gen/stage5")
    except Exception:
        pass

    for stage in ['stage0', 'stage1', 'stage2', 'stage3', 'stage4']:
        skip_image_path = os.path.join('pi-gen', stage, 'SKIP')
        os.system(f"rm -rf {skip_image_path}")
