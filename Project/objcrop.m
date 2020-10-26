function Objcrop=objcrop(Im,sizeIm)
I=im2double(rgb2gray(Im));
I(I<0.6)=0;
I(I>0.1)=1;
size=sizeIm;
a=0;b=0;c=0;d=0;
for i=1:size(1)
    for j=1:size(2)
        if I(i,j)==0
            a=i;
            break;
        end
        if a~=0
            break;
        end
    end
end
for i=size(1):-1:1
    for j=1:size(2)
        if I(i,j)==0
            c=i;
            break;
        end
        if c~=0
            break;
        end
    end
end
for j=1:size(2)
    for i=1:size(1)
        if I(i,j)==0
            b=j;
            break;
        end
        if b~=0
            break;
        end
    end
end
for j=size(2):-1:1
    for i=1:size(1)
        if I(i,j)==0
            d=j;
            break;
        end
        if d~=0
            break;
        end
    end
end
I=imcrop(I,[b a d-b c-a]);
I(I==0)=0.8;
Objcrop=I;

