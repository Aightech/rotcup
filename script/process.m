%% offset
file = load("empty.mat");
data = file.data;
time = file.timestamp;
acc = data(:, 1:3);
force = data(:, 4:5);
offset_force = mean(force);
plot(time, force-offset_force)
%%
types = ["relax","flex"];
conf=["1", "2", "3"];
angles=[0,85,110]+90;

acceleration = [];
zci = @(v) find(v(:).*circshift(v(:), [-1 0]) <= 0);  

% w=2*pi/per;
% C=m*r*w^2
% C/Acos(phi) = D;
% C/Asin(phi) = (Iw - K/w);

for i = 1:length(conf)
    for j = 1:length(types)
        filename = "pos" + conf(i)+"_"+types(j);
        file = load(filename);
        data = [file.timestamp file.data ];
        data = sortrows(data);
        time = double(data(:,1))/1000000;
        acc = double(data(:, 2:4));
        force = data(:, 5:6)-int64(offset_force);

        
        
        x = time(1):1/1000:time(end);
        per=0;
        acceleration = [];
        alpha=(angles(i)-40)*pi/180;
        for k = 1:2
            y = interp1(time,acc(:,k),x);
    
            ym = mean(y);                    
            yz = y-mean(y);
            zx = x(zci(yz));     % Find zero-crossing
            if per==0
            per = 2*mean(diff(zx));                     % Estimate period
            end
           
            peak=zci(yz)+floor(per*1000/4);
            A=mean(abs(yz(peak(1:end-10))));                         
            
            shift = 0;
            yp = A*sin(2*pi/per*(x))+ym;
            min_sum=sum(abs(yp-y));
            for s = 0:0.001:per
                yp = A*sin(2*pi/per*(x+s))+ym;
                su=sum(abs(yp-y));
                if su < min_sum
                    min_sum = su;
                    shift=s;
                end
            end
            yp = A*sin(2*pi/per*(x+shift))+ym;


            if(length(acceleration)==0)
                acceleration=yp;
            else
                acceleration=[acceleration; yp];
            end
        end
        x=acceleration(1,:).*cos(alpha)+ acceleration(2,:).*sin(alpha)+500*cos(pi*angles(i)/180);
        y=-acceleration(2,:).*cos(alpha)+ acceleration(1,:).*sin(alpha)+500*sin(pi*angles(i)/180);
        %figure(1)
        co="b"
        if j==2
            co="r"
        end
        figure(1)
        plot(x, y, co)
        hold on;

        figure(2)
        subplot(3,1,i)
        me = mean(force,2)
        plot(time(10:end),me(10:end), co)
        title("Force arm angle: " + angles(i) + "deg")
        legend("Relaxing", "Flexing")
        hold on
        
    end
end

figure(1)
for i = 1:length(conf)
    plot([0 500*cos(pi*angles(i)/180)], [0 500*sin(pi*angles(i)/180)], "-o")
end
figure(1)
plot([0 0], [-500 0], "-oblack")
title("Acceleration for 3 arm configurations")
legend("Relaxing", "Flexing")


m=700
figure(1)
axis([-m m -m m], "equal")
hold off;                 % Returns Zero-Crossing Indices Of Argument Vector

