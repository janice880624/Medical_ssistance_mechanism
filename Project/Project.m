clc
clear all
close all
%% Initial setting
% Empty all comunication
% if ~isempty(instrfind)
%     fclose(instrfind);
%     delete(instrfind);
% end
% % Comunication setting
% COM_XY = serial('com1');
% set(COM_XY, 'BaudRate', 9600);
% COM_C = serial('com2');
% set(COM_C, 'BaudRate', 9600);
% COM_CONVEYOR = serial('com3');
% set(COM_CONVEYOR, 'BaudRate', 9600);
% fopen(COM_XY);
% fopen(COM_C);
% fopen(COM_CONVEYOR);
% % Camera setting
% playercam=webcam(2);
% playercam.Resolution='1280x960';
% robotcam=webcam(3);
% robotcam.Resolution='1280x960';
% Real length(cm) per pixel
lengthplayer=25;
lengthrobot=30;
% Game setting
ratio=2.75; %55cm/20cm
sizewidth=2000; %pixel
sizeheight=round(sizewidth/ratio);
backgroundcolor=1; %white background
linewidth=5; %odd number
outlinewidth=11; %odd number
linecolor=0.5;
gridnum=4;
gridsize=round(sizeheight/gridnum);
countdown=5; %set game countdown
numobject=5;
hexobject=imread('hex.png');
circleobject=imread('circle.png');
%% Create window
% Setting display window
window=creategridwindow(ratio,sizewidth,backgroundcolor,linewidth,outlinewidth,linecolor,gridnum);
% Create random object position
array=(1:gridnum^2);
randomarray(1:numobject)=0;
for i=1:numobject
    randomarray(i)=array(randi(numel(array)));
    array=setdiff(array,randomarray(i));
end
% Struct with robot arm position and player position
objectposition=position(randomarray,numobject,gridnum,gridsize,sizewidth,sizeheight);
% Create arm play region
window=plotobject(window,"robot",objectposition,hexobject,gridsize);
% Create player play region
window=plotobject(window,"player",objectposition,circleobject,gridsize);
% Create window with countdown
windowstruct=createwindowstruct(window,countdown);
%% Maincode

% Show window
% Set window to fullscreen
figure('units','normalized','outerposition',[0 0 1 1])
set(gcf,'MenuBar','none')
set(gca,'Position',[0 0 1 1 ])
set(gcf,'NumberTitle','off');
tStart=tic;
%Show 
for i=countdown:-1:1
    imshow(windowstruct(i).window);
    pause(1);
end
tEnd=toc(tStart);
disp(tEnd);
close