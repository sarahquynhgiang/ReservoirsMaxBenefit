%% resultPlotting
% the first section is (less-than-optimal) setup for all of the plotting
% for figures 4-14, which are plotted by the later sections of this code.
%
% This code also uses hatchfill2 v3.0.0.0 by Kesh Ikuma, which can be
% downloaded here:
% https://matlab.mathworks.com/open/fileexchange/v1?id=53593

load allStudyReservoirs.mat


%% data setup

c1 = find(cell2mat(allReservoirs(:,3))==1);
c2 = find(cell2mat(allReservoirs(:,3))==2);
c3 = find(cell2mat(allReservoirs(:,3))==3);
c4 = find(cell2mat(allReservoirs(:,3))==4);
c5 = find(cell2mat(allReservoirs(:,3))==5);
c6 = find(cell2mat(allReservoirs(:,3))==6);
c7 = find(cell2mat(allReservoirs(:,3))==7);
c8 = find(cell2mat(allReservoirs(:,3))==8);
c9 = find(cell2mat(allReservoirs(:,3))==9);
c10 = find(cell2mat(allReservoirs(:,3))==10);

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

% sort by categories

ts_f = [nat_f_ts,hwo_f_ts,hnw_f_ts];
ts_d = [nat_d_ts,hwo_d_ts,hnw_d_ts];
vol_f = [nat_f_vol,hwo_f_vol,hnw_f_vol];
vol_d = [nat_d_vol,hwo_d_vol,hnw_d_vol];
pen_f = [nat_f_pen,hwo_f_pen,hnw_f_pen];
pen_d = [nat_d_pen,hwo_d_pen,hnw_d_pen];

% full list by size
class_ts_f = [ts_f(c8,:);ts_f(c9,:);ts_f(c1,:);ts_f(c10,:);ts_f(c2,:);ts_f(c4,:);ts_f(c3,:);ts_f(c5,:);...
    ts_f(c7,:);ts_f(c6,:)];
class_ts_d = [ts_d(c8,:);ts_d(c9,:);ts_d(c1,:);ts_d(c10,:);ts_d(c2,:);ts_d(c4,:);ts_d(c3,:);ts_d(c5,:);...
    ts_d(c7,:);ts_d(c6,:)];
class_vol_f = [vol_f(c8,:);vol_f(c9,:);vol_f(c1,:);vol_f(c10,:);vol_f(c2,:);vol_f(c4,:);vol_f(c3,:);vol_f(c5,:);...
    vol_f(c7,:);vol_f(c6,:)];
class_vol_d = [vol_d(c8,:);vol_d(c9,:);vol_d(c1,:);vol_d(c10,:);vol_d(c2,:);vol_d(c4,:);vol_d(c3,:);vol_d(c5,:);...
    vol_d(c7,:);vol_d(c6,:)];
class_pen_f = [pen_f(c8,:);pen_f(c9,:);pen_f(c1,:);pen_f(c10,:);pen_f(c2,:);pen_f(c4,:);pen_f(c3,:);pen_f(c5,:);...
    pen_f(c7,:);pen_f(c6,:)];
class_pen_d = [pen_d(c8,:);pen_d(c9,:);pen_d(c1,:);pen_d(c10,:);pen_d(c2,:);pen_d(c4,:);pen_d(c3,:);pen_d(c5,:);...
    pen_d(c7,:);pen_d(c6,:)];
class_names = [names(c8,:);names(c9,:);names(c1,:);names(c10,:);names(c2,:);names(c4,:);names(c3,:);names(c5,:);...
    names(c7,:);names(c6,:)];
class_nat_useStats = [nat_useStats(c8,:);nat_useStats(c9,:);nat_useStats(c1,:);nat_useStats(c10,:);nat_useStats(c2,:);nat_useStats(c4,:);nat_useStats(c3,:);nat_useStats(c5,:);...
    nat_useStats(c7,:);nat_useStats(c6,:)];
class_hwo_useStats = [hwo_useStats(c8,:);hwo_useStats(c9,:);hwo_useStats(c1,:);hwo_useStats(c10,:);hwo_useStats(c2,:);hwo_useStats(c4,:);hwo_useStats(c3,:);hwo_useStats(c5,:);...
    hwo_useStats(c7,:);hwo_useStats(c6,:)];
