function [throughput,meanDelay,trafficOffered,pcktCollisionProb] = saloha(sourceNumber,packetReadyProb,maxBackoff,simulationTime,showProgressBar,niceOutput)
% function [throughput,mean delay,traffic offered,packet collision probability]
%    = saloha(source number,packet ready probability, maximum backoff,simulation time,
%      show progress bar,nice output)
%
% +++ Function input parameters
%
% source number (positive integer): the number of sources that generate packets.
%
% packet ready probability (real, [0,1]): the probability that a given source has
%        a packet ready to be transmitted at any given time slot.
%
% maximum backoff (positive integer): the maximum backoff value that a backlogged
%        source must wait before a new transmission attempt.
%
% simulation time (positive integer): the duration of the simulation in time slots.
%
% show progress bar (optional): if true, a progress bar showing the simulation
%        advance will be displayed. Default behaviour is showProgressBar = false
%        for faster simulations.
%
% nice output (optional): if true, prints out the function outputs. Default
%        behaviour is niceOutput = false.
%
% +++ Function outputs
%
% throughput: normalized throughput of the slotted aloha random access protocol
%
% mean delay: the average delay (in slots) for a packet to be successfully
%        transmitted (acknowledge) from the moment it is ready at the source
%
% traffic offered: normalized traffic offered to the system,including
%        retransmissions
%
% packet collision probability: probability that a packet collides with others
%        at any given time slot

sourceStatus = zeros(1,sourceNumber);
% legit source statuses are always non-negative integers and equal to:
% 0: source has no packet ready to be transmitted (is idle)
% 1: source has a packet ready to be transmitted, either because new data must be sent or a previously collided packet has waited the backoff time
% >1: source is backlogged due to previous packets collision, the value of the status equals the number of slots it must wait for the next transmission attempt
sourceBackoff = zeros(1,sourceNumber);
pcktTransmissionAttempts = 0;
ackdPacketDelay = zeros(1,simulationTime);
ackdPacketCount = 0;
pcktCollisionCount = 0;
pcktGenerationTimestamp = zeros(1,sourceNumber);
currentSlot = 0;

if exist('showProgressBar','var') && showProgressBar == 1
    showProgressBar = 1;
    progressBar = waitbar(0,'Generating traffic...','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
    setappdata(progressBar,'canceling',0);
else
    showProgressBar = 0;
end

while currentSlot < simulationTime
    currentSlot = currentSlot + 1;

    if showProgressBar == 1
        if getappdata(progressBar,'canceling')
            delete(progressBar);
            fprintf('\nWarning: terminated by user!\n');
            break
        end
        waitbar(currentSlot / simulationTime,progressBar,sprintf('Packets sent: %u; packets acknowledged: %u.',pcktTransmissionAttempts,ackdPacketCount));
    end

    for eachSource1 = 1:length(sourceStatus)
        if sourceStatus(1,eachSource1) == 0 && rand(1) <= packetReadyProb % new packet
            sourceStatus(1,eachSource1) = 1;
            sourceBackoff(1,eachSource1) = randi(maxBackoff,1);
            pcktGenerationTimestamp(1,eachSource1)=currentSlot;
        elseif sourceStatus(1,eachSource1)==1 % backlogged packet
            sourceBackoff(1,eachSource1)=randi(maxBackoff,1);
        end
    end

    pcktTransmissionAttempts = pcktTransmissionAttempts + sum(sourceStatus == 1);

    if sum(sourceStatus == 1) == 1
        ackdPacketCount = ackdPacketCount + 1;
        [dummy,sourceId] = find(sourceStatus == 1);
        ackdPacketDelay(ackdPacketCount) = currentSlot - pcktGenerationTimestamp(sourceId);
    elseif sum(sourceStatus == 1) > 1
        pcktCollisionCount = pcktCollisionCount + 1;
        sourceStatus  = sourceStatus + sourceBackoff;
    end

    sourceStatus = sourceStatus - 1; % decrease backoff interval
    sourceStatus(sourceStatus < 0) = 0; % idle sources stay idle (see permitted statuses above)
    sourceBackoff = zeros(1,sourceNumber);
end

if currentSlot == simulationTime && showProgressBar == 1
    delete(progressBar);
end

trafficOffered = pcktTransmissionAttempts / currentSlot;
meanDelay = mean(ackdPacketDelay(1:ackdPacketCount));
throughput = ackdPacketCount / currentSlot;
pcktCollisionProb = pcktCollisionCount / currentSlot;

if exist('niceOutput','var') && niceOutput == 1
    fprintf('\nTraffic offered (G): %.3f,\nThroughput (S): %.3f,\nMean delay (D): %.2f slots,\nCollision probability (P_c): %.3f.\n',trafficOffered,throughput,meanDelay,pcktCollisionProb);
end