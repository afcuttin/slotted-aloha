clear all
% the following values return a throughput very close to the theoretical maximum
% sources number = 100
% maximum backoff = 100
% packet ready probability  = 0.0057
% simulation time = 5000
saloha(100,0.0057,100,5000,true,true);