%% resultPlotting
% the first section is (less-than-optimal) setup for all of the plotting
% for figures 4-14, which are plotted by the later sections of this code.
%
% This code also uses hatchfill2 v3.0.0.0 by Kesh Ikuma, which can be
% downloaded here:
% https://matlab.mathworks.com/open/fileexchange/v1?id=53593



%% data setup

load allStudyReservoirs.mat

% collect and rearrange baseStats

names = cell(30,1);

nat_f_ts = zeros(30,1);
nat_d_ts = nat_f_ts;
hwo_f_ts = nat_f_ts;    % Hochwasser only
hwo_d_ts = nat_f_ts;
hnw_f_ts = nat_f_ts;    % Hoch- Niedrigwasser
hnw_d_ts = nat_f_ts;

nat_f_vol = nat_f_ts;
nat_d_vol = nat_f_ts;
hwo_f_vol = nat_f_ts;
hwo_d_vol = nat_f_ts;
hnw_f_vol = nat_f_ts;
hnw_d_vol = nat_f_ts;

nat_f_pen = nat_f_ts;
nat_d_pen = nat_f_ts;
hwo_f_pen = nat_f_ts;
hwo_d_pen = nat_f_ts;
hnw_f_pen = nat_f_ts;
hnw_d_pen = nat_f_ts;

nat_useStats = zeros(30,6);
hwo_useStats = nat_useStats;
hnw_useStats = nat_useStats;

rel_f_vol = zeros(30,1);
sav_f_vol = rel_f_vol;
rel_d_vol = rel_f_vol;
sav_d_vol = rel_f_vol;

res_vol = rel_f_vol;
rf = rel_f_vol;     % actual RF
rf_e = rel_f_vol;   % estimated RF
qcrit = rf;
qd_max = rf;
qd_min = rf;
qr = rf;
c = rf;

y = zeros(30,1);
neg = y;
pos = y;

for i=1:30

    % allReservoirs{i,1}.results = multiOptModel(allReservoirs{i,1},50);
    allReservoirs{i,1} = calcBaseStats(allReservoirs{i,1});
    baseStats = table2array(allReservoirs{i,1}.baseStats);

    idx = i;

    names(idx) = {allReservoirs{i,1}.hrbName};

    res_vol(idx) = allReservoirs{i,1}.Vv-allReservoirs{i,1}.Vd;

    allReservoirs{i,1} = calcRF(allReservoirs{i,1});

    rf(i) = allReservoirs{i,1}.rf;

    qcrit(i) = allReservoirs{i,1}.Qr_d;
    qd_max(i) = max(allReservoirs{i,1}.qd.Q70);
    qd_min(i) = min(allReservoirs{i,1}.qd.Q70);
    qr(i) = allReservoirs{i,1}.results{4,2};
    c(i) = allReservoirs{i,1}.Vv - allReservoirs{i,1}.Vd;

    % error bar plotting
    y(i) = allReservoirs{i,1}.results{4,2};
    neg(i) = y(i)-max(allReservoirs{i,1}.qd.Q70);
    pos(i) = allReservoirs{i,1}.Qr_d - y(i);

    nat_f_ts(idx) = baseStats(1,1);
    nat_d_ts(idx) = baseStats(2,1);
    hwo_f_ts(idx) = baseStats(3,1);
    hwo_d_ts(idx) = baseStats(4,1);
    hnw_f_ts(idx) = baseStats(5,1);
    hnw_d_ts(idx) = baseStats(6,1);

    nat_f_vol(idx) = baseStats(1,2);
    nat_d_vol(idx) = baseStats(2,2);
    hwo_f_vol(idx) = baseStats(3,2);
    hwo_d_vol(idx) = baseStats(4,2);
    hnw_f_vol(idx) = baseStats(5,2);
    hnw_d_vol(idx) = baseStats(6,2);
    
    nat_f_pen(idx) = baseStats(1,3);
    nat_d_pen(idx) = baseStats(2,3);
    hwo_f_pen(idx) = baseStats(3,3);
    hwo_d_pen(idx) = baseStats(4,3);
    hnw_f_pen(idx) = baseStats(5,3);
    hnw_d_pen(idx) = baseStats(6,3);

    sav_f_vol(idx) = baseStats(5,7);
    rel_f_vol(idx) = baseStats(5,8);
    sav_d_vol(idx) = baseStats(6,7);
    rel_d_vol(idx) = baseStats(6,8);

    % flood first, then drought stats
    nat_useStats(idx,1:3) = baseStats(1,4:6);
    hwo_useStats(idx,1:3) = baseStats(3,4:6);
    hnw_useStats(idx,1:3) = baseStats(5,4:6);
    nat_useStats(idx,4:6) = baseStats(2,4:6);
    hwo_useStats(idx,4:6) = baseStats(4,4:6);
    hnw_useStats(idx,4:6) = baseStats(6,4:6);