class_hnw_useStats = [hnw_useStats(c8,:);hnw_useStats(c9,:);hnw_useStats(c1,:);hnw_useStats(c10,:);hnw_useStats(c2,:);hnw_useStats(c4,:);hnw_useStats(c3,:);hnw_useStats(c5,:);...
    hnw_useStats(c7,:);hnw_useStats(c6,:)];
class_rel_vol_f = [rel_f_vol(c8,:);rel_f_vol(c9,:);rel_f_vol(c1,:);rel_f_vol(c10,:);rel_f_vol(c2,:);rel_f_vol(c4,:);rel_f_vol(c3,:);rel_f_vol(c5,:);...
    rel_f_vol(c7,:);rel_f_vol(c6,:)];
class_sav_vol_f = [sav_f_vol(c8,:);sav_f_vol(c9,:);sav_f_vol(c1,:);sav_f_vol(c10,:);sav_f_vol(c2,:);sav_f_vol(c4,:);sav_f_vol(c3,:);sav_f_vol(c5,:);...
    sav_f_vol(c7,:);sav_f_vol(c6,:)];
class_rel_vol_d = [rel_d_vol(c8,:);rel_d_vol(c9,:);rel_d_vol(c1,:);rel_d_vol(c10,:);rel_d_vol(c2,:);rel_d_vol(c4,:);rel_d_vol(c3,:);rel_d_vol(c5,:);...
    rel_d_vol(c7,:);rel_d_vol(c6,:)];
class_sav_vol_d = [sav_d_vol(c8,:);sav_d_vol(c9,:);sav_d_vol(c1,:);sav_d_vol(c10,:);sav_d_vol(c2,:);sav_d_vol(c4,:);sav_d_vol(c3,:);sav_d_vol(c5,:);...
    sav_d_vol(c7,:);sav_d_vol(c6,:)];
class_res_vol = [res_vol(c8,:);res_vol(c9,:);res_vol(c1,:);res_vol(c10,:);res_vol(c2,:);res_vol(c4,:);res_vol(c3,:);res_vol(c5,:);...
    res_vol(c7,:);res_vol(c6,:)];
class_rf = [rf(c8,:);rf(c9,:);rf(c1,:);rf(c10,:);rf(c2,:);rf(c4,:);rf(c3,:);rf(c5,:);...
    rf(c7,:);rf(c6,:)];
class_ben_d = class_pen_d(:,3)-class_pen_d(:,2);
class_imp_d = -100*class_ben_d./class_pen_d(:,2);
class_tsr_d = 100*(class_ts_d(:,1)-class_ts_d(:,3))./class_ts_d(:,1);
class_y = [y(c8,:);y(c9,:);y(c1,:);y(c10,:);y(c2,:);y(c4,:);y(c3,:);y(c5,:);...
    y(c7,:);y(c6,:)];
class_neg = [neg(c8,:);neg(c9,:);neg(c1,:);neg(c10,:);neg(c2,:);neg(c4,:);neg(c3,:);neg(c5,:);...
    neg(c7,:);neg(c6,:)];
class_pos = [pos(c8,:);pos(c9,:);pos(c1,:);pos(c10,:);pos(c2,:);pos(c4,:);pos(c3,:);pos(c5,:);...
    pos(c7,:);pos(c6,:)];
class_qcrit = [qcrit(c8,:);qcrit(c9,:);qcrit(c1,:);qcrit(c10,:);qcrit(c2,:);qcrit(c4,:);qcrit(c3,:);qcrit(c5,:);...
    qcrit(c7,:);qcrit(c6,:)];
class_qd_max = [qd_max(c8,:);qd_max(c9,:);qd_max(c1,:);qd_max(c10,:);qd_max(c2,:);qd_max(c4,:);qd_max(c3,:);qd_max(c5,:);...
    qd_max(c7,:);qd_max(c6,:)];
class_qd_min = [qd_min(c8,:);qd_min(c9,:);qd_min(c1,:);qd_min(c10,:);qd_min(c2,:);qd_min(c4,:);qd_min(c3,:);qd_min(c5,:);...
    qd_min(c7,:);qd_min(c6,:)];
class_qr = [qr(c8,:);qr(c9,:);qr(c1,:);qr(c10,:);qr(c2,:);qr(c4,:);qr(c3,:);qr(c5,:);...
    qr(c7,:);qr(c6,:)];
class_c = [c(c8,:);c(c9,:);c(c1,:);c(c10,:);c(c2,:);c(c4,:);c(c3,:);c(c5,:);...
    c(c7,:);c(c6,:)];

