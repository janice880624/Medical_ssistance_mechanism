function objectposition=position(randomarray,numobject,gridnum,gridsize,sizewidth,sizeheight)
    % Create random position of object
    objpositionstruct=struct();
    for i=1:numobject
        a=fix(randomarray(i)/gridnum)+1;
        b=mod(randomarray(i),gridnum);
        if b==0
            b=gridnum;
            a=a-1;
        end
        objpositionstruct(i).robotarm=[round(a*gridsize-gridsize/2),round(b*gridsize-gridsize/2)];
        objpositionstruct(i).player=[round(a*gridsize-gridsize/2),sizewidth-sizeheight+round(b*gridsize-gridsize/2)];
    end
objectposition=objpositionstruct;