end

sz = allReservoirs(:,4);
sz = strrep(sz,'gross','Large');
sz = strrep(sz,'mittel','Mid-size');
sz = strrep(sz,'klein','Small');
use = allReservoirs(:,6);
use = strrep(use,'HWX','Multipurpose');
use = strrep(use,'HW','Flood-only');
dam = allReservoirs(:,7);
dam = strrep(dam,'ja','Permanent');
dam = strrep(dam,'nein','Operational');
sz = categorical(sz);
use = categorical(use);

% sort different tables by categories
    % ts = # timesteps
    % vol = vol deficit / flood spill
    % pen = penalty
    % d = drought
    % f = flood
    % rel_vol = volume released for drought / flood protection (i.e.
    % pre-emptying)
    % sav_vol = volume saved for drought / flood retention volume

ts_f = table([nat_f_ts,hwo_f_ts,hnw_f_ts],'VariableNames',{'ts_f'},'RowNames',allReservoirs(:,2));
ts_d =  table([nat_d_ts,hwo_d_ts,hnw_d_ts],'VariableNames',{'ts_d'},'RowNames',allReservoirs(:,2));
vol_f = table([nat_f_vol,hwo_f_vol,hnw_f_vol],'VariableNames',{'vol_f'},'RowNames',allReservoirs(:,2));
vol_d = table([nat_d_vol,hwo_d_vol,hnw_d_vol],'VariableNames',{'vol_d'},'RowNames',allReservoirs(:,2));
pen_f = table([nat_f_pen,hwo_f_pen,hnw_f_pen],'VariableNames',{'pen_f'},'RowNames',allReservoirs(:,2));
pen_d = table([nat_d_pen,hwo_d_pen,hnw_d_pen],'VariableNames',{'pen_d'},'RowNames',allReservoirs(:,2));
rel_vol = table([rel_f_vol,rel_d_vol],'VariableNames',{'rel_vol'});
sav_vol = table([sav_f_vol,sav_d_vol],'VariableNames',{'sav_vol'});

ben_d = 100*(hwo_d_pen-hnw_d_pen)./hwo_d_pen;       % penalty benefit
nor_rel_vol_d = rel_d_vol./res_vol;                 % normalized drought release volume
vol_ben_d = 100*(hwo_d_vol-hnw_d_vol)./hwo_d_vol;   % volume benefit

mainTbl = table(sz,use,dam,rf,ben_d,nor_rel_vol_d,vol_ben_d,qd_max,qd_min,...
    qr,'VariableNames',...
    {'Size','Use','Inundation','Availability_Factor','Drought_Benefit','Normalized_Release_Volume',...
    'Volume_Benefit','MaxQ70','MinQ70','Qr'},'RowNames',allReservoirs(:,2));
mainTbl = [mainTbl,ts_f,ts_d,vol_f,vol_d,pen_f,pen_d,rel_vol];

clear nat_f_ts hwo_f_ts hnw_f_ts nat_d_ts hwo_d_ts hnw_d_ts nat_f_vol hwo_f_vol hnw_f_vol ...
    nat_d_vol hwo_d_vol hnw_d_vol nat_f_pen hwo_f_pen hnw_f_pen nat_d_pen hwo_d_pen hnw_d_pen ...
    rel_f_vol rel_d_vol sav_f_vol sav_d_vol

