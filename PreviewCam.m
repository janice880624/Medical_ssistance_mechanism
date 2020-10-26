clc
clearvars
close all
% num=2;
% cam=webcam(num);
% preview(cam);
% if ~isempty(instrfind)
%     fclose(instrfind);
%     delete(instrfind);
% end
% COM4 = serial('COM4');
% set(COM4, 'BaudRate', 9600);
% COM3 = serial('COM3');
% set(COM3, 'BaudRate', 9600);
% fopen(COM3);
% fopen(COM4);
% pause(2);
% fprintf(COM3,"5");
% fprintf(COM4,"4");

%% Code
notch_value=0.9;%¥W¼ÑªùÂe       0(¶Â)~1(¥Õ)
notch_reg_maxdist=0.1;
reallength_CropImage=96;
tStart=tic;
OriginalImage=imread('test.jpg');
% OriginalImage=imcrop(OriginalImage,[200 1 860 850]);
gray=rgb2gray(im2double(OriginalImage));
OriImsize=size(gray);
find=0;
for j=1:OriImsize(2)
    for i=1:OriImsize(1)
        if gray(i,j)>0.95
            find=1;
            break;
        end
    end
    if find==1
        break;
    end
end
leftcropX=i;
leftcropY=j;
find=0;
for j=OriImsize(2):-1:1
    for i=1:OriImsize(1)
        if gray(i,j)>0.95
            find=1;
            break;
        end
    end
    if find==1
        break;
    end
end
rightcropX=i;
rightcropY=j;
find=0;
CropImage=imcrop(OriginalImage,[leftcropY+2 leftcropX+2 rightcropY-leftcropY-3 800]);
I = im2double(CropImage);
sizeI=size(I);
%% Find origin coordinate
count_High=0;
sum_high=0;
for x=1:sizeI(1)
    for y=1:sizeI(2)
        if I(x,y)>notch_value
            count_High=count_High+1;
            sum_high=sum_high+I(x,y);
        end
    end
end
highavg=sum_high/count_High;
count_high=0;
%Find coordinate for regrowing
for x=1:sizeI(1)
    for y=1:sizeI(2)
        if count_high>count_High/2.5
            break
        end
        if I(x,y)>highavg
            count_high=count_high+1;
        end
    end
    if count_high>count_High/2.5
        break
    end
end
notch_seg = regiongrowing(I,x,y,notch_reg_maxdist);
notch_seg = im2uint8(notch_seg);
notch=notch_seg(:,:,1);
notch(notch>20)=255;
notch=imfill(notch,'holes');
BW = edge(notch,'Canny');
xy1(1:2)=0;
countBW=0;
for i=1:sizeI(1)
    for j=1:sizeI(2)
        if BW(i,j)==1
            countBW=countBW+1;
            xy1(1)=xy1(1)+i;
            xy1(2)=xy1(2)+j;
        end
    end
