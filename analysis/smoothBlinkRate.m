% INITIAL DRAFT DONE - 11.24.2014


function smoothedBlinkData = smoothBlinkRate(fractBlinks, samplesPerMin, Y)

instBR = calcInstBR(fractBlinks, samplesPerMin); % blink rate in blinks/min
smoothedBlinkData = conv2_mirrored(instBR, Y);