%%

mainTbl = sortrows(mainTbl,'RowNames');
mainTbl = sortrows(mainTbl,{'Size','Use','Inundation'});
names = mainTbl.Row(1:30);

% pull indices for different sub-groups
[gross,~]   = find(mainTbl.Size=='Large');
[mittel,~]  = find(mainTbl.Size=='Mid-size');
[klein,~]   = find(mainTbl.Size=='Small');

[hw,~]  = find(mainTbl.Use=='Flood-only');
[hwx,~] = find(mainTbl.Use=='Multipurpose');

[gross_hw,~]    = intersect(gross,hw);
[gross_hwx,~]   = intersect(gross,hwx);

[mittel_hw,~]   = intersect(mittel,hw);
[mittel_hwx,~]  = intersect(mittel,hwx);

[klein_hw,~]   = intersect(klein,hw);
[klein_hwx,~]    = intersect(klein,hwx);

% hold color values for plotting
colors = zeros(3,3);
colors(1,:) = [0.6350 0.0780 0.1840];
colors(2,:) = [0.9290 0.6940 0.1250];
colors(3,:) = [0 0.4470 0.7410];


%% Figure 4

figure
t = tiledlayout(1,3);
t.TileSpacing = 'compact';

nexttile([1 2]);
hold on
scatter(mainTbl.Availability_Factor(gross_hw),mainTbl.Drought_Benefit(gross_hw),[],colors(1,:),'filled',"^");
scatter(mainTbl.Availability_Factor(gross_hwx),mainTbl.Drought_Benefit(gross_hwx),[],colors(1,:),'filled',"square");
scatter(mainTbl.Availability_Factor(mittel_hw),mainTbl.Drought_Benefit(mittel_hw),[],colors(2,:),'filled',"^");
scatter(mainTbl.Availability_Factor(mittel_hwx),mainTbl.Drought_Benefit(mittel_hwx),[],colors(2,:),'filled',"square");
scatter(mainTbl.Availability_Factor(klein_hw),mainTbl.Drought_Benefit(klein_hw),[],colors(3,:),'filled',"^");
scatter(mainTbl.Availability_Factor(klein_hwx),mainTbl.Drought_Benefit(klein_hwx),[],colors(3,:),'filled',"square");
text(mainTbl.Availability_Factor+3,mainTbl.Drought_Benefit,names);
xlabel('Availability Factor [-]');
ylabel('Penalty Benefit [%]');
ylim([0 100]);
%title('Water Availability');
lgd = legend({'Large, flood-only';'Large, multipurpose';'Mid-size, flood-only';'Mid-size, multipurpose';...
    'Small, flood-only';'Small, multipurpose'});
lgd.Location = 'northoutside';
lgd.NumColumns = 3;

nexttile;
boxchart(mainTbl.Size,mainTbl.Drought_Benefit,'GroupByColor',mainTbl.Use)
lgd = legend;
lgd.Location = 'northoutside';
lgd.Orientation = 'horizontal';
ylabel('% Penalty Benefit');
ylim([0 100]);

%% Figure 10
% plot flood base stats (time, volume, penalty) by categories (horizontal)
fig = figure;
t = tiledlayout(3,3);
t.TileSpacing = 'tight';

t(1) = nexttile([2 1]);
hold on
ylim([0.5 30.5]);
patch([1 1 10^5 10^5],[0.5 4.5 4.5 0],'r','FaceColor','#fcd1cf');
A = patch([1 1 10^5 10^5],[4.5 8.5 8.5 4.5],'r','FaceColor','#fcd1cf');
patch([1 1 10^5 10^5],[8.5 15.5 15.5 8.5],'r','FaceColor','#fbfccf');
B = patch([1 1 10^5 10^5],[15.5 23.5 23.5 15.5],'r','FaceColor','#fbfccf');
patch([1 1 10^5 10^5],[23.5 27.5 27.5 23.5],'r','FaceColor','#cff7fc');
C = patch([1 1 10^5 10^5],[27.5 30.5 30.5 27.5],'r','FaceColor','#cff7fc');
barh(mainTbl.ts_f)
hatchfill2(A);
hatchfill2(B);
hatchfill2(C);
yticks(1:30)
yticklabels(names);
xticks([1 10 100 1000 10000 100000])
xscale('log');
set(gca,'YDir','reverse');
title('log(# Flood Hours)')

