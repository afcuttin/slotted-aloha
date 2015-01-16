function [throughput,meanDelay,trafficOffered,pcktCollisionProb] = saloha(sourceNumber,packetReadyProb,maxBackoff,simulationTime,showProgressBar,niceOutput)
%
% write help here
%
% showProgressBar (optional): if true, a progress bar showing the
%        simulation advance will be displayed. Default behaviour is
%        showProgressBar = false for faster simulations.
%
% niceOutput (optional): if true, prints out the function outputs
%        Default behaviour is niceOutput = false.

sourceStatus = zeros(1,sourceNumber);
% legit source statuses are always non-negative integers and equal to:
% 0: source has no packet ready to be transmitted (is idle)
% 1: source has a packet ready to be transmitted, either because new data must be sent or a previously collided packet has waited the backoff time
% >1: source is backlogged due to previous packets collision, the value of the status equals the number of slots it must wait for the next transmission attempt
sourceBackoff = zeros(1,sourceNumber);
pcktTransmissionAttempts = 0;
ackdPacketDelay = [];
ackdPacketCount = 0;
pcktCollisionCount = 0; % this is not an output of the function. deletable?
currentSlot = 0;

if exist('showProgressBar','var') & showProgressBar == 1
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
            fprintf('Warning: terminated by user!\n');
            break
        end
        waitbar(currentSlot / simulationTime,progressBar,sprintf('Packets sent: %u; packets acknowledged: %u.',pcktTransmissionAttempts,ackdPacketCount));
    end

    for eachSource1 = 1:length(sourceStatus)
        if sourceStatus(1,eachSource1) == 0 & rand(1) <= packetReadyProb % new packet
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
        [dummy,sourceId] = find(sourceStatus == 1); % trova la posizione sourceId della sorgente che trasmette per poter determinare il ritardo dovuto alle collisioni
        ackdPacketDelay(ackdPacketCount) = currentSlot - pcktGenerationTimestamp(sourceId);
    elseif sum(sourceStatus == 1) > 1
        pcktCollisionCount = pcktCollisionCount + 1; % this is not an output of the function. deletable?
        sourceStatus  = sourceStatus + sourceBackoff;
    end

    for eachSource2 = 1:length(sourceStatus) % get rid of these for and if using vector operations
        if sourceStatus(1,eachSource2) > 0
            sourceStatus(1,eachSource2) = sourceStatus(1,eachSource2) - 1; % decrementa sourceStatus: chi ha trasmesso passa in idle, chi è backlogged riduce l'attesa fino a quando è di nuovo pronto
        end
    end

    sourceBackoff = zeros(1,sourceNumber); % inizializzazione del vettore di sourceBackoff prima del nuovo slot
end

if currentSlot==simulationTime & showProgressBar == 1
    delete(progressBar);
end

trafficOffered = pcktTransmissionAttempts / currentSlot;  % calcola il traffico in ingresso, ritrasmissioni incluse
meanDelay = mean(ackdPacketDelay);
throughput = ackdPacketCount / currentSlot;
pcktCollisionProb = pcktCollisionCount / currentSlot;

if exist('niceOutput','var') & niceOutput == 1
    fprintf('\nTraffic offered (G): %.3f,\nThroughput (S): %.3f,\nMean delay (D): %.2f slots,\nCollision probability (P_c): %.3f.\n',trafficOffered,throughput,meanDelay,pcktCollisionProb);
end