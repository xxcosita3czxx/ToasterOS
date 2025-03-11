import cv2
import customtkinter as ctk
from PIL import Image, ImageTk

video_path = "betwen.mp4"
cap = cv2.VideoCapture(video_path)

root = ctk.CTk()
root.title("CTk Video Player")
root.geometry("800x600")

video_label = ctk.CTkLabel(root, text="")
video_label.pack(expand=True)

def update_frame():
    if cap.isOpened():
        ret, frame = cap.read()
        if ret:
            frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            img = Image.fromarray(frame)
            img_tk = ImageTk.PhotoImage(img)
            video_label.img_tk = img_tk
            video_label.configure(image=img_tk)
            root.after(17, update_frame)  # 17ms delay → ~60 FPS
        else:
            cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
            root.after(17, update_frame)

update_frame()
root.mainloop()
cap.release()
