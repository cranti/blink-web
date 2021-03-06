function sp = conv2_mirrored(s,c)
%CONV2_MIRRORED
% 2D convolution with mirrored edges to reduce edge effects
% Output of convolution is same size as leading input matrix
%
%FROM:
% MATLAB for Neuroscientists: An Introduction to Scientific Computing in
% MATLAB
%  By Pascal Wallisch, Michael E. Lusignan, Marc D. Benayoun, Tanya I.
%  Baker, Adam Seth Dickey, Nicholas G. Hatsopoulos

[N,M] = size(s);
[n,m] = size(c); %%both n & m should be odd

%enlarge matrix s in preparation for convolution with matrix c via
%mirroring edges to reduce edge effects
padn = round(n/2)-1;
padm = round(m/2)-1;
sp=[zeros(padn,M+(2*padm)); zeros(N,padm) s zeros(N,padm); zeros(padn,M+(2*padm))];
sp(1:padn,:)=flipud(sp(padn+1:2*padn,:));
sp(padn + N +1:N+2*padn,:)= flipud(sp(N+1:N+padn,:));
sp(:,1:padm)=fliplr(sp(:,padm+1:2*padm));
sp(:,padm + M + 1:M + 2*padm) = fliplr(sp(:,M+1:M+padm));

%perform 2D convolution
sp = conv2(sp,c,'valid');
