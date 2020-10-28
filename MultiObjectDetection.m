clc % 清除命令窗口的內容
clear all % 清除工作空間的所有變量
close all

objectleft=0;
Im=imread('new.jpg'); %照片檔讀取
% 轉成灰階圖
I=rgb2gray(im2double(Im)); %轉成灰階圖
I(I<0.8)=0;
I(I>=0.8)=1;
se = strel('cube',3); %建立長度為3的立方體
I= imerode(I,se); %圖像腐蝕
I=imdilate(I,se); %圖像膨脹
[L, n]=bwlabel(I); %對二維二值圖像中的連通分量進行標注
sizeI=size(I);
Object_struct=struct('object',zeros(sizeI(1),sizeI(2)),'theta',0,'centroid',zeros(1,2),...
                     'point1',zeros(1,2),'point2',zeros(1,2)); %創建一個新的結構體
for objectcount=1:n
    object=zeros(sizeI(1),sizeI(2));
    totalx_O=0;
    totaly_O=0;
    pointcount_O=0;
    for i=1:sizeI(1)
        for j=1:sizeI(2)
            if L(i,j)==objectcount
                object(i,j)=1;
                totalx_O=totalx_O+i;
                totaly_O=totaly_O+j;
                pointcount_O=pointcount_O+1;
            else
                object(i,j)=0;
            end
        end
    end
    edge_O=edge(object);
    [H_O,T_O,R_O] = hough(edge_O);
    P_O  = houghpeaks(H_O,1,'threshold',ceil(0.3*max(H_O(:))));
    lines_O = houghlines(edge_O,T_O,R_O,P_O,'FillGap',20,'MinLength',7);
    x_O=totalx_O/pointcount_O;
    y_O=totaly_O/pointcount_O;
    Object_struct(objectcount).object=object;
    Object_struct(objectcount).theta=180-lines_O.theta;
    Object_struct(objectcount).centroid=[x_O,y_O];
    Object_struct(objectcount).point1=lines_O.point1;
    Object_struct(objectcount).point2=lines_O.point2;
end
figure, imshow(Im),hold on;
for i=1:n
    plot(Object_struct(i).centroid(2),Object_struct(i).centroid(1),'greenx','linewidth',2,'MarkerSize',10); %plot centroid
    text(Object_struct(i).centroid(2),Object_struct(i).centroid(1),sprintf('%d',i),'fontsize',30,'fontweight','bold','color','r');
    text(Object_struct(i).centroid(2)-75,Object_struct(i).centroid(1)-25,sprintf('(%.1f,%.1f)',...
         Object_struct(i).centroid(1),Object_struct(i).centroid(2)),'fontsize',15,'color','b'); %text centroid coordinate
    xy = [Object_struct(i).point1; Object_struct(i).point2]; %plot line
    plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green'); %plot line
    text(Object_struct(i).centroid(2)-50,Object_struct(i).centroid(1)+25,sprintf('\\theta=%.1f^{o}',... %text theta
         Object_struct(i).theta),'fontsize',15,'color','b');
end


