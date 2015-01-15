function [throughput,meanDelay,trafficOffered] = saloha(sourcesNumber,txProbability,maxBackoff,simulationTime,showProgressBar)
% clear all

% sourcesNumber=100; % numero di sorgenti

% maxBackoff=100; % intervallo massimo di backoff in slots
% txProbability=0.005; % parametro per l'esperimento casuale che decide se una sorgente trasmette o meno

source=zeros(1,sourcesNumber); % inizializzazione sorgenti: all'inizio sono tutte vuote
backoff=zeros(1,sourcesNumber); % inizializzazione vettore intervalli backoff

attempt=0; % contatore dei tentativi di trasmissione (sorgente con pacchetto pronto a un certo istante)
acknowledge=0; % contatore dei pacchetti confermati
collision=0; % contatore delle collisioni
delays=[]; % vettore dei ritardi

% simulationTime = 10000; % durata simulazione, in slot
now = 0; % istante corrente

h = waitbar(0,'Generating traffic...','CreateCancelBtn','setappdata(gcbf,''canceling'',1)'); % finestra con barra di avanzamento

setappdata(h,'canceling',0)

while now<simulationTime

    if getappdata(h,'canceling')
        delete(h);
        fprintf('Warning: terminated by user!\n');
        break
    end

    waitbar(now / simulationTime,h,sprintf('Packets sent: %u; packests acknowledged: %u.',attempt,acknowledge));
    
    for i=1:length(source)
        if source(1,i)==0 & rand(1)<=txProbability % esperimento casuale: se la sorgente è idle e se vero, la sorgente trasmette
            source(1,i)=1; % sorgente pronta a trasmttere
            backoff(1,i)=randi(maxBackoff,1); % genera eventuale intervallo di backoff in caso di collisione
            generated(1,i)=now; % prendi nota di quando il pacchetto era pronto per calcolare il ritardo
        elseif source(1,i)==1 % era backlogged e ha aspettato il suo turno (non si può integrare nella condizione precedente, perché altrimenti si perde l'informazione sul ritardo (a generated(,i) viene assegnato un nuovo valore)
            backoff(1,i)=randi(maxBackoff,1); % genera eventuale intervallo di backoff in caso di collisione
        end
    end
    
%    disp('nuove trasmissioni')
%    source
%    backoff
    
    attempt=attempt+sum(source==1);
    
    if sum(source==1)==1 % non c'è collisione
        acknowledge=acknowledge+1; % il pacchetto è trasmesso e riceve acknowledge
        [a,b]=find(source==1); % trova la posizione b della sorgente che trasmette per poter determinare il ritardo dovuto alle collisioni
        delays(acknowledge)=now-generated(b); % calcola il ritardo e lo mette in un vettore man mano che i pacchetti vengono confermati
%        fprintf('Acknowledge: %u \n',acknowledge);    
    elseif sum(source==1)>1 % c'è collisione
        collision=collision+1;
        source=source+backoff;
%        fprintf('Collisioni: %u \n',collision);    
    end
    
    for j=1:length(source)
        if source(1,j)>0
            source(1,j)=source(1,j)-1; % decrementa source: chi ha trasmesso passa in idle, chi è backlogged riduce l'attesa fino a quando è di nuovo pronto
        end
    end
    
%    source
%    pause('on');
%    pause;
    now=now+1; % avanza di uno slot
    backoff=zeros(1,sourcesNumber); % inizializzazione del vettore di backoff prima del nuovo slot
end

if now==simulationTime
    delete(h);
end

trafficOffered=attempt/now;  % calcola il traffico in ingresso, ritrasmissioni incluse
meanDelay=mean(delays); % calcola il ritardo medio in slots
throughput=acknowledge/now;
% fprintf('Mean delay (D): %.2f slots,\nTraffic offered (G): %.3f,\nThroughput (S): %.3f\n',D,G,S);
