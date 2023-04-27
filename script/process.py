import numpy as np
import matplotlib.pyplot as plt
from scipy.io import loadmat
from scipy.interpolate import interp1d

# offset
file = loadmat("empty.mat")
data = file["data"]
time = file["timestamp"]
acc = data[:, 0:3]
force = data[:, 3:5]
offset_force = np.mean(force, axis=0)

plt.figure(3)
plt.plot(time, force - offset_force)
plt.show()


file = loadmat("pos2_flex.mat")
data = file["data"]
time = file["timestamp"]
acc = data[:, 0:3]
force = data[:, 3:5]
offset_force = np.mean(force, axis=0)

plt.figure(2)
plt.plot(time, acc[:,0])
plt.show()


types = ["relax", "flex"]
conf = [ "2", "3"]
angles = np.array([85, 110]) + 90

acceleration = []

def zci(v):
    return np.where(np.diff(np.sign(v)))[0]

for i in range(len(conf)):
    for j in range(len(types)):
        filename = "pos" + conf[i] + "_" + types[j]
        file = loadmat(filename)
        data = np.column_stack((file["timestamp"], file["data"]))
        data = data[np.argsort(data[:, 0])]
        time = data[:, 0].astype(float) / 1e6
        acc = data[:, 1:4].astype(float)
        force = data[:, 4:6] - offset_force
        
        x = np.arange(time[0], time[-1], 1 / 1000)
        per = 0
        acceleration = []
        alpha = (angles[i] - 40) * np.pi / 180
        for k in range(2):
            y = interp1d(time, acc[:, k], kind="linear")(x)
    
            ym = np.mean(y)
            yz = y - ym
            zx = x[zci(yz)]
            if per == 0:
                per = 2 * np.mean(np.diff(zx))
            
            peak = zci(yz) + int(per * 1000 / 4)
            A = np.mean(np.abs(yz[peak[:-10]]))
            
            shift = 0
            yp = A * np.sin(2 * np.pi / per * x) + ym
            min_sum = np.sum(np.abs(yp - y))
            for s in np.arange(0, per, 0.001):
                yp = A * np.sin(2 * np.pi / per * (x + s)) + ym
                su = np.sum(np.abs(yp - y))
                if su < min_sum:
                    min_sum = su
                    shift = s
            yp = A * np.sin(2 * np.pi / per * (x + shift)) + ym

            acceleration.append(yp)
        
        acceleration = np.array(acceleration)
        x = acceleration[0] * np.cos(alpha) + acceleration[1] * np.sin(alpha) + 500 * np.cos(np.pi * angles[i] / 180)
        y = -acceleration[1] * np.cos(alpha) + acceleration[0] * np.sin(alpha) + 500 * np.sin(np.pi * angles[i] / 180)
        
        co = "b"
        if j == 1:
            co = "r"
        
        plt.figure(1)
        plt.plot(x, y, co)

        plt.figure(4+j)
        plt.subplot(3, 1, i + 1)
        me = np.mean(force, axis=1)
        print(me.shape, time.shape)
        plt.plot(time[9:], me[9:], co)
        plt.title(f"Force arm angle: {angles[i]}deg")
        plt.legend(["Relaxing", "Flexing"])
        
plt.figure(1)
for i in range(len(conf)):
    plt.plot([0, 500 * np.cos(np.pi * angles[i] / 180)], [0, 500 * np.sin(np.pi * angles[i] / 180)], "-o")

plt.plot([0, 0], [-500, 0], "black")
plt.title("Acceleration for 3 arm configurations")
plt.legend(["Relaxing", "Flexing"])

m = 700
#set the limits of the plot to plus or minus m
plt.xlim(-m, m)
plt.ylim(-m, m)
plt.show()