class_vol_ben_d = -100*(class_vol_d(:,3)-class_vol_d(:,2))./class_vol_d(:,2);
class_nor_rel_vol_d = class_rel_vol_d./class_res_vol;
class_nor_def_vol_d = class_vol_d./class_res_vol;
class_eff_d = class_imp_d./class_nor_rel_vol_d;

class_id = [8;8;9;9;1;1;1;10;2;2;2;4;4;4;4;3;3;3;3;3;5;5;5;7;7;7;7;6;6;6];
idx = 1:30';

% partial by category types
[gross,~] = find(class_id==[1,8,9,10]);
[mittel,~] = find(class_id==[2,3,4,5]);
[klein,~] = find(class_id==[6,7]);

[neben,~] = find(class_id==[9,10]);
haupt = idx(~ismember(idx,neben));

[hw,~] = find(class_id==[2,4,7,8,9]);
hwx = idx(~ismember(idx,hw))';

[mit,~] = find(class_id==[1,2,3,6,10]);
ohne = idx(~ismember(idx,mit));

[gross_hw,~] = find(class_id==[8,9]);
[gross_hwx,~] = find(class_id==[1,10]);

[mittel_hw,~] = find(class_id==[2,4]);
[mittel_hwx,~] = find(class_id==[3,5]);

[klein_hwx,~] = find(class_id==6);
[klein_hw,~] = find(class_id==7);


colors = zeros(3,3);
colors(1,:) = [0.6350 0.0780 0.1840];
colors(2,:) = [0.9290 0.6940 0.1250];
colors(3,:) = [0 0.4470 0.7410];

%

sz = cell(30,1);
sz(gross) = {'Large'};
sz(mittel) = {'Mid-size'};
sz(klein) = {'Small'};

ds = cell(30,1);
ds(mit) = {'Permanent'};
ds(ohne) = {'Operational'};

dam = cell(30,1);
dam(haupt) = {'In-River'};
dam(neben) = {'Parallel'};

use = cell(30,1);
use(hw) = {'Flood-only'};
use(hwx) = {'Multipurpose'};

sz_cat = strcat(ds,", ",use);

sz = categorical(sz);
ds = categorical(ds);
dam = categorical(dam);
use = categorical(use);
sz_cat = categorical(sz_cat);

class_rel_vol_f(class_rel_vol_f==0)=nan;

tbl = table(class_names,sz,dam,ds,use,class_imp_d,class_vol_ben_d,class_rel_vol_d,class_rel_vol_f,class_rf,...
    'VariableNames',{'Name','Size','DamLocation','Inundation','Use','PenBen','VolBen','Release_vol_d','Release_vol_f','RF'});

% clear some variables bc this is a hot mess

clear c1 c2 c3 c4 c5 c6 c7 c8 c9 c10
clear baseStats nat_f_ts nat_d_ts hwo_f_ts hwo_d_ts hnw_f_ts hnw_d_ts
clear nat_f_vol nat_d_vol hwo_f_vol hwo_d_vol hnw_f_vol hnw_d_vol
clear nat_f_pen nat_d_pen hwo_f_pen hwo_d_pen hnw_f_pen hnw_d_pen
clear nat_useStats hwo_useStats hnw_useStats
clear rel_f_vol sav_f_vol rel_d_vol sav_d_vol

% curve fitting

px1 = [0,100];
px3 = [0,max(class_rf)];

lf_rf = class_rf(gross_hw);
lm_rf = class_rf(gross_hwx);
mf_rf = class_rf(mittel_hw);
mm_rf = class_rf(mittel_hwx);
sf_rf = class_rf(klein_hw);
sm_rf = class_rf(klein_hwx);

lf_rv = class_nor_rel_vol_d(gross_hw);
lm_rv = class_nor_rel_vol_d(gross_hwx);
mf_rv = class_nor_rel_vol_d(mittel_hw);
mm_rv = class_nor_rel_vol_d(mittel_hwx);
sf_rv = class_nor_rel_vol_d(klein_hw);
sm_rv = class_nor_rel_vol_d(klein_hwx);

lf_bv = class_vol_ben_d(gross_hw);
lm_bv = class_vol_ben_d(gross_hwx);
mf_bv = class_vol_ben_d(mittel_hw);
mm_bv = class_vol_ben_d(mittel_hwx);
sf_bv = class_vol_ben_d(klein_hw);
sm_bv = class_vol_ben_d(klein_hwx);