t(3) = nexttile([2 1]);
hold on
ylim([0.5 30.5]);
patch([1 1 10^5 10^5],[0.5 4.5 4.5 0],'r','FaceColor','#fcd1cf');
A = patch([1 1 10^5 10^5],[4.5 8.5 8.5 4.5],'r','FaceColor','#fcd1cf');
patch([1 1 10^5 10^5],[8.5 15.5 15.5 8.5],'r','FaceColor','#fbfccf');
B = patch([1 1 10^5 10^5],[15.5 23.5 23.5 15.5],'r','FaceColor','#fbfccf');
patch([1 1 10^5 10^5],[23.5 27.5 27.5 23.5],'r','FaceColor','#cff7fc');
C = patch([1 1 10^5 10^5],[27.5 30.5 30.5 27.5],'r','FaceColor','#cff7fc');
barh(mainTbl.vol_f,1)
hatchfill2(A);
hatchfill2(B);
hatchfill2(C);
yticks(1:30);
yticklabels([]);
xticks([1 10 100 1000 10000 100000])
xscale('log');
xlim([1 10^5])
title('log(Total Flood Volume [1000 m^3])')
set(gca,'YDir','reverse');
tL = legend({'Large Reservoirs','','','Medium Reservoirs','','','Small Reservoirs','','Multipurpose'...
    'Semi-natural','Flood Operation','Combined Operation'});
tL.NumColumns = 4;
tL.Location = 'northoutside';

t(5) = nexttile([2 1]);
hold on
ylim([0.5 30.5]);
patch([1 1 10^5 10^5],[0.5 4.5 4.5 0],'r','FaceColor','#fcd1cf');
A = patch([1 1 10^5 10^5],[4.5 8.5 8.5 4.5],'r','FaceColor','#fcd1cf');
patch([1 1 10^5 10^5],[8.5 15.5 15.5 8.5],'r','FaceColor','#fbfccf');
B = patch([1 1 10^5 10^5],[15.5 23.5 23.5 15.5],'r','FaceColor','#fbfccf');
patch([1 1 10^5 10^5],[23.5 27.5 27.5 23.5],'r','FaceColor','#cff7fc');
C = patch([1 1 10^5 10^5],[27.5 30.5 30.5 27.5],'r','FaceColor','#cff7fc');
barh(-mainTbl.pen_f,1)
hatchfill2(A);
hatchfill2(B);
hatchfill2(C);
yticks(1:30);
yticklabels([]);
xticks([1 10 100 1000 10000 100000])
xscale('log');
xlim([1 10^5]);
title('log(Total Flood Penalty)')
set(gca,'YDir','reverse');

t1 = nexttile;
lims = [0, max(mainTbl.ts_f(:,2))+0.2*max(mainTbl.ts_f(:,2))];
scatter(mainTbl.ts_f(:,2),mainTbl.ts_f(:,3),[],"+");
hold on;
line(lims(1):lims(2),lims(1):lims(2));
legend({'Reservoirs';'1:1 Line'})
xlabel('Flood Operation Model');
ylabel('Combined Operation Model');
xlim(lims);
ylim(lims);
title('Time under Floods [hrs]');

t1 = nexttile;
lims = [0, max(mainTbl.vol_f(:,2))+0.2*max(mainTbl.vol_f(:,2))];
scatter(mainTbl.vol_f(:,2),mainTbl.vol_f(:,3),[],"+");
hold on;
line(lims(1):lims(2),lims(1):lims(2));
xlabel('Flood Operation Model');
% ylabel('Combined Operation Model');
xlim(lims);
ylim(lims);
title('Flooding Volume [1000 m3]');

