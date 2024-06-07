function [xr]=msm_DFT_filtering_ecg(x,Fs)

y=x-mean(x);

L=length(y);

NFFT = 2^nextpow2(L); % Next power of 2 from length of y
Y = fft(y,NFFT);
%---------------------------------------
kf1=ceil((NFFT*60/Fs)); % for power-line frequency 

kfb=ceil((NFFT*1/Fs)); % for Base-line wander noise 
DLb=2; % Threshold for baseline
DL=10; % Threshold for power-line
 
Y1=Y;

Y1(kf1-DL:kf1+DL)=0*Y1(kf1-DL:kf1+DL);
% Symmetry coeff are also made equal to zero
Y1(NFFT-kf1-DL:NFFT-kf1+DL)=0*Y1(NFFT-kf1-DL:NFFT-kf1+DL);

Y1(1:kfb+DLb)=0*Y1(1:kfb+DLb);
% Due to symmetry, the last coeff are made equal to zero
Y1(end:-1:end-(kfb+DLb))=0*Y1(end:-1:end-(kfb+DLb));

xr1=ifft(Y1,NFFT);

xr=real(xr1);

%  err=Y-xr;
%  t=0:1/Fs:(max_lenEEG-1)/Fs';
% figure;subplot(311);plot(y);
% axis tight;grid on;
% subplot(312);plot(xr);axis tight;grid on;
% subplot(313);plot(abs(err));axis tight;grid on;
