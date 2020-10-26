function J=regiongrowing(I,x,y,reg_maxdist)
if(exist('reg_maxdist','var')==0), reg_maxdist=0.2; end
if(exist('y','var')==0), figure, imshow(I,[]); [y,x]=getpts; y=round(y(1)); x=round(x(1)); end
J = zeros(size(I)); 
Isizes = size(I); 
reg_mean = I(x,y); 
reg_size = 1; 
neg_free = 10000; neg_pos=0;
neg_list = zeros(neg_free,3); 
pixdist=0; 
neigb=[-1 0; 1 0; 0 -1;0 1];
while(pixdist<reg_maxdist&&reg_size<numel(I))
    for j=1:4,
        xn = x +neigb(j,1); yn = y +neigb(j,2);
        ins=(xn>=1)&&(yn>=1)&&(xn<=Isizes(1))&&(yn<=Isizes(2));
        if(ins&&(J(xn,yn)==0)) 
                neg_pos = neg_pos+1;
                neg_list(neg_pos,:) = [xn yn I(xn,yn)]; J(xn,yn)=1;
        end
    end
    if(neg_pos+10>neg_free), neg_free=neg_free+10000; neg_list((neg_pos+1):neg_free,:)=0; end
    dist = abs(neg_list(1:neg_pos,3)-reg_mean);
    [pixdist, index] = min(dist);
    J(x,y)=2; reg_size=reg_size+1;
    reg_mean= (reg_mean*reg_size + neg_list(index,3))/(reg_size+1);
    x = neg_list(index,1); y = neg_list(index,2);
    neg_list(index,:)=neg_list(neg_pos,:); neg_pos=neg_pos-1;
end
J=J>1;