lf_bp = class_imp_d(gross_hw);
lm_bp = class_imp_d(gross_hwx);
mf_bp = class_imp_d(mittel_hw);
mm_bp = class_imp_d(mittel_hwx);
sf_bp = class_imp_d(klein_hw);
sm_bp = class_imp_d(klein_hwx);

lf_ef = class_eff_d(gross_hw);
lm_ef = class_eff_d(gross_hwx);
mf_ef = class_eff_d(mittel_hw);
mm_ef = class_eff_d(mittel_hwx);
sf_ef = class_eff_d(klein_hw);
sm_ef = class_eff_d(klein_hwx);

%% Figure 4

figure
t = tiledlayout(1,3);
t.TileSpacing = 'compact';

nexttile([1 2]);
hold on
scatter(class_rf(gross_hw),class_imp_d(gross_hw),[],colors(1,:),'filled',"^");
scatter(class_rf(gross_hwx),class_imp_d(gross_hwx),[],colors(1,:),'filled',"square");
scatter(class_rf(mittel_hw),class_imp_d(mittel_hw),[],colors(2,:),'filled',"^");
scatter(class_rf(mittel_hwx),class_imp_d(mittel_hwx),[],colors(2,:),'filled',"square");
scatter(class_rf(klein_hw),class_imp_d(klein_hw),[],colors(3,:),'filled',"^");
scatter(class_rf(klein_hwx),class_imp_d(klein_hwx),[],colors(3,:),'filled',"square");
text(class_rf+2,class_imp_d,class_names)
xlabel('Storage Factor [-]');
ylabel('Penalty Benefit [%]');
ylim([0 100]);
%title('Water Availability');
legend({'Large, flood-only';'Large, multipurpose';'Mid-size, flood-only';'Mid-size, multipurpose';...
    'Small, flood-only';'Small, multipurpose'});

nexttile;
boxchart(tbl.Size,tbl.PenBen,'GroupByColor',tbl.Use)
legend;
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
barh(class_ts_f,1)
hatchfill2(A);
hatchfill2(B);
hatchfill2(C);
yticks(1:30)
yticklabels(class_names);
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
barh(class_vol_f,1)
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
barh(-class_pen_f,1)
hatchfill2(A);
hatchfill2(B);
hatchfill2(C);
yticks(1:30);
yticklabels([]);
xticks([1 10 100 1000 10000 100000])
xscale('log');
title('log(Total Flood Penalty)')
set(gca,'YDir','reverse');

t1 = nexttile;
lims = [0, max(class_ts_f(:,2))+0.2*max(class_ts_f(:,2))];
scatter(class_ts_f(:,2),class_ts_f(:,3),[],"+");
hold on;
line(lims(1):lims(2),lims(1):lims(2));
legend({'Reservoirs';'1:1 Line'})
% ylabel('Flood Operation Model');
xlabel('Combined Operation Model');
xlim(lims);
ylim(lims);
title('Time under Floods [hrs]');

t1 = nexttile;
lims = [0, max(class_vol_f(:,2))+0.2*max(class_vol_f(:,2))];
scatter(class_vol_f(:,2),class_vol_f(:,3),[],"+");
hold on;
line(lims(1):lims(2),lims(1):lims(2));
% ylabel('Flood Operation Model');
xlabel('Combined Operation Model');
xlim(lims);
ylim(lims);
title('Flooding Volume [1000 m3]');

t1 = nexttile;
lims = [min(class_pen_f(:,2))+0.2*max(class_pen_f(:,2)),0];
scatter(class_pen_f(:,2),class_pen_f(:,3),[],"+");
hold on;
line(lims(1):lims(2),lims(1):lims(2));
% ylabel('Flood Operation Model');
xlabel('Combined Operation Model');
set(gca,'Ydir','reverse')
set(gca,'Xdir','reverse')
xlim(lims);
ylim(lims);
title('Flood Penalty');

