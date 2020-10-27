clc
clear all
close all

objectleft=0;
Im=imread('new.jpg');

I=rgb2gray(im2double(Im));
I(I<0.8)=0;
I(I>=0.8)=1;

se = strel('cube',3)