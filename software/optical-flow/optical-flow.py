import numpy as np
import math
import cv2
import sys

cap = cv2.VideoCapture('motion-4-long.mp4')

# params for ShiTomasi corner detection
feature_params = dict(maxCorners = 100,
                      qualityLevel = 0.3,
                      minDistance = 7,
                      blockSize = 7)

# Parameters for lucas kanade optical flow
lk_params = dict(winSize  = (15,15),
                 maxLevel = 2,
                 criteria = (cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 10, 0.03))

# Create some random colors
color = np.random.randint(0, 255, (100, 3))

# Take first frame and find corners in it
ret, old_frame = cap.read()
old_gray = cv2.cvtColor(old_frame, cv2.COLOR_BGR2GRAY)

videoWidth = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
videoHeight = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)
gridSize = 200
gridWidth = math.floor(videoWidth / gridSize) - 1
gridHeight = math.floor(videoHeight / gridSize) - 1

print(gridWidth, gridHeight)

p0 = np.empty((gridWidth * gridHeight, 1, 2), dtype=np.float32)
#p0 = cv2.goodFeaturesToTrack(old_gray, mask = None, **feature_params)
for y in range(0, gridHeight):
    for x in range(0, gridWidth):
        i = y * gridWidth + x

        p0[i][0][0] = x * gridSize + gridSize
        p0[i][0][1] = y * gridSize + gridSize

# Create a mask image for drawing purposes
mask = np.zeros_like(old_frame)

while True:
    ret, frame = cap.read()
    frame_gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    # calculate optical flow
    p1, st, err = cv2.calcOpticalFlowPyrLK(old_gray, frame_gray, p0, None, **lk_params)

    if p1 is None:
        continue

    # Select good points
    good_new = p1[st == 1]
    good_old = p0[st == 1]

    # draw the tracks
    for i, (new, old) in enumerate(zip(good_new, good_old)):
        a, b = new.ravel()
        c, d = old.ravel()
        mask = cv2.line(mask, (a,b),(c,d), color[i].tolist(), 2)
        frame = cv2.circle(frame,(a,b),5,color[i].tolist(),-1)

    img = cv2.add(frame,mask)
    cv2.imshow('frame', img)
    k = cv2.waitKey(30) & 0xff

    if k == 27:
        break

    # Now update the previous frame and previous points
    old_gray = frame_gray.copy()
    p0 = good_new.reshape(-1, 1, 2)

cv2.destroyAllWindows()
cap.release()
