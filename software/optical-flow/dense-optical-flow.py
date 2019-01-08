import math
import cv2
import imutils
import numpy as np

cap = cv2.VideoCapture("motion-4-long-small.mp4")
ret, frame1 = cap.read()
prvs = cv2.cvtColor(frame1,cv2.COLOR_BGR2GRAY)
hsv = np.zeros_like(frame1)
hsv[...,1] = 255

out = cv2.VideoWriter('output.avi', -1, 20.0, (640,480))

blankFrame = None
first = True
while True:
    ret, frame2 = cap.read()
    next = cv2.cvtColor(frame2, cv2.COLOR_BGR2GRAY)
    flow = cv2.calcOpticalFlowFarneback(prvs, next, None, 0.5, 3, 15, 3, 7, 1.2, 0)
    mag, ang = cv2.cartToPolar(flow[..., 0], flow[..., 1])
    #hsv[..., 0] = ang * 180 / np.pi / 2
    hsv[..., 0] = 0
    hsv[..., 1] = 0
    hsv[..., 2] = mag * (256/16)#cv2.normalize(mag, None, 0, 255, cv2.NORM_MINMAX)

    bgr = cv2.cvtColor(hsv, cv2.COLOR_HSV2BGR)
    #bgr = cv2.min(bgr, frame2)

    if blankFrame is None:
        blankFrame = np.zeros_like(bgr)

    #if np.average(mag) < 0.2:
    #    bgr = blankFrame

    gray = cv2.cvtColor(bgr,cv2.COLOR_BGR2GRAY)
    thresh = cv2.threshold(gray, 10, 255, cv2.THRESH_BINARY)[1]

    cnts = cv2.findContours(thresh.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    cnts = cnts[0] if imutils.is_cv2() else cnts[1]

    for c in cnts:
            # compute the center of the contour
            M = cv2.moments(c)

            if cv2.contourArea(c) < 3000:
                continue

            if M["m00"] == 0:
                continue

            cX = int(M["m10"] / M["m00"])
            cY = int(M["m01"] / M["m00"])

            angleAtCenter = ang[cY, cX]
            r = 50
            compassX = cX + int(r * math.cos(angleAtCenter))
            compassY = cY + int(r * math.sin(angleAtCenter))

            #cv2.arrowedLine(bgr, (cX, cY), (compassX, compassY), (0, 0, 255), 5, 8, 0, 0.2)
     
            # draw the contour and center of the shape on the image
            #cv2.drawContours(bgr, [c], -1, (0, 255, 0), 2)
            #cv2.circle(bgr, (cX, cY), 7, (255, 255, 255), -1)
            #cv2.putText(bgr, "center", (cX - 20, cY - 20),
            #        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 2)

    #cv2.addWeighted(bgr, np.average(mag) * 12, blankFrame, 0.0, 0, bgr)
    cv2.imshow('frame2', bgr)
    out.write(bgr)

    k = cv2.waitKey(16) & 0xff
    if k == 27:
        break
    elif k == ord('s'):
        cv2.imwrite('opticalfb.png',frame2)
        cv2.imwrite('opticalhsv.png',bgr)
    prvs = next

cap.release()
out.release()
cv2.destroyAllWindows()
