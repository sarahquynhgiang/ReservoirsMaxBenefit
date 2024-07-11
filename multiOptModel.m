% runs optModel on a given object for a given number of test Qrs and stores
% results in a new matrix, which can be re-assigned back to the object

function [results] = multiOptModel(obj,nQr,qd_ts,saveFolder)
%% initialization

nQr = nQr+1;        % we want n runs excluding the max qd and including the Qr_d
testQr = linspace(max(obj.qd.Q70),obj.Qr_d,nQr);

results = cell(nQr-1,6);

%% run the loop
for i=2:nQr         % excludes the max qd

    [Qout,V,Vflood,Vrelease_f,Vrelease_f_c,Vstore,Vrelease_d,Vrelease_d_c,Vneed,modTS] = optModel(obj,testQr(i),qd_ts);
    modelOut = table(Qout,V,Vflood,Vrelease_f,Vrelease_f_c,Vstore,Vrelease_d,...
        Vrelease_d_c,Vneed,modTS,'VariableNames',{'Qout','V','Vflood','Vrelease_f'...
        'Vrelease_f_c','Vstore','Vrelease_d','Vrelease_d_c','Vneed','modTS'});

    [penalties, maintF, benD] = compPenalty(Qout,obj,qd_ts);
    freq = floodFreq(obj,testQr(i));

    results(i-1,1) = {testQr(i)};
    results(i-1,2) = {maintF};
    results(i-1,3) = {freq};
    results(i-1,4) = {benD};
    results(i-1,5) = {modelOut};
    results(i-1,6) = {penalties};

end

%% plot results of the highest-benefit run

modelTrue = results(find(contains(results(:,2),'true')),:);
benDrought = cell2mat(modelTrue(:,3));
idx = find(max(benDrought));

if isempty(idx)
    idx = 1;
    modelTrue = results(nQr-1,:);
end

plotVQP(obj,modelTrue{idx,5},modelTrue{idx,6},modelTrue{idx,1},qd_ts);

saveName = strcat(saveFolder,obj.hrbName,'_best.fig');
savefig(saveName);
close all

%% prep final results

final = cell(4,2);
final(1,1) = {'testQr-maintain-benD'};
final(1,2) = {results(:,1:4)};
final(2,1) = {'modelResults'};
final(2,2) = modelTrue(idx,5);
final(3,1) = {'modelPenalties'};
final(3,2) = modelTrue(idx,6);
final(4,1) = {'Qr_o'};
final(4,2) = modelTrue(idx,1);

results = final;

end
