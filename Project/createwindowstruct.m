function WindowStruct=createwindowstruct(window,countdown)
windowsize=size(window);
sizeheight=windowsize(1);
sizewidth=windowsize(2);
%% Number setting
number=imread('number.jpg');
number=im2double(rgb2gray(number));
sizenum=size(number);
numstruct=struct();
for i=1:10
    if i==1
        num=number(:,1:round(sizenum(2)/10));
    elseif i ==6
        num=number(:,round(sizenum(2)/10)*(i-1):round(sizenum(2)/10)*i);
        num(:,1:round(11*sizenum(2)/1220))=1;
    elseif i ==10
        num=number(:,round(sizenum(2)/10)*(i-1):sizenum(2));
    else
        num=number(:,round(sizenum(2)/10)*(i-1):round(sizenum(2)/10)*i);
    end
    num=imresize(num,[round(9/55*sizewidth) round(13/110*sizewidth)]);
    numstruct(i).num=num;
end
%% Window struct
sizenum=size(numstruct(1).num);
windowstruct=struct();
for i=1:countdown
    if i<10
        window(round(5*sizeheight/12):round(5*sizeheight/12+sizenum(1)-1),...
            round(sizewidth/2-sizenum(2)/2):round(sizewidth/2+sizenum(2)/2-1))=numstruct(i).num;     
    else
        %clear the center px
        window(round(5*sizeheight/12):round(5*sizeheight/12+sizenum(1)-1),...
            round(sizewidth/2-41*sizewidth/6800-2):round(sizewidth/2+41*sizewidth/6800+1))=1; 
        %set the left num
        window(round(5*sizeheight/12):round(5*sizeheight/12)+sizenum(1)-1,...
            round(sizeheight+82*sizewidth/6800):round(sizeheight+82*sizewidth/6800)+sizenum(2)-1)...
            =numstruct(fix(i/10)).num;                                                       
        countwindow=i-fix(i/10)*10;
        %set the right num 
        if countwindow==0
            window(round(5*sizeheight/12):round(5*sizeheight/12)+sizenum(1)-1,...
                round(sizewidth/2+41*sizewidth/6800):round(sizewidth/2+41*sizewidth/6800)+sizenum(2)-1)...
                =numstruct(10).num;
        else
            window(round(5*sizeheight/12):round(5*sizeheight/12)+sizenum(1)-1,...
                round(sizewidth/2+41*sizewidth/6800):round(sizewidth/2+41*sizewidth/6800)+sizenum(2)-1)...
                =numstruct(countwindow).num;
        end
    end
    windowstruct(i).window=window;
end
WindowStruct=windowstruct;