t1 = nexttile;
lims = [min(mainTbl.pen_f(:,2))+0.2*max(mainTbl.pen_f(:,2)),0];
scatter(mainTbl.pen_f(:,2),mainTbl.pen_f(:,3),[],"+");
hold on;
line(lims(1):lims(2),lims(1):lims(2));
xlabel('Flood Operation Model');
% ylabel('Combined Operation Model');
set(gca,'Ydir','reverse')
set(gca,'Xdir','reverse')
xlim(lims);
ylim(lims);
title('Flood Penalty');


%% Figure 11
% plot drought base stats (time, volume, penalty) by categories (horizontal)

figure;
t = tiledlayout(3,3);
t.TileSpacing = 'tight';

t(2) = nexttile([2 1]);
hold on
ylim([0.5 30.5]);
patch([1 1 7*10^4 7*10^4],[0.5 4.5 4.5 0],'r','FaceColor','#fcd1cf');
A = patch([1 1 7*10^4 7*10^4],[4.5 8.5 8.5 4.5],'r','FaceColor','#fcd1cf');
patch([1 1 7*10^4 7*10^4],[8.5 15.5 15.5 8.5],'r','FaceColor','#fbfccf');
B = patch([1 1 7*10^4 7*10^4],[15.5 23.5 23.5 15.5],'r','FaceColor','#fbfccf');
patch([1 1 7*10^4 7*10^4],[23.5 27.5 27.5 23.5],'r','FaceColor','#cff7fc');
C = patch([1 1 7*10^4 7*10^4],[27.5 30.5 30.5 27.5],'r','FaceColor','#cff7fc');
barh(mainTbl.ts_d,1)
hatchfill2(A);
hatchfill2(B);
hatchfill2(C);
xlim([1 7*10^4])
yticks(1:30);
yticklabels(names);
set(gca,'YDir','reverse');
title('# Drought Hours')
tL = legend({'Large Reservoirs','','','Medium Reservoirs','','','Small Reservoirs','','Multipurpose',...
    'Semi-natural','Flood Operation','Combined Operation'});
tL.NumColumns = 4;
tL.Layout.Tile = 'north';

t(4) = nexttile([2 1]);
hold on
ylim([0.5 30.5]);
patch([1 1 10^6 10^6],[0.5 4.5 4.5 0],'r','FaceColor','#fcd1cf');
A = patch([1 1 10^6 10^6],[4.5 8.5 8.5 4.5],'r','FaceColor','#fcd1cf');
patch([1 1 10^6 10^6],[8.5 15.5 15.5 8.5],'r','FaceColor','#fbfccf');
B = patch([1 1 10^6 10^6],[15.5 23.5 23.5 15.5],'r','FaceColor','#fbfccf');
patch([1 1 10^6 10^6],[23.5 27.5 27.5 23.5],'r','FaceColor','#cff7fc');
C = patch([1 1 10^6 10^6],[27.5 30.5 30.5 27.5],'r','FaceColor','#cff7fc');
barh(mainTbl.vol_d,1)
xscale('log');
hatchfill2(A);
hatchfill2(B);
hatchfill2(C);
yticks(1:30);
yticklabels([]);
xlim([1 10^6]);
xticks([1 10 100 1000 10^4 10^5 10^6])
set(gca,'YDir','reverse');
title('Deficit Volume [1000 m^3]')