imwrite(fig,'fig10.tif','Resolution',300)

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
barh(class_ts_d(:,2:3),1)
hatchfill2(A);
hatchfill2(B);
hatchfill2(C);
xlim([1 7*10^4])
yticks(1:30);
yticklabels(class_names);
set(gca,'YDir','reverse');
title('# Drought Hours')
tL = legend({'Large Reservoirs','','','Medium Reservoirs','','','Small Reservoirs','','Multipurpose',...
    'Flood Operation','Combined Operation'});
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
barh(class_vol_d,1)
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
patch([1000 1000 10^6 10^6],[0.5 4.5 4.5 0],'r','FaceColor','#fcd1cf');
A = patch([1000 1000 10^6 10^6],[4.5 8.5 8.5 4.5],'r','FaceColor','#fcd1cf');
patch([1000 1000 10^6 10^6],[8.5 15.5 15.5 8.5],'r','FaceColor','#fbfccf');
B = patch([1000 1000 10^6 10^6],[15.5 23.5 23.5 15.5],'r','FaceColor','#fbfccf');
patch([1000 1000 10^6 10^6],[23.5 27.5 27.5 23.5],'r','FaceColor','#cff7fc');
C = patch([1000 1000 10^6 10^6],[27.5 30.5 30.5 27.5],'r','FaceColor','#cff7fc');
barh(-class_pen_d,1)
xscale('log');
hatchfill2(A);
hatchfill2(B);
hatchfill2(C);
yticks(1:30);
yticklabels([]);
xlim([1000 10^6])
xticks([1000 10^4 10^5 10^6])
set(gca,'YDir','reverse');
title('Total Penalty')

t1 = nexttile;
lims = [0, max(class_ts_d(:,2))+0.2*max(class_ts_d(:,2))];
scatter(class_ts_d(:,2),class_ts_d(:,3),[],"+");
hold on;
line(lims(1):lims(2),lims(1):lims(2));
legend({'Reservoirs';'1:1 Line'})
ylabel('Flood Operation Model');
xlabel('Combined Operation Model');
xlim(lims);
ylim(lims);
title('Time under Drought [hrs]');

t1 = nexttile;
lims = [0, max(class_vol_d(:,2))+0.2*max(class_vol_d(:,2))];
scatter(class_vol_d(:,2),class_vol_d(:,3),[],"+");
hold on;
line(lims(1):lims(2),lims(1):lims(2));
% ylabel('Flood Operation Model');
xlabel('Combined Operation Model');
xlim(lims);
ylim(lims);
title('Deficit Volume [1000 m^3]');

t1 = nexttile;
lims = [min(class_pen_d(:,2))+0.2*max(class_pen_d(:,2)),0];
scatter(class_pen_d(:,2),class_pen_d(:,3),[],"+");
hold on;
line(lims(1):lims(2),lims(1):lims(2));
% ylabel('Flood Operation Model');
xlabel('Combined Operation Model');
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
a = bar([class_vol_ben_d,class_imp_d]);
hatchfill2(A);
hatchfill2(B);
hatchfill2(C);
xticks(1:30);
xticklabels(class_names);
xlim([0.5 30.5])
ylim([0 100]);
title('Drought Benefit [%]')
tL = legend({'Large Reservoirs','','','Medium Reservoirs','','','Small Reservoirs','','Multipurpose',...
    'Volume Benefit','Penalty Benefit'});
tL.NumColumns = 4;
tL.Location = 'northoutside';

t(3) = nexttile;
hold on
scatter(class_vol_ben_d(gross_hw),class_imp_d(gross_hw),[],colors(1,:),'filled',"^");
scatter(class_vol_ben_d(gross_hwx),class_imp_d(gross_hwx),[],colors(1,:),'filled',"square");
scatter(class_vol_ben_d(mittel_hw),class_imp_d(mittel_hw),[],colors(2,:),'filled',"^");
scatter(class_vol_ben_d(mittel_hwx),class_imp_d(mittel_hwx),[],colors(2,:),'filled',"square");
scatter(class_vol_ben_d(klein_hw),class_imp_d(klein_hw),[],colors(3,:),'filled',"^");
scatter(class_vol_ben_d(klein_hwx),class_imp_d(klein_hwx),[],colors(3,:),'filled',"square");
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

class_rel_vol = [class_rel_vol_f,class_rel_vol_d];
temp = tbl;
temp.Use(:) = 'All';
temp.Size(:) = 'All';
temp = [tbl;temp];

figure
t = tiledlayout(1,4);

