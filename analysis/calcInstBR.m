% INITIAL DRAFT DONE - 11.24.2014
% Calculate instantaneous blink rate, using fractional blinks. Treats NaNs
% as lost data.
%
% Carolyn Ranti

function instBR = calcInstBR(fractBlinks, samplesPerMin)

instBR = samplesPerMin * nanmean(fractBlinks,1);



