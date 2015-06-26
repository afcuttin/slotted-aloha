function [capturedSource] =  packetCapture(sourceStatus,sourcePower,sourceRho,captureThreshold)
% function [capturedSource] =  capture(sourceStatus,sourcePower,sourceRho,captureThreshold)
% Evaluates the capture effect for colliding packets in an Aloha-like environment.
%
% Returns 0 if no capture occurs.
% If capture occurs, returns the index of sourceStatus corresponding to the source whose packet has been captured

if numel(find(sourceStatus == 1)) == 1
	capturedSource = find(sourceStatus == 1)
	fprintf('Warning: there are no collisions!\nNevertheless, I provide you with the right answer without computing the capture ratio.\n')
elseif numel(find(sourceStatus == 1)) > 1
	collided = find(sourceStatus == 1)
	receivedPower = sourcePower(collided)./(1+sourceRho(collided).^2)
	captured = collided(find(receivedPower == max(receivedPower)))
	interfering = setdiff(collided,captured)
	captureRatio = sum(receivedPower.*ismember(collided,captured)) / sum(receivedPower.*not(ismember(collided,captured)))
	captureRatiodB = 10 * log10(captureRatio)
	if captureRatiodB >= captureThreshold
		capturedSource = captured;
	elseif captureRatiodB < captureThreshold
		capturedSource = 0;
	end
end