t(6) = nexttile([2 1]);
hold on
ylim([0.5 30.5]);
patch([1000 1000 10^7 10^7],[0.5 4.5 4.5 0],'r','FaceColor','#fcd1cf');
A = patch([1000 1000 10^7 10^7],[4.5 8.5 8.5 4.5],'r','FaceColor','#fcd1cf');
patch([1000 1000 10^7 10^7],[8.5 15.5 15.5 8.5],'r','FaceColor','#fbfccf');
B = patch([1000 1000 10^7 10^7],[15.5 23.5 23.5 15.5],'r','FaceColor','#fbfccf');
patch([1000 1000 10^7 10^7],[23.5 27.5 27.5 23.5],'r','FaceColor','#cff7fc');
C = patch([1000 1000 10^7 10^7],[27.5 30.5 30.5 27.5],'r','FaceColor','#cff7fc');
barh(-mainTbl.pen_d,1)
xscale('log');
hatchfill2(A);
hatchfill2(B);
hatchfill2(C);
yticks(1:30);
yticklabels([]);
xlim([1000 10^7])
xticks([1000 10^4 10^5 10^6 10^7])
set(gca,'YDir','reverse');
title('Total Penalty')

t1 = nexttile;
lims = [0, max(mainTbl.ts_d(:,2))+0.2*max(mainTbl.ts_d(:,2))];
scatter(mainTbl.ts_d(:,2),mainTbl.ts_d(:,3),[],"+");
hold on;
line(lims(1):lims(2),lims(1):lims(2));
legend({'Reservoirs';'1:1 Line'})
xlabel('Flood Operation Model');
ylabel('Combined Operation Model');
xlim(lims);
ylim(lims);
title('Time under Drought [hrs]');

t1 = nexttile;
lims = [0, max(mainTbl.vol_d(:,2))+0.2*max(mainTbl.vol_d(:,2))];
scatter(mainTbl.vol_d(:,2),mainTbl.vol_d(:,3),[],"+");
hold on;
line(lims(1):lims(2),lims(1):lims(2));
xlabel('Flood Operation Model');
% ylabel('Combined Operation Model');
xlim(lims);
ylim(lims);
title('Deficit Volume [1000 m^3]');

t1 = nexttile;
lims = [min(mainTbl.pen_d(:,2))+0.2*max(mainTbl.pen_d(:,2)),0];
scatter(mainTbl.pen_d(:,2),mainTbl.pen_d(:,3),[],"+");
hold on;
line(lims(1):lims(2),lims(1):lims(2));
xlabel('Flood Operation Model');
% ylabel('Combined Operation Model');
set(gca,'Ydir','reverse')
set(gca,'Xdir','reverse')
xlim(lims);
ylim(lims);
title('Drought Penalty');

%% Figure 12
% plot volume and penalty benefits

figure;
t = tiledlayout(2,2);
t.TileSpacing = 'tight';

t(2) = nexttile([1 2]);
hold on
ylim([0.5 30.5]);
patch([0.5 4.5 4.5 0],[0 0 100 100],'r','FaceColor','#fcd1cf');
A = patch([4.5 8.5 8.5 4.5],[0 0 100 100],'r','FaceColor','#fcd1cf');
patch([8.5 15.5 15.5 8.5],[0 0 100 100],'r','FaceColor','#fbfccf');
B = patch([15.5 23.5 23.5 15.5],[0 0 100 100],'r','FaceColor','#fbfccf');
patch([23.5 27.5 27.5 23.5],[0 0 100 100],'r','FaceColor','#cff7fc');
C = patch([27.5 30.5 30.5 27.5],[0 0 100 100],'r','FaceColor','#cff7fc');
a = bar([mainTbl.Volume_Benefit,mainTbl.Drought_Benefit]);
hatchfill2(A);
hatchfill2(B);
hatchfill2(C);
xticks(1:30);
xticklabels(names);
xlim([0.5 30.5])
ylim([0 100]);
title('Drought Benefit [%]')
tL = legend({'Large Reservoirs','','','Medium Reservoirs','','','Small Reservoirs','','Multipurpose',...
    'Volume Benefit','Penalty Benefit'});
tL.NumColumns = 4;
tL.Location = 'northoutside';

