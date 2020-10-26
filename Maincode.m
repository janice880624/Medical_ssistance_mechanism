%% finw 
clc
clear all
close all
go=1;
%清除所有跟電腦連接通訊
if ~isempty(instrfind)
    fclose(instrfind);
    delete(instrfind);
end
COM_Y = serial('com5');
set(COM_Y, 'BaudRate', 9600);
set(COM_Y, 'Parity', 'none');
set(COM_Y, 'DataBits', 8);
set(COM_Y, 'StopBit', 1); 
set(COM_Y,'Terminator','CR/LF');
cam=webcam(2);
cam.Resolution='1280x960';
while go<2
    fopen(COM_Y);
    notch_value=0.9;%凹槽門檻       0(黑)~1(白)
    notch_reg_maxdist=0.1;
    reallength_CropImage=96; %Length of two laser in cm
    while (get(COM_Y,'BytesAvailable')==0)
    end
    datascan=fscanf(COM_Y);
    disp(datascan);
    %收到Arduino傳來停止程式
    if datascan=="STOPLOOP"
        pause(0.1);
        flushinput(COM_Y);
        fclose(COM_Y);
        break;
    else
        pause(1.5);
        tStart=tic;
        OriginalImage=snapshot(cam);
        %擷取有效範圍影像
        OriginalImage=imcrop(OriginalImage,[200 1 860 850]);
        gray=rgb2gray(im2double(OriginalImage));
        OriImsize=size(gray);
        find=0;
        %尋找雷射光座標
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
        %找左雷射座標
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
        %找右雷射座標
        rightcropX=i;
        rightcropY=j;
        find=0;
        %擷取雷射限制區域的影像(兩雷射在安裝時知道實際長度，影像寬度就是實際寬度，之後作單位換算)
        CropImage=imcrop(OriginalImage,[leftcropY+2 leftcropX+2 rightcropY-leftcropY-3 800]);
        I = im2double(CropImage);
        sizeI=size(I);
        %% Find origin coordinate
        count_High=0;
        sum_high=0;
        %找影像最亮部分的平均值
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
        %填滿孔洞
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
        %找中心點座標
        OriginX=xy1(1)/countBW;
        OriginY=xy1(2)/countBW;
        %% Find standard line(基準線)
        hsv=rgb2hsv(I);
