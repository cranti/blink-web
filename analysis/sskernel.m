function [optW, C, W] = sskernel(x, W, hWaitBar)
%SSKERNEL
%
% Function `sskernel' returns optimal bandwidth (standard deviation) 
% of the Gauss density function used in kernel density estimation.
% Optimization principle is to minimize expected L2 loss function between 
% the kernel estimate and an unknown underlying density function. 
% An assumption made is merely that samples are drawn from the density
% independently each other.
%
% The optimal bandwidth is obtained as a minimizer of the formula, 
% sum_{i,j} \int k(x - x_i) k(x - x_j) dx  -  2 sum_{i~=j} k(x_i - x_j), 
% where k(x) is the kernel function. 
%
% Original paper:
% Shimazaki and Shinomoto, Kernel Bandwidth Optimization in Spike Rate Estimation 
% Journal of Computational Neuroscience 2009
% http://dx.doi.org/10.1007/s10827-009-0180-4
%
% Example usage:
% optW = sskernel(x); ksdensity(x,'width',optW); 
%
% Statistics Toolbox is required to execute ksdensity. 
% If it is not available, define the Gauss function as
% `Gauss = @(s,w) 1/sqrt(2*pi)/w*exp(-s.^2/2/w^2);'.
% Computing `mean( Gauss(x-s,optW) )' provides a kernel density estimate at s.
%
% Input argument
% x:    Sample data vector. 
% W (optional): 
%       A vector of kernel bandwidths.
%       The optimal bandwidth is selected from the elements of W.  
%       Default value is W = logspace(log10(2*dx),log10((x_max - x_min)),50).
%       * Do not search bandwidths smaller than a sampling resolution of data.
% hWaitBar (optional): 
%       Handle for a waitbar - update user with progress
%
% REMOVED:
% str (optional):
%       String that specifies the kernel type.
%       This option is reserved for future extention.
%       Default str = 'Gauss'.
%
% Output argument
% optW: Optimal kernel bandwidth.
% W:    Kernel bandwidths examined. 
% C:    Cost functions of W.
%
% See also SSHIST
%
% Copyright (c) 2009, Hideaki Shimazaki All rights reserved.
% http://2000.jukuin.keio.ac.jp/shimazaki
%
% Modified by Carolyn Ranti
% 6.1.2015

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parameters Settings

x = single(reshape(x,1,numel(x)));

str = 'Gauss';

if nargin < 2 || isempty(W)
    x_min = min(x);
    x_max = max(x);
  

    buf = sort(abs(diff(sort(x))));
    dx = min(buf(logical(buf ~= 0)));
    Wmin = 2*dx; Wmax = 1*(x_max - x_min);
    W = logspace(log10(Wmin),log10(Wmax),50);
end

if nargin<3 || isempty(hWaitBar)
    waitBarLen = 0;
else
    waitBarLen = length(W) + 1;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute a Cost Function

%update progress bar
if waitBarLen
    waitbar(1/waitBarLen,hWaitBar);
end

N_total = length(x);

tau = (triu( ones(N_total,1,'single')*x - x'*ones(1,N_total,'single'), 1)); 
idx = (triu( ones(N_total,N_total,'single'), 1)); 
TAU = (tau(logical(idx)).^2); 

C = zeros(1,length(W),'single');

for k = 1: length(W)
    
    if waitBarLen
        %Check for "cancel" button press, return empty optW
        if getappdata(hWaitBar,'canceling')
            delete(hWaitBar);
            optW = [];
            return
        end
        
        %update progress bar
        waitbar(k/waitBarLen,hWaitBar);
    end

	w = single(W(k));
	C(k) = (N_total/w + 1/w*sum(sum(2*exp(-TAU/4/w/w) - 4*sqrt(2)*exp(-TAU/2/w/w))));
end

C = C/2/sqrt(pi);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Optimal Bin Size Selection
[optC,nC]=min(C); 
optW = W(nC);

