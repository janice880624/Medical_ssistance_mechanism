function Window=creategridwindow(ratio,sizewidth,backgroundcolor,linewidth,outlinewidth,linecolor,gridnum,gridsize,object,numobject)
sizeheight=round(sizewidth/ratio);
window=zeros(sizeheight,sizewidth);
window(:,:)=backgroundcolor; %white background
%%Draw Outline
for i=1:outlinewidth
    % Top horizon 
    window(i,:)=linecolor;
    % Left vertical
    window(:,i)=linecolor;
    % Bottom horizon
    window(sizeheight+1-i,:)=linecolor;
    % Right vertical
    window(:,sizewidth+1-i)=linecolor;
end
window(1:sizeheight,sizeheight-(outlinewidth-1)/2:sizeheight+(outlinewidth-1)/2)=linecolor;
window(1:sizeheight,sizewidth-sizeheight-(outlinewidth-1)/2:sizewidth-sizeheight+(outlinewidth-1)/2)=linecolor;
%%Draw grid
for i=1:gridnum-1
    % Left horizon
    window(round(sizeheight/gridnum)*i-(linewidth-1)/2:...
        round(sizeheight/gridnum)*i+(linewidth-1)/2,...
        1:sizeheight)=linecolor;
    % Right horizon
    window(round(sizeheight/gridnum)*i-(linewidth-1)/2:...
        round(sizeheight/gridnum)*i+(linewidth-1)/2,...
        sizewidth-sizeheight:sizewidth)=linecolor;
    % Left vertical
    window(1:sizeheight,...
        round(sizeheight/gridnum)*i-(linewidth-1)/2:...
        round(sizeheight/gridnum)*i+(linewidth-1)/2)=linecolor;
    % Right vertical
    window(1:sizeheight,...
        sizewidth-sizeheight+round(sizeheight/gridnum)*i-(linewidth-1)/2:...
        sizewidth-sizeheight+round(sizeheight/gridnum)*i+(linewidth-1)/2)=linecolor;
end
%% Countdown font setting
time=imread('countdown.jpg');
time=imresize(time,[sizewidth*13/110 sizewidth*13/55]);
time=im2double(rgb2gray(time));
time=1-time;
sizetime=size(time);
window(round(sizeheight/12):round(sizeheight/12)+sizetime(1)-1,round(sizewidth/2-sizetime(2)/2:sizewidth/2+sizetime(2)/2-1))=time;
Window=window;