%         v=hsv(:,:,3);
        v=hsv(:,:,1);
        v(v<0.6)=0;
        filt=imgaussfilt(v,7);
        v(filt<0.3)=0;
        BW=edge(v,'Prewitt',0.3);
        [H,theta,rho] = hough(BW);
        P = houghpeaks(H,5,'threshold',ceil(0.3*max(H(:)))); %houghpeaks(H,5...)代表找出5條線
        lines = houghlines(BW,theta,rho,P,'FillGap',100,'MinLength',150); %FillGap:若兩條線之間兼具小於100pixel就被填滿成為一條，MinLength:容許最短的線150pixel
        %lines是資料結構，包含線的起始點，終點，角度，距離(相對0,0)
        max_len = 0;
        countpoint=1;
        ITSpoint_x(1:length(lines))=0;
        ITSpoint_y(1:length(lines))=0;
        %找焦點
        for a = 1:length(lines)-1
            for b=a+1:length(lines)
                %只找線與線之間角度大於5度的焦點
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
                    %直線方程式在二緯空間是y=ax+b，找出兩條線的方程式，再把x從某個特定值開始跑值到abs(y1-y2)最小視為兩條線的焦點
                    a1=(line_a(4)-line_a(3))/(line_a(2)-line_a(1));
                    b1=-line_a(1)*(line_a(4)-line_a(3))/(line_a(2)-line_a(1))+line_a(3);
                    a2=(line_b(4)-line_b(3))/(line_b(2)-line_b(1));
                    b2=-line_b(1)*(line_b(4)-line_b(3))/(line_b(2)-line_b(1))+line_b(3);
                    if line_a(2)-line_a(1)==0 %當線是垂直於x軸時直接找出焦點
                        ITSpoint_x(countpoint)=line_a(1);
                        ITSpoint_y(countpoint)=round(a2*line_a(1)+b2); %round:取整數,例如: round(1.2)=1,round(1.6)=2
                        countpoint=countpoint+1;
                    else
                        %找x的起始點跟終點，減少運算
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
                        %找出xstep原因是將線很垂直x軸時，每x變化小y就會變化很大，所以要切細才能夠找到abs(y1-y2)的最小值
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
        %以上計算過程都是以顯示圖片的座標，改成影像座標(X,Y顛倒而已)
        for i=1:4
            Pattern_edge_xy(i,1:2)=[ITSpoint_y(i),ITSpoint_x(i)]; %Pattern_edge_xy:物件角落的座標
        end
        %Arrange the point
        %排列焦點(最上方為第一點，最左第二，最下第三，最右第四)
        %note:此程式只是用四邊形的形狀
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
        %基準線定義是最長的線，線的起始點離凹槽中心點最近
        for i=1:4
            if (i==4)
                length(i)=sqrt((pattern_edge_xy(i,1)-pattern_edge_xy(1,1))^2+(pattern_edge_xy(i,2)-pattern_edge_xy(1,2))^2);
                break
            end
            length(i)=sqrt((pattern_edge_xy(i,1)-pattern_edge_xy(i+1,1))^2+(pattern_edge_xy(i,2)-pattern_edge_xy(i+1,2))^2);
        end
        [max,Index]=max(length);
        %Check standard line
        %線的起始點編號一定小於終點
        begin1=Index; %最長線的起始點
        end1=begin1+1;
        %起始點是4終點是1(不是5，因沒有5)
        if end1>4
            end1=end1-4;
        end
        begin2=Index+2; %另外條一樣長的線(一定再對邊所以起始點編號一定差2)
        if begin2>4
            begin2=begin2-4;
        end
        end2=begin2+1;
        if end2>4
            end2=end2-4;
        end
        %計算兩條線起始點離凹槽中心點的距離
        length_1=sqrt((OriginX-pattern_edge_xy(begin1,1))^2+(OriginY-pattern_edge_xy(begin1,2))^2);
        length_2=sqrt((OriginX-pattern_edge_xy(begin2,1))^2+(OriginY-pattern_edge_xy(begin2,2))^2);
        %選擇基準線的起始點與終點
        if length_1<length_2
            beginPoint=begin1;
            endPoint=end1;
        else
            beginPoint=begin2;
            endPoint=end2;
        end
        %計算線與x軸的夾角
        v_1 = [sizeI(1),0,0] - [0,0,0];
        v_2 = [pattern_edge_xy(endPoint,1),pattern_edge_xy(endPoint,2),0] - [pattern_edge_xy(beginPoint,1),pattern_edge_xy(beginPoint,2),0];
        Theta = atan2(norm(cross(v_1, v_2)), dot(v_1, v_2))/pi*180;
        if beginPoint==1
            Theta=-Theta;
        elseif beginPoint==4
            Theta=360-Theta;
        end
        tEnd=toc(tStart); %計算演算法使用時間
        disp(tEnd);
        %% Senddata
        MmPerPixel=reallength_CropImage/sizeI(2); %單位換算(每單位像數實際上的mm長度)
        realX=round(OriginX*MmPerPixel,2); 
        Xstep=round(realX*30.8); %傳給步進馬達的步數X軸
        realY=round(OriginY*MmPerPixel+67,2);
        ThetaStep=round(Theta*17.78); %角度步數
        senddata=num2str(Xstep)+" "+num2str(realY*100)+" "+num2str(ThetaStep); %傳到Arduino的資料
        fprintf(COM_Y,senddata); %傳
        disp(realX);
        disp(realY);
        disp(senddata);
        %% Show 顯示
        subplot(1,2,1), imshow(I);
        subplot(1,2,2), imshow(notch);
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
        pause(0.2);
        flushinput(COM_Y);
        %等待Arduino裝配完再重新回圈
        while (get(COM_Y,'BytesAvailable')==0) 
        end
        datascan=fscanf(COM_Y);
        disp(datascan);
        fclose(COM_Y);
        clearvars -except go cam COM;
        close all
    end
end