clc;
clear all;
close all;
%% file directory
files = dir('H:\backup\arka\DISEASE_WORK\King_Aubdullah\COPD');
%% segment
All_COPD_sigs=[]; i=1;
for p=3:36
    disp(['Iteration==>' num2str(p-2)]);
    file = files(p).name;
    [data,fs]=audioread(file);
    t=0:1/fs:(length(data)-1)/fs';
    fixed_win=20000;
    sliding_win=10000;
    size_of_ip = size(data);
    c=1;
    while 1
    seg_s=n_data(c:c+fixed_win-1);
    bw_removed=msm_DFT_filtering_ecg(seg_s,fs);
    bwr_s=bw_removed(1:length(seg_s));
    norm_s=bwr_s/max(abs(bwr_s));
    All_COPD_sigs(:,i)=norm_s;
    c=c+sliding_win;
    i=i+1;
    if(c+fixed_win-1>size_of_ip)
        break;
    end
    end
end
