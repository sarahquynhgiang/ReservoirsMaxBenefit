%% apply methods to all reservoirs in allReservoirs object array

load allStudyReservoirs.mat;
saveFolder = 'C:\Users\ho\Documents\Data\Images\OptimizationModel\ReservoirPlots\';

for i=1:size(allReservoirs,1)

    close all;

    obj = allReservoirs{i,1};

    % apply area ratio to LARSIM Qin
    obj.qin.Q = obj.qin_d.Q*area_ratio(i,1);

    obj = calcMinFlow(obj);
    saveName = strcat(saveFolder,obj.hrbName,'_minFlow.fig');
    savefig(saveName);

    obj = floodOptModel(obj,obj.qd_ts.Q70);
    saveName = strcat(saveFolder,obj.hrbName,'_floodOpt.fig');
    savefig(saveName);

    obj.results = multiOptModel(obj,50,obj.qd_ts.Q70,saveFolder);

    obj = calcBaseStats(obj);

    obj = penaltyRidgePlot(obj);
    saveName = strcat(saveFolder,obj.hrbName,'_penaltyRidgePlot.fig');
    savefig(saveName);

    allReservoirs{i,1} = obj;

end