t(3) = nexttile;
hold on
scatter(mainTbl.Volume_Benefit(gross_hw),mainTbl.Drought_Benefit(gross_hw),[],colors(1,:),'filled',"^");
scatter(mainTbl.Volume_Benefit(gross_hwx),mainTbl.Drought_Benefit(gross_hwx),[],colors(1,:),'filled',"square");
scatter(mainTbl.Volume_Benefit(mittel_hw),mainTbl.Drought_Benefit(mittel_hw),[],colors(2,:),'filled',"^");
scatter(mainTbl.Volume_Benefit(mittel_hwx),mainTbl.Drought_Benefit(mittel_hwx),[],colors(2,:),'filled',"square");
scatter(mainTbl.Volume_Benefit(klein_hw),mainTbl.Drought_Benefit(klein_hw),[],colors(3,:),'filled',"^");
scatter(mainTbl.Volume_Benefit(klein_hwx),mainTbl.Drought_Benefit(klein_hwx),[],colors(3,:),'filled',"square");
line(0:100,0:100);
xlabel('Volume Benefit [%]');
ylabel('Penalty Benefit [%]');
ylim([0 100]);
xlim([0 100]);
%title('Water Availability');
tl = legend({'Large, flood-only';'Large, multipurpose';'Mid-size, flood-only';'Mid-size, multipurpose';...
    'Small, flood-only';'Small, multipurpose'});
tl.Layout.Tile = 4;

%% Figure 13
% release volumes

% make a temporary table with only the release volumes
rel_vol = mainTbl.rel_vol;
rel_vol(rel_vol==0) = nan;      % avoids errors in log plotting
ymin = floor(log10(min(rel_vol,[],'all')));        % lower y limit for plotting
rel_vol = array2table(rel_vol,'VariableNames',{'Flood_Release',...
    'Drought_Release'});
rel_vol = addvars(rel_vol,mainTbl.Size,mainTbl.Use,'NewVariableNames',{'Size','Use'});
temp = rel_vol;
temp.Use(:) = 'All';
temp.Size(:) = 'All';
rel_vol = [rel_vol;temp];

figure
t = tiledlayout(1,4);

nexttile([1 2])
hold on;
patch([0 4.5 4.5 0],[0.01 0.01 5.5*10^5 5.5*10^5],'r','FaceColor','#fcd1cf');
A = patch([4.5 8.5 8.5 4.5],[0.01 0.01 5.5*10^5 5.5*10^5],'r','FaceColor','#fcd1cf');
patch([8.5 15.5 15.5 8.5],[0.01 0.01 5.5*10^5 5.5*10^5],'r','FaceColor','#fbfccf');
B = patch([15.5 23.5 23.5 15.5],[0.01 0.01 5.5*10^5 5.5*10^5],'r','FaceColor','#fbfccf');
patch([23.5 27.5 27.5 23.5],[0.01 0.01 5.5*10^5 5.5*10^5],'r','FaceColor','#cff7fc');
C = patch([27.5 30.5 30.5 27.5],[0.01 0.01 5.5*10^5 5.5*10^5],'r','FaceColor','#cff7fc');
bar(mainTbl.rel_vol);
hatchfill2(A);
hatchfill2(B);
hatchfill2(C);
%set(gca,'YDir','reverse');
xlim([0 30.5]);
xticks(1:30);
xticklabels(names);
ylim([0.01 5.5*10^5])
yscale('log');
ylabel('Volume [1000 m^3]');
tL = legend({'Large Reservoirs','','','Medium Reservoirs','','','Small Reservoirs','','Multipurpose'...
    'Flood Pre-Release','Drought Release'});
tL.NumColumns = 4;
tL.Location = 'northoutside';

nexttile;
boxchart(rel_vol.Size,rel_vol.Drought_Release,'GroupByColor',rel_vol.Use);
yscale('log');
ylim([0.01 5.5*10^5])
title('Drought Release')

nexttile;
boxchart(rel_vol.Size,rel_vol.Flood_Release,'GroupByColor',rel_vol.Use);
yscale('log');
ylim([0.01 5.5*10^5])
tL = legend;
tL.NumColumns = 3;
tL.Location = 'northoutside';
title('Flood Pre-Release')

%% figure 14

px2 = [0 225];