end
OriginX=xy1(1)/countBW;
OriginY=xy1(2)/countBW;
%% Find standard line
hsv=rgb2hsv(I);
%         v=hsv(:,:,3);
v=hsv(:,:,1);
v(v<0.6)=0;
filt=imgaussfilt(v,7);
v(filt<0.3)=0;
BW=edge(v,'Prewitt',0.3);
[H,theta,rho] = hough(BW);
P = houghpeaks(H,5,'threshold',ceil(0.3*max(H(:))));
lines = houghlines(BW,theta,rho,P,'FillGap',100,'MinLength',150);
max_len = 0;
countpoint=1;
ITSpoint_x(1:length(lines))=0;
ITSpoint_y(1:length(lines))=0;
for a = 1:length(lines)-1
    for b=a+1:length(lines)
        if abs(lines(a).theta-lines(b).theta)<5
            continue;
        else
            if lines(a).theta>-20 && lines(a).theta<20
                line_a=[lines(a).point1;lines(a).point2];
                line_b=[lines(b).point1;lines(b).point2];
            else
                line_b=[lines(a).point1;lines(a).point2];
                line_a=[lines(b).point1;lines(b).point2];
            end
            a1=(line_a(4)-line_a(3))/(line_a(2)-line_a(1));
            b1=-line_a(1)*(line_a(4)-line_a(3))/(line_a(2)-line_a(1))+line_a(3);
            a2=(line_b(4)-line_b(3))/(line_b(2)-line_b(1));
            b2=-line_b(1)*(line_b(4)-line_b(3))/(line_b(2)-line_b(1))+line_b(3);
            if line_a(2)-line_a(1)==0
                ITSpoint_x(countpoint)=line_a(1);
                ITSpoint_y(countpoint)=round(a2*line_a(1)+b2);
                countpoint=countpoint+1;
            else
                if b1<0
                    xstart=-b1/a1;
                    xend=(sizeI(1)-b1)/a1;
                end
                if b1>sizeI(1)
                    xstart=(sizeI(1)-b1)/a1;
                    xend=-b1/a1;
                end
                if b1>0 && b1<sizeI(1)
                    xstart=0;
                    if a1<0
                        xend=-b1/a1;
                    else
                        xend=(sizeI(1)-b1)/a1;
                    end
                end
                if xend>sizeI(2)
                    xend=sizeI(2);
                end
                xstep=(xend-xstart)/sizeI(2);
                for x=xstart:xstep:xend
                    y1=a1*x+b1;
                    y2=a2*x+b2;
                    if abs(y1-y2)<2
                        ITSpoint_x(countpoint)=round(x);
                        ITSpoint_y(countpoint)=round((y1+y2)/2);
                        countpoint=countpoint+1;
                        break;
                    end
                end
            end
        end
    end
end
Pattern_edge_xy(:,:)=0;
pattern_edge_xy(:,:)=0;
%Change the plot point coordinate to image coordinate
for i=1:4
    Pattern_edge_xy(i,1:2)=[ITSpoint_y(i),ITSpoint_x(i)];
end
%Arrange the point
[Xmin,Xminindex]=min(Pattern_edge_xy(:,1));
for i=1:4
    if i==Xminindex
        continue
    end
    if Xmin-Pattern_edge_xy(i,1)==0 && Pattern_edge_xy(i,2)-Pattern_edge_xy(Xminindex,2)<0
        Xminindex=i;
        break
    end
end
[Xmax,Xmaxindex]=max(Pattern_edge_xy(:,1));
for i=1:4
    if i==Xmaxindex
        continue
    end
    if Xmax-Pattern_edge_xy(i,1)==0 && Pattern_edge_xy(i,2)-Pattern_edge_xy(Xmaxindex,2)>0
        Xmaxindex=i;
        break
    end
end
[Ymin,Yminindex]=min(Pattern_edge_xy(:,2));
for i=1:4
    if i==Yminindex
        continue
    end
    if Ymin-Pattern_edge_xy(i,2)==0 && Pattern_edge_xy(i,1)-Pattern_edge_xy(Xminindex,1)>0
        Yminindex=i;
        break
    end
end
[Ymax,Ymaxindex]=max(Pattern_edge_xy(:,2));
for i=1:4
    if i==Ymaxindex
        continue
    end
    if Ymax-Pattern_edge_xy(i,2)==0 && Pattern_edge_xy(i,1)-Pattern_edge_xy(Xmaxindex,1)<0
        Xmaxindex=i;
        break
    end
end
pattern_edge_xy(1,1:2)=Pattern_edge_xy(Xminindex,1:2);
pattern_edge_xy(2,1:2)=Pattern_edge_xy(Yminindex,1:2);
pattern_edge_xy(3,1:2)=Pattern_edge_xy(Xmaxindex,1:2);
pattern_edge_xy(4,1:2)=Pattern_edge_xy(Ymaxindex,1:2);
length(1:4)=0;
for i=1:4
    if (i==4)
        length(i)=sqrt((pattern_edge_xy(i,1)-pattern_edge_xy(1,1))^2+(pattern_edge_xy(i,2)-pattern_edge_xy(1,2))^2);
        break
    end
    length(i)=sqrt((pattern_edge_xy(i,1)-pattern_edge_xy(i+1,1))^2+(pattern_edge_xy(i,2)-pattern_edge_xy(i+1,2))^2);
