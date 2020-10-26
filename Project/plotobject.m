function Window=plotobject(window,type,objectposition,object,gridsize)
    gridsize=gridsize*3/4;
    object=objcrop(object,size(object));
    object=imresize(object,[gridsize gridsize]);
    numobject=size(objectposition);
    % Create random position of object
    for i=1:numobject(2)
        if type=="robot"
            xy=objectposition(i).robotarm;
        else 
            xy=objectposition(i).player;
        end
        window(round(xy(1)-gridsize/2):round(xy(1)+gridsize/2),round(xy(2)-gridsize/2):round(xy(2)+gridsize/2))=object;
    end
Window=window;