figure
t = tiledlayout(1,2);
t.TileSpacing = 'compact';

nexttile;
hold on;
scatter(mainTbl.Availability_Factor(gross_hw),  mainTbl.Normalized_Release_Volume(gross_hw),  [],colors(1,:),'filled',"^");
scatter(mainTbl.Availability_Factor(gross_hwx), mainTbl.Normalized_Release_Volume(gross_hwx), 50,colors(1,:),'filled',"square");
scatter(mainTbl.Availability_Factor(mittel_hw), mainTbl.Normalized_Release_Volume(mittel_hw), [],colors(2,:),'filled',"^");
scatter(mainTbl.Availability_Factor(mittel_hwx),mainTbl.Normalized_Release_Volume(mittel_hwx),50,colors(2,:),'filled',"square");
scatter(mainTbl.Availability_Factor(klein_hw),  mainTbl.Normalized_Release_Volume(klein_hw),  [],colors(3,:),'filled',"^");
scatter(mainTbl.Availability_Factor(klein_hwx), mainTbl.Normalized_Release_Volume(klein_hwx), 50,colors(3,:),'filled',"square");
g = polyfit(mainTbl.Availability_Factor(gross), mainTbl.Normalized_Release_Volume(gross),1);
m = polyfit(mainTbl.Availability_Factor(mittel),mainTbl.Normalized_Release_Volume(mittel),1);
k = polyfit(mainTbl.Availability_Factor(klein), mainTbl.Normalized_Release_Volume(klein),1);
g1 = plot(px2,polyval(g,[0,225]),"--",'Color',colors(1,:));
m1 = plot(px2,polyval(m,[0,225]),"-",'Color',colors(2,:));
k1 = plot(px2,polyval(k,[0,225]),"-.",'Color',colors(3,:));
xlim([0 225]);
ylim([0 100]);
xlabel('AF [-]');
ylabel('Normalized Release Volume (V_d_,_n_o_r)')

nexttile;
hold on
scatter(mainTbl.Availability_Factor(gross_hw),  mainTbl.Volume_Benefit(gross_hw),  [],colors(1,:),'filled',"^");
scatter(mainTbl.Availability_Factor(gross_hwx), mainTbl.Volume_Benefit(gross_hwx), 50,colors(1,:),'filled',"square");
scatter(mainTbl.Availability_Factor(mittel_hw), mainTbl.Volume_Benefit(mittel_hw), [],colors(2,:),'filled',"^");
scatter(mainTbl.Availability_Factor(mittel_hwx),mainTbl.Volume_Benefit(mittel_hwx),50,colors(2,:),'filled',"square");
scatter(mainTbl.Availability_Factor(klein_hw),  mainTbl.Volume_Benefit(klein_hw),  [],colors(3,:),'filled',"^");
scatter(mainTbl.Availability_Factor(klein_hwx), mainTbl.Volume_Benefit(klein_hwx), 50,colors(3,:),'filled',"square");
g = polyfit(mainTbl.Availability_Factor(gross), mainTbl.Volume_Benefit(gross),1);
m = polyfit(mainTbl.Availability_Factor(mittel),mainTbl.Volume_Benefit(mittel),1);
k = polyfit(mainTbl.Availability_Factor(klein), mainTbl.Volume_Benefit(klein),1);
g1 = plot(px2,polyval(g,[0,225]),"--",'Color',colors(1,:));
m1 = plot(px2,polyval(m,[0,225]),"-",'Color',colors(2,:));
k1 = plot(px2,polyval(k,[0,225]),"-.",'Color',colors(3,:));
ylabel('Volume Benefit [%]');
xlabel('AF [-]');
xlim([0 225]);
ylim([0 100]);
tL = legend({'Large, flood-only';'Large, multipurpose';'Mid-size, flood-only';'Mid-size, multipurpose';...
   'Small, flood-only';'Small, multipurpose';'Best fit - Large';'Best fit - Medium';...
   'Best fit - Small'});
tL.NumColumns = 3;
tL.Layout.Tile = 'south';