end
[max,Index]=max(length);
%Check standard line
begin1=Index;
end1=begin1+1;
if end1>4
    end1=end1-4;
end
begin2=Index+2;
if begin2>4
    begin2=begin2-4;
end
end2=begin2+1;
if end2>4
    end2=end2-4;
end
length_1=sqrt((OriginX-pattern_edge_xy(begin1,1))^2+(OriginY-pattern_edge_xy(begin1,2))^2);
length_2=sqrt((OriginX-pattern_edge_xy(begin2,1))^2+(OriginY-pattern_edge_xy(begin2,2))^2);
if length_1<length_2
    beginPoint=begin1;
    endPoint=end1;
else
    beginPoint=begin2;
    endPoint=end2;
end
v_1 = [sizeI(1),0,0] - [0,0,0];
v_2 = [pattern_edge_xy(endPoint,1),pattern_edge_xy(endPoint,2),0] - [pattern_edge_xy(beginPoint,1),pattern_edge_xy(beginPoint,2),0];
Theta = atan2(norm(cross(v_1, v_2)), dot(v_1, v_2))/pi*180;
if beginPoint==1
    Theta=-Theta;
elseif beginPoint==4
    Theta=360-Theta;
end
tEnd=toc(tStart);
disp(tEnd);
% %% Senddata
MmPerPixel=reallength_CropImage/sizeI(2);
realX=round(OriginX*MmPerPixel,2);
Xstep=round(realX*30.8);
realY=round(OriginY*MmPerPixel+67,2);
ThetaStep=round(Theta*17.78);
% %         senddata=num2str(realX)+" "+num2str(realY)+" "+num2str(realTheta);
% senddata=num2str(Xstep)+" "+num2str(realY*100)+" "+num2str(ThetaStep);
% fprintf(COM_Y,senddata);
% disp(realX);
% disp(realY);
% disp(senddata);
%% Show
subplot(2,3,1), imshow(OriginalImage);
subplot(2,3,2), imshow(gray);
subplot(2,3,3), imshow(v);
subplot(2,3,4), imshow(I);
subplot(2,3,5), imshow(notch);
figure, imshow(I), hold on
plot(OriginY,OriginX,'greenx','linewidth',2,'MarkerSize',10);
text(OriginY-50,OriginX-25,sprintf('(%.2f,%.2f)',realX,realY-63.5),'fontsize',15,'color','b');
xaxis=text(-20,sizeI(1)/2,'7cm','fontsize',20);
set(xaxis,'rotation',90);
yaxis=text(sizeI(2)/2,-20,'105mm','fontsize',20);
plot([1,sizeI(2)],[1,1],'LineWidth',2,'Color',[1, 0.5, 0.5]);
plot([1,1],[sizeI(1),1],'LineWidth',2,'Color',[1, 0.5, 0.5]);
if beginPoint==4
    plot([pattern_edge_xy(beginPoint,2),pattern_edge_xy(endPoint,2)],[pattern_edge_xy(beginPoint,1),pattern_edge_xy(endPoint,1)],'LineWidth',2,'Color','green');
else
    plot(pattern_edge_xy(beginPoint:endPoint,2),pattern_edge_xy(beginPoint:endPoint,1),'LineWidth',2,'Color','green');
end
text(-25,-20,sprintf('(0,0)'),'fontsize',20);
plot(pattern_edge_xy(beginPoint,2),pattern_edge_xy(beginPoint,1),'yellowo','LineWidth',2,'MarkerSize',7);
plot(pattern_edge_xy(endPoint,2),pattern_edge_xy(endPoint,1),'rx','LineWidth',2,'MarkerSize',7);
text(sizeI(2)*3/4,sizeI(1)*1/4,sprintf('\\theta=%.2f^{o}',Theta),'fontsize',20,'color','w');