nexttile([1 2])
hold on;
patch([0 4.5 4.5 0],[1 1 5.5*10^5 5.5*10^5],'r','FaceColor','#fcd1cf');
A = patch([4.5 8.5 8.5 4.5],[1 1 5.5*10^5 5.5*10^5],'r','FaceColor','#fcd1cf');
patch([8.5 15.5 15.5 8.5],[1 1 5.5*10^5 5.5*10^5],'r','FaceColor','#fbfccf');
B = patch([15.5 23.5 23.5 15.5],[1 1 5.5*10^5 5.5*10^5],'r','FaceColor','#fbfccf');
patch([23.5 27.5 27.5 23.5],[1 1 5.5*10^5 5.5*10^5],'r','FaceColor','#cff7fc');
C = patch([27.5 30.5 30.5 27.5],[1 1 5.5*10^5 5.5*10^5],'r','FaceColor','#cff7fc');
bar(class_rel_vol);
hatchfill2(A);
hatchfill2(B);
hatchfill2(C);
%set(gca,'YDir','reverse');
xlim([0 30.5]);
xticks(1:30);
xticklabels(class_names);
ylim([1 5.5*10^5])
yscale('log');
ylabel('Volume [1000 m^3]');
tL = legend({'Large Reservoirs','','','Medium Reservoirs','','','Small Reservoirs','','Multipurpose'...
    'Flood Pre-Release','Drought Release'});
tL.NumColumns = 4;
tL.Location = 'northoutside';

nexttile;
boxchart(temp.Size,temp.Release_vol_d,'GroupByColor',temp.Use);
yscale('log');
ylim([1 5.5*10^5])
title('Drought Release')

nexttile;
boxchart(temp.Size,temp.Release_vol_f,'GroupByColor',temp.Use);
yscale('log');
ylim([1 5.5*10^5])
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
scatter(class_rf(gross_hw),  class_nor_rel_vol_d(gross_hw),  [],colors(1,:),'filled',"^");
scatter(class_rf(gross_hwx), class_nor_rel_vol_d(gross_hwx), 50,colors(1,:),'filled',"square");
scatter(class_rf(mittel_hw), class_nor_rel_vol_d(mittel_hw), [],colors(2,:),'filled',"^");
scatter(class_rf(mittel_hwx),class_nor_rel_vol_d(mittel_hwx),50,colors(2,:),'filled',"square");
scatter(class_rf(klein_hw),  class_nor_rel_vol_d(klein_hw),  [],colors(3,:),'filled',"^");
scatter(class_rf(klein_hwx), class_nor_rel_vol_d(klein_hwx), 50,colors(3,:),'filled',"square");
g = polyfit(class_rf(gross), class_nor_rel_vol_d(gross),1);
m = polyfit(class_rf(mittel),class_nor_rel_vol_d(mittel),1);
k = polyfit(class_rf(klein), class_nor_rel_vol_d(klein),1);
g1 = plot(px2,polyval(g,[0,225]),"--",'Color',colors(1,:));
m1 = plot(px2,polyval(m,[0,225]),"-",'Color',colors(2,:));
k1 = plot(px2,polyval(k,[0,225]),"-.",'Color',colors(3,:));
xlim([0 225]);
ylim([0 100]);
xlabel('SF [-]');
ylabel('Normalized Release Volume (V_d_,_n_o_r)')

nexttile;
hold on
scatter(class_rf(gross_hw),  lf_bv,[],colors(1,:),'filled',"^");
scatter(class_rf(gross_hwx), lm_bv,50,colors(1,:),'filled',"square");
scatter(class_rf(mittel_hw), mf_bv,[],colors(2,:),'filled',"^");
scatter(class_rf(mittel_hwx),mm_bv,50,colors(2,:),'filled',"square");
scatter(class_rf(klein_hw),  sf_bv,[],colors(3,:),'filled',"^");
scatter(class_rf(klein_hwx), sm_bv,50,colors(3,:),'filled',"square");
g = polyfit(class_rf(gross), class_vol_ben_d(gross),1);
m = polyfit(class_rf(mittel),class_vol_ben_d(mittel),1);
k = polyfit(class_rf(klein), class_vol_ben_d(klein),1);
g1 = plot(px2,polyval(g,[0,225]),"--",'Color',colors(1,:));
m1 = plot(px2,polyval(m,[0,225]),"-",'Color',colors(2,:));
k1 = plot(px2,polyval(k,[0,225]),"-.",'Color',colors(3,:));
ylabel('Volume Benefit [%]');
xlabel('SF [-]');
xlim([0 225]);
ylim([0 100]);
tL = legend({'Large, flood-only';'Large, multipurpose';'Mid-size, flood-only';'Mid-size, multipurpose';...
   'Small, flood-only';'Small, multipurpose';'Best fit - Large';'Best fit - Medium';...
   'Best fit - Small'});
tL.NumColumns = 3;
tL.Layout.Tile = 'south';