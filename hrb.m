classdef hrb
    % Defines properties of individual reservoirs
    
    properties
        % reservoir characteristics
        hrbName         % reservoir name
        catchment       % LARSIM model catchment
        hauptschluss    % Hauptschluss = true, Neben = false
        use_short       % usage code
        use_long        % usage(s) as a list
        months_w        % winter operation months 
        days_w          % day of month that winter operation begins
        measured        % measured data, if exists
        fuellkurve      % Beckenfuellkurve (Einstauhoehe-Volumen)
        class_id        % class ID code (1-10)
        class_id_long   % description of class ID
        rf              % Rueckhaltefaktor (storage factor, SF) based on Q70 and Qin
        rf_d            % originally estimated Rueckhaltefaktor [-] (if applicable) ((MQ-MNQ)/V)
        rf_d_p          % Rueckhaltefaktor percentile (out of all in class_id, based on rf_d)
        
        % time series
        qin             % qin time series; from LARSIM
        qd              % Hourly minimum flow (365 days); calculated from qin
        qd_ts           % Hourly minimum flow as a time series matching qin
        v               % volume [1000 m3] time series; calculated from operation
        qout            % qout [m3/s] time series; calculated from operation
        ssi             % Standardized Streamflow Index; 1, 3, and 6-month
        
        % discharge parameters
        Qr_d            % Regelabfluss (if seasonal, summer); from LUBW
        Qr_w            % Regelabfluss (winter); from LUBW
        HWE             % discharge-volume [1000 m3] curve for extreme floods (HWEA)
        HWE_2           % discharge-volume [1000 m3] curve through a secondary location
        GA              % discharge-volume [1000 m3] curve for extreme floods (Grundablass)
        ED              % minimum emptying duration [h], rounded to next integer (Vv/Qcrit) 
        
        % volume parameters
            % note that these should be TOTAL volume (i.e. Vv = Vd + HWRR)
            % außergew. HWRR 2 usually DOES NOT include HWRR 1
            % order of data priority: LUBW Betriebsdaten > STA_Sachdaten > UDO Tabelle > LARSIM data
        Vd              % Dauerstau volume [1000 m3] (if seasonal, summer); from LUBW
        Vd_w            % Dauerstau volume [1000 m3] (winter); from LUBW
        Vv              % Normal flood retention volume [1000 m3]; from LUBW
        Vh1             % Hochwasserstauziel 1 [1000 m3]; from LUBW
        Vh2             % Hochwasserstauziel 2 [1000 m3]; from LUBW
        Vk              % Crown volume [1000 m3]; from LUBW
        
        % optimization values
        Qr_o            % Regelabfluss; optimized
        Vd_o            % Dauerstau volume [1000 m3] (optimized)
        qout_od         % qout [m3/s] time series; calculated from default optimization model (flood module only)
        v_od            % volume [1000 m3] time series; calculated from default optimization model (flood module only)
        pD_d            % drought penalty time series, default (flood module only)
        pF_d            % flood penalty time series, default (flood module only)
        pMonthly        % total monthly penalties across the time series (flood module only)
        results         % stores results from optimization (ED = time from V(t) - 0)
        rf_o            % optimized yearly RF [-] (total stored water (flood & slow) / operable volume / year)
        rf_o_d          % optimized yearly RF [-] (drought release volume over all years / operable volume / year)
        baseStats       % base statistics between natural / modified (flood-only optModel) / optimized models
        
        % notes
        notes           % store strings re: notes about the reservoir
        
    end
    
    methods
        
        % constructor function
        function obj = hrb(hrbName,catchment,hauptschluss,use_short)
            % Construct an instance of this class
            obj.hrbName = hrbName;
            obj.catchment = catchment;
            obj.hauptschluss = hauptschluss;
            obj.use_short = use_short;
        end
        
        % Calculate SSI-1, -3, and -6 and store in object
        function obj = calcSSI(obj)
            daily = retime(table2timetable(obj.qin),'daily','mean');
            daily = timetable2table(daily);
            
            SSI1 = calculateSDAT(daily.Q,30);
            SSI1 = array2table(SSI1,'VariableNames',{'SSI-1'});
            
            SSI3 = calculateSDAT(daily.Q,90);
            SSI3 = array2table(SSI3,'VariableNames',{'SSI-3'});
            
            SSI6 = calculateSDAT(daily.Q,180);
            SSI6 = array2table(SSI6,'VariableNames',{'SSI-6'});
            
            time = table(daily.time,'VariableNames',{'time'});
            ssi = [time, daily(:,2), SSI1, SSI3, SSI6];
            obj.ssi = ssi;
        end
        
        % Plot SSI timeseries
        function plotSSI(obj)
            ssiTime = table2timetable(obj.ssi);
            
            figure
            stackedplot(ssiTime,["Q","SSI-1","SSI-3","SSI-6"]);
            title(obj.hrbName)
        end
        
        % Apply current operating rules (Vd, Vv, Qr, HWE, GA) to qin
        function obj = descriptiveModel(obj)

            q = table2array(obj.qin(:,2));
            time = obj.qin(:,1);
            months = month(obj.qin.time);

            Qout = zeros(size(q));  % outflow time series
            V = zeros(size(q));     % volume time series; volume at the end of the time period (e.g. at 11:59)
            
            if istable(obj.HWE)
                obj.HWE = table2array(obj.HWE);
            end

            for i=1:size(q,1)
                
                if isempty(obj.months_w)
                    Qr = obj.Qr_d;
                    vd = obj.Vd;
                elseif ismember(months(i),obj.months_w)
                    Qr = obj.Qr_w;
                    vd = obj.Vd_w;
                else
                    Qr = obj.Qr_d;
                    vd = obj.Vd;
                end

                if i==1                 % assume empty at beginning
                    V(i) = 0;
                    Qout(i) = q(i);

                elseif V(i-1) < vd            % if volume is less than Dauerstau, fill
                    Qout(i) = 0;
                    V(i) = V(i-1)+ q(i)*3.6;   % dV = Q*t*(60*60/1000) = Q*3.6

                elseif V(i-1) < obj.Vv        % if volume is less than Vollstau, check flow
                    if q(i) <= Qr        % if under Regelabfluss, release volume > Vd

                        dv = V(i-1) - vd;   % dischargeable volume
                        dq = dv/3.6;         % maximum discharge

                        if dq+q(i) > Qr    % release as much water as possible
                            Qout(i) = Qr;
                            V(i) = V(i-1) - (Qr-q(i))*3.6;

                        else
                            Qout(i) = dq+q(i);  % if dq = 0, qin = qout and dV = 0
                            V(i) = V(i-1) - dq*3.6;

                        end

                    elseif q(i) >= Qr       % if above Qr, Qout = Qr; dV = (Qin-Qout)*36
                        Qout(i) = Qr;
                        V(i) = V(i-1) + (q(i)-Qr)*3.6;
                    end

                elseif V(i-1) >= obj.Vv       % if V >= Vollstau, look into HWE flow rules
                    
                    if q(i) > Qr
                        
                        if ~isempty(obj.HWE) 
                            
                            if V(i-1) > obj.HWE(end,1)
                                Qout(i) = q(i);
                                
                            elseif V(i-1) < obj.HWE(1,1)
                                Qout(i) = Qr;
                                
                            else
                                % interpolate using V 
                                if size(obj.HWE,1) == 1
                                    temp = [obj.Vv, 0];
                                    obj.HWE = [temp;obj.HWE];
                                end
                                
                                qHWE = interp1(obj.HWE(:,1),obj.HWE(:,2),V(i-1));
                                
                                Qout(i) = qHWE+Qr;
                            end
                            
                        else
                            Qout(i) = q(i);
                        end
                        
                    else
                        Qout(i) = q(i);

                    end
                    
                    V(i) = V(i-1) + (q(i)-Qout(i))*3.6;
                    
                end

            end
            
            Qout = array2table(Qout,'VariableNames',{'Qout'});
            Qout = [time, Qout];
            
            V = array2table(V,'VariableNames',{'V'});
            V = [time, V];
            
            obj.qout = Qout;
            obj.v = V;
            
        end
        
        % Plot Qin, Qout, V timeseries
        function plotVQout(obj)

            C = obj.Vv-obj.Vd;
            
            figure
            t = tiledlayout(2,1);
            t.TileSpacing = 'compact';
            
            t1 = nexttile;
            hold on
            plot(obj.qin.time,obj.qin.Q,'LineStyle',':','Color','k');
            plot(obj.qin.time,obj.qout_od,'Color','#0072BD');
            yline(obj.Qr_d,'Color','r');
            hold off
            ylabel('Discharge [m^3/s]');
            legend('Qin','Qout','Qcrit');
            title(obj.hrbName);
            
            t2 = nexttile;
            hold on
            plot(obj.qin.time,obj.v_od);
            legendNames = {'Reservoir Volume'};
            yline(C,'Color','r','LineStyle','-.');
            legendNames = [legendNames; {'Capacity'}];
            
            hold off
            ylabel('Volume [1000 m^3]')
            title(obj.hrbName);
            legend(legendNames);
            
            linkaxes([t1 t2],'x');
            
        end
        
        % Calculate the hourly min flow time series for Q70, Q80, and Q95
        % percentile exceedance
        function obj = calcMinFlow(obj)
            qin = obj.qin;
            
            % create a generalized array for each day of the year where the first 
            % column is the day and the second column is the hour
            doy = [datetime(2001,1,1,0,0,0):hours(1):datetime(2001,12,31,23,0,0)]'; %#ok<NBRAK>
            
            % keep it as a 365-day year and, on leap years, use the March 1st data for
            % February 29th
            qd = [1:size(doy,1)]';
            
            nyears = size(unique(year(qin.time)),1);
            q_sorted = nan(nyears,8760);
            
            % reorganize data by DOY
            % February 29th will be incorporated into March 1st data; i.e. February
            % 29th and March 1st will have the same Julian day
            
            % find Julian day for each time step for easier sorting
            qdoy = day(qin.time,'dayofyear');
            qhours = hour(qin.time)+1;
            
            % identify indices for timestamps in leap years to adjust, starting with 
            % March 1st (i.e. DOY 61-366 during leap years)
            iLeap = find(rem(year(qin.time),4)==0 & qdoy >=61 & qdoy <= 366);
            
            % change Julian day for leap year March 1st to 60 (normal Julian day) (i.e.
            % qdoy(iLeap) = 60) and adjust the rest of the year to match
            qdoy(iLeap) = qdoy(iLeap)-1;
            
            % change qdoy to be hourly timestep
            qhours = (qdoy-1)*24+qhours;
            
            % take moving average of qin
            mDays = 30;
            k = 24*mDays+1;
            qdata = movmean(qin.Q,k,"Endpoints","discard");

            for i=1:size(qd,1)
                idx = find(qhours==i);
                data = nan(size(idx,1),721);

                for ii=1:size(idx)
                    bwd = max(idx(ii)-(mDays/2)*24,1);
                    fwd = min(idx(ii)+(mDays/2)*24,size(qin.Q,1));
                    data(ii,1:(fwd-bwd+1)) = qin.Q(bwd:fwd)';
                end

                data = reshape(data,[],1);
                data(isnan(data)) = [];

                [~, rank] = ismember(data,sort(data));
                p = rank/(length(data)+1);
                p = 1-p;

                X = sort(unique(p),'descend');
                V = unique(sort(data));

                if ~isempty(find(p==0.7, 1))
                    qd1(i,1) = unique(data(p==0.7));
                else
                    qd1(i,1) = interp1(X,V,0.7);
                end
            
                if ~isempty(find(p==0.8, 1))
                    qd2(i,1) = unique(data(p==0.8));
                else
                    qd2(i,1) = interp1(X,V,0.8);
                end
            
                if ~isempty(find(p==0.95, 1))
                    qd3(i,1) = unique(data(p==0.95));
                else
                    qd3(i,1) = interp1(X,V,0.95);
                end

                data = qin.Q(idx);

                % add selection of q into a sorted timeseries for plotting
                    % modify leap year data (skip Feb 29)
                if day(qin.time(idx(1)),'dayofyear')==60
            
                    t1 = day(qin.time(idx),'dayofyear');
                    idx1 = find(t1==61);
                    data(idx1)=[];
                end
            
                n = year(qin.time(idx(1)))-1996;
            
                q_sorted(n:n+length(data)-1,i) = data;
            
            end
            
            % assemble into a final table for storage
            qd = table(qd1,qd2,qd3,'VariableNames',{'Q70','Q80','Q95'});
            obj.qd = qd; %#ok<*PROP>

            qd_ts = table(qdTS(qd1,obj),qdTS(qd2,obj),qdTS(qd3,obj),...
                'VariableNames',{'Q70','Q80','Q95'}); %#ok<*NASGU>
            obj.qd_ts = qd_ts;

            % prep median and min timeseries for plotting
            q_sorted(q_sorted==0) = nan;
            qmed = median(q_sorted,1,'omitnan')';
            qmin = min(q_sorted,[],1,'omitnan')';
            
            % plot qd comparisons
            figure
            hold on
            for i=1:nyears
                plot(doy,q_sorted(i,:),"Color","#BABABA");
            end
            qMed = plot(doy,qmed,'Color',"#BABABA");
            qMin = plot(doy,qmin,'Color',"#BABABA");
            % p1 = patch([doy; flipud(doy)], [qmin; flipud(qmed)],'r');
            % p1.EdgeColor = 'none';
            % p1.FaceColor = '#BABABA';
            % p1.FaceAlpha = 0.25;
            
            
            q1 = plot(doy,qd1,'Color',"#0072BD",'LineWidth',2);
            q2 = plot(doy,qd2,'Color',"#D95319",'LineWidth',2);
            q3 = plot(doy,qd3,'Color',"#EDB120",'LineWidth',2);
            
            hold off
            legend([qMed q1 q2 q3],...
                {'30-day centered moving average 1997-2021',...
                '70th Percentile Exceedance','80th Percentile Exceedance',...
                '95th Percentile Exceedance'});
            title('Different Percentile Exceedance Thresholds for Streamflow');

        end
            
        % Match qd (single column) to an object's time series (time);
        % called in calcMinFlow
        function qd_ts = qdTS(qd,obj)

            time = obj.qin.time;
            ts = day(time,'dayofyear');
            qd_ts = zeros(size(qd));
            
            % identify indices for timestamps in leap years to adjust, starting with 
            % March 1st (i.e. DOY 61-366 during leap years)
            iLeap = find(rem(year(time),4)==0 & ts >=61 & ts <= 366);
            
            % change Julian day for leap year March 1st to 60 (normal Julian day) (i.e.
            % qdoy(iLeap) = 60) and adjust the rest of the year to match
            ts(iLeap) = ts(iLeap)-1;
            
            % find the hour rank of the first time step
            qhours = hour(time)+1;
            
            ts = (ts-1)*24+qhours;
            
            for i=1:size(qd,1)
                qd_ts(ts==i)=qd(i);
            end
        
        end

        % Run a default flood-only model and calculate default penalties;
        % also produces a plot
        function  obj = floodOptModel(obj,qd_ts)

            ED_ts = zeros(size(obj.qin.time));
            
            % initialize based on object
            Qrd = obj.Qr_d;                             % Qcrit = max downstream flow
            qd = qd_ts;% obj.qd_ts.Q70;                              % qd = min discharge target
            C = obj.Vv - obj.Vd;                        % C = reservoir operating capacity
            qin = obj.qin.Q;                            % qin = inflow
                        
            % initialize volume, drought volume, qd, and Qout time series
            V = zeros(size(qin,1),1);
            Vstore = V;
            Vflood = V;
            Vrelease = V;
            Vrelease_c = V;
            Vneed = V;
            Qout = V;
            modTS = V;
            
            % model operation
            
            % initializing time step
            Qout(1,1) = qin(1);
            V(1) = 0;
            Vneed(1) = max([3.6*(qd(1) - qin(1)) 0]);
            modTS(1) = 5;
            
            for t=2:size(qin,1)                         % time step = hours
            
                % flood operation module (code: 1)
                if qin(t) > Qrd
                    modTS(t) = 1;
            
                    dv = 3.6*(qin(t)-Qrd);            % incoming (+) volume [1000 m3]
                    
                    if dv < (C - V(t-1))
                        Qout(t,1) = Qrd;
                        V(t) = V(t-1) + dv;
                    else
                        Qout(t,1) = qin(t) - (C - V(t-1))/3.6;
                        V(t) = C;
                    end
            
                
                % default flood release module
                    % ***** USE ONLY WHEN MODELING THE AS-IS SCENARIO *****
                    % releases all volume after flood wave passes
                elseif V(t-1) > 0

                    dv = 3.6*(Qrd - qin(t));          % outgoing (+) volume [1000 m3]

                    if dv < V(t-1)
                        V(t) = V(t-1) - dv;
                        Qout(t,1) = Qrd;
                    else
                        Qout(t,1) = qin(t) + V(t-1)/3.6;
                        V(t) = 0;
                    end
            
                % normal operation (code: 5)
                else
                    modTS(t) = 5;
                    Qout(t,1) = qin(t); %#ok<*PROPLC>
                    V(t) = V(t-1);
                end

            end

            [pF,pD] = penalty(Qout,obj,qd);

            obj.qout_od = Qout;
            obj.v_od = V;
            obj.pF_d = pF;
            obj.pD_d = pD;

            % plot
            plotFloodOptModel(obj,qd);

        end

        % Compare penalty of optModel with default
        function [penalties, maintF, benD] = compPenalty (Qout, obj, qd_ts)

            [pF,pD] = penalty(Qout,obj,qd_ts);
            
            pF_d = obj.pF_d;
            pD_d = obj.pD_d;
            
            dpF = pF - pF_d;
            dpD = pD - pD_d;
            
            % benefit = reduction in penalty
            benD = sum(dpD);
            
            % check that d(flood penalty) = 0 at all time steps (avoids
            % cross-compensation)
            if isempty(find(dpF~=0))
                maintF = 'true';
            else
                maintF = 'false';
            end
            
            penalties = table(pF,pD,dpF,dpD,'VariableNames',{'Flood Penalty','Drought Penalty','dFlood','dDrought'});

        end

        % Calculate penalty functions (called in compPenalty and floodOptModel)
        function [pF, pD] = penalty(Qout,obj,qd_ts)

            Qr_d = obj.Qr_d;        % Qcrit
            qd = qd_ts;%obj.qd_ts.Q70;        % discharge target time series
            
            pF = Qout;
            pF = -5*(pF-Qr_d);
            pF(Qout<=Qr_d) = 0;
            
            % catch all to avoid -inf
                % 24.07.05: edited fringe condition to be equal to the
                % penalty at min(qd_ts)/4
                % previous: minQ = 0.001 m^/s
            minQ = min(qd_ts)/4;
            pD = Qout;
            pD(pD<minQ) = minQ;
            pD = -1./sqrt(pD)+1./sqrt(qd);
            pD(Qout>qd) = 0;
        
        end

        % Calculate outputs needed for multiOptModel using a simplified
        % optimization model with a volume-dependent ED
        function [Qout,V,Vflood,Vrelease_f,Vrelease_f_c,Vstore,Vrelease_d,Vrelease_d_c,Vneed,modTS] = optModel(obj,Qr,qd_ts)

            ED_ts = zeros(size(obj.qin.time));
            
            % initialize based on object
            Qrd = obj.Qr_d;                             % Qcrit = max downstream flow
            qd = qd_ts;
            %qd = obj.qd_ts.Q70;                              % qd = min discharge target
            C = obj.Vv - obj.Vd;                        % C = reservoir operating capacity
            qin = obj.qin.Q;                            % qin = inflow
                        
            % initialize volume, drought volume, qd, and Qout time series
            V = zeros(size(qin,1),1);
            Vstore = V;
            Vflood = V;
            Vrelease_f = V;
            Vrelease_f_c = V;
            Vrelease_d = V;
            Vrelease_d_c = V;
            Vneed = V;
            Qout = V;
            modTS = V;
            
            % model operation
            
            % initializing time step
            Qout(1,1) = qin(1);
            V(1) = 0;
            Vneed(1) = max([3.6*(qd(1) - qin(1)) 0]);
            modTS(1) = 5;
            
            for t=2:size(qin,1)                         % time step = hours
            
                % flood operation module (code: 1)
                if qin(t) > Qrd
                    modTS(t) = 1;
            
                    dv = 3.6*(qin(t)-Qrd);            % incoming (+) volume [1000 m3]
                    
                    if dv < (C - V(t-1))
                        Qout(t,1) = Qrd;
                        V(t) = V(t-1) + dv;
                    else
                        Qout(t,1) = qin(t) - (C - V(t-1))/3.6;
                        V(t) = C;
                    end
            
                    % tracks how much water is stored during floods
                    Vflood(t) = V(t) - V(t-1);
            
                else
                    % calculate ED
                    ED = 1;
                    dV = V(t-1) + max([0,(qin(t) - Qr)*3.6]);
                    while t+ED <= size(qin,1)-1
                        % find the emptying duration by finding how many time
                        % steps it would take to empty the total operating 
                        % volume given future inflow

                        dV = dV - 3.6*(Qrd-qin(t+ED));

                        if dV < 0
                            break
                        end

                        ED = ED+1;

                    end

                    ED_ts(t) = ED; 

                    if t==size(qin,1)
                        ED_ts(t) = 0;
                    end

                % pre-flood release module (code: 2)
                    if max(qin(t:(t+ED_ts(t)))) > Qrd

                        while qin(t) <= Qrd
                            modTS(t) = 2;

                            dv = 3.6*(Qrd - qin(t));            % outgoing (+) volume [1000 m3]

                            if V(t-1) == 0
                                Qout(t,1) = qin(t);
                                V(t) = V(t-1);
                            elseif dv < V(t-1)
                                Qout(t,1) = Qrd;
                                V(t) = V(t-1) - dv;
                            else
                                if dv > 0
                                    Qout(t,1) = qin(t) + V(t-1)/3.6;
                                    V(t) = 0;
                                else
                                    Qout(t,1) = qin(t);
                                    V(t) = 0;
                                end
                            end

                            % tracks how much water has been released for
                            % pre-flood drawdwon
                            Vrelease_f(t) = V(t-1)-V(t);

                            % tracks how much water has been released for flood (cumulative)
                            Vrelease_f_c(t) = Vrelease_f_c(t-1)+Vrelease_f(t);

                            % tracks how much water has been released for flood (cumulative)
                            Vrelease_d_c(t) = Vrelease_d_c(t-1)+Vrelease_d(t);

                            % this overwrites all possibilities to go to other modules
                            % until flood conditions are reached (perfect forecast only)
                            t = t+1; %#ok<FXSET>

                        end


                % drought release module (code: 3)
                    elseif qin(t) <= qd(t,1) 
                        modTS(t) = 3;

                        dv = 3.6*(qd(t,1) - qin(t));      % outgoing (+) volume [1000 m3]

                        if dv < V(t-1)
                            Qout(t,1) = qd(t,1);
                            V(t) = V(t-1) - dv;
                        else
                            if dv < 0
                                Qout = qin(t) + dv/3.6;
                                V(t) = 0;
                            else    % failed drought release (code: 6)
                                Qout(t,1) = qin(t);
                                V(t) = 0;
                                modTS(t) = 6;
                            end
                        end

                        % tracks how much water has been released for drought (single time step)
                        Vrelease_d(t) = V(t-1)-V(t);

                        Vneed(t) = dv;

                % slow fill module (code: 4)
                    elseif qin(t) >= Qr
                        modTS(t) = 4;

                        dv = 3.6*(qin(t)-Qr);             % incoming (+) volume [1000 m3]

                        if dv < (C-V(t-1))
                            Qout(t,1) = Qr;
                            V(t) = V(t-1) + dv;
                        else
                            Qout(t,1) = qin(t) - (C-V(t-1))/3.6;
                            V(t) = C;
                        end

                        % tracks how much water is filled during slow storage
                        Vstore(t) = V(t)-V(t-1);
                
                % default flood release module
                    % ***** USE ONLY WHEN MODELING THE AS-IS SCENARIO *****
                    % releases all volume after flood wave passes
                    % elseif V(t-1) > 0
                    % 
                    %     dv = 3.6*(Qrd - qin(t));          % outgoing (+) volume [1000 m3]
                    % 
                    %     if dv < V(t-1)
                    %         V(t) = V(t-1) - dv;
                    %         Qout(t,1) = Qrd;
                    %     else
                    %         Qout(t,1) = qin(t) + V(t-1)/3.6;
                    %         V(t) = 0;
                    %     end
                
                    % normal operation (code: 5)
                    else
                        modTS(t) = 5;
                        Qout(t,1) = qin(t); %#ok<*PROPLC>
                        V(t) = V(t-1);
                    end
                end

                % tracks how much water has been released for drought (cumulative)
                Vrelease_d_c(t) = Vrelease_d_c(t-1)+Vrelease_d(t);

                % tracks how much water has been released for flood (cumulative)
                Vrelease_f_c(t) = Vrelease_f_c(t-1)+Vrelease_f(t);
            end

            modelOut = table(Qout,V,Vflood,Vrelease_f,Vrelease_f_c,Vstore,Vrelease_d,...
                Vrelease_d_c,Vneed,modTS,'VariableNames',{'Qout','V','Vflood','Vrelease_f'...
                'Vrelease_f_c','Vstore','Vrelease_d','Vrelease_d_c','Vneed','modTS'});

        end
        
        % Plot the results of optModel
        function plotVQP(obj,modelOut,penalties,Qr,qd_ts)

            qin = obj.qin;
            qd = qd_ts; %obj.qd_ts.Q70;
            pD_d = obj.pD_d;
            pF_d = obj.pF_d;
            discharge = modelOut.Qout;
            volume = modelOut.V;
            vdrought = modelOut.Vrelease_d_c;
            vflood = modelOut.Vrelease_f_c;
            pF = penalties{:,1};
            pD = penalties{:,2};
            
            figure
            t = tiledlayout(3,1);
            title(t,obj.hrbName);
            
            t1 = nexttile;
            title(t1,'Discharge');
            hold on
            q_in = plot(qin.time,qin.Q,'Color','#BABABA');
            q_out = plot(qin.time,discharge,'Color',"#0072BD",'LineStyle','--');
            q_d = plot(qin.time,qd,'Color',"red",'LineStyle','--');
            q_rd = yline(obj.Qr_d,'Color',"red");
            q_r = yline(Qr);
            ylabel('Discharge [m^3/s]');
            legendNames = {"Inflow","Outflow","Drought Threshold","Qcrit","Retention Flow (Qr)"};
            legend(legendNames);
            
            
            t2 = nexttile;
            hold on
            plot(qin.time,volume,'Color','#BABABA');
            fill([qin.time;flip(qin.time)], [volume; flip(zeros(size(volume)))],[0.831 0.831 0.831],'edgecolor','none','FaceAlpha',0.5)
            ylabel('Volume [1000 cbm]');
            yyaxis right
            plot(qin.time,vdrought,'Color',"#0072BD",'LineStyle','--');
            plot(qin.time,vflood,'Color',"#D95319",'LineStyle','--')
            ylabel('Release Volume [1000 cbm]');
            legendNames = {"Reservoir Volume","","Cumulative Drought Release Volume","Cumulative Pre-Flood Release Volume"};
            legend(legendNames);
            title(t2,'Volume');
            
            t3 = nexttile;
            hold on
            plot(qin.time,pD_d,'Color','#BABABA')
            plot(qin.time,pD,'Color',"#0072BD",'LineStyle','--');
            ylabel('Drought Penalty')
            yyaxis right;
            plot(qin.time,pF_d,'Color','#BABABA')
            plot(qin.time,pF,'Color',"#D95319",'LineStyle','--');
            legendNames = {"Default Drought Penalty","Drought Penalty (Qr)","Default Flood Penalty","Flood Penalty (Qr)"};
            legend(legendNames);
            ylabel('Flood Penalty [-]')
            title(t3,'Penalty')
            
            linkaxes([t1 t2 t3],'x')
            
        end

        % Plot the results of floodOptModel
        function plotFloodOptModel(obj,qd_ts)

            qin = obj.qin;
            qd = qd_ts;%obj.qd_ts.Q70;
            pD_d = obj.pD_d;
            pF_d = obj.pF_d;
            Qr_d = obj.Qr_d;
            discharge = obj.qout_od;
            volume = obj.v_od;
            
            figure
            t = tiledlayout(3,1);
            title(t,obj.hrbName);
            
            t1 = nexttile;
            title(t1,'Discharge');
            hold on
            q_in = plot(qin.time,qin.Q,'Color','#BABABA');
            q_out = plot(qin.time,discharge,'Color',"#0072BD",'LineStyle','--');
            q_d = plot(qin.time,qd,'Color',"red");
            q_r = yline(Qr_d);
            ylabel('Discharge [m^3/s]');
            legendNames = {"Inflow","Outflow","Min. Discharge Target","Default Retention Flow (Qr_d)"};
            legend(legendNames);
            
            
            t2 = nexttile;
            hold on
            plot(qin.time,volume,'Color',"#0072BD");
            ylabel('Volume [1000 cbm]');
            ylabel('Release Volume [1000 cbm]');
            legendNames = {"Reservoir Volume"};
            legend(legendNames);
            title(t2,'Volume');
            
            t3 = nexttile;
            hold on
            plot(qin.time,pD_d,'Color',"#0072BD")
            ylabel('Drought Penalty')
            yyaxis right;
            plot(qin.time,pF_d,'Color',"#D95319")
            legendNames = {"Default Drought Penalty","Default Flood Penalty"};
            legend(legendNames);
            ylabel('Flood Penalty [-]')
            title(t3,'Penalty')
            
            linkaxes([t1 t2 t3],'x')

        end

        % Calculate base statistics for cross-reservoir analysis
        function obj = calcBaseStats(obj)
            % n = natural; m = modified (flood-only); o = optimized (flood / drought)
            Qr_d = obj.Qr_d;
            qin = obj.qin.Q;
            results = obj.results;
            qout_m = obj.qout_od;
            qout_o = results{2,2}.Qout;
            qd = obj.qd_ts.Q70;
            pD_d = obj.pD_d;
            pF_d = obj.pF_d;
            pD_o = results{3,2}{:,2};
            pF_o = results{3,2}{:,1};
            modTS = results{2,2}.modTS;
            v_m = obj.v_od;
            v_o = results{2,2}{:,2};
            
            % characterization
            timesteps = zeros(6,1);
            volume = timesteps;
            pen = timesteps;
            
            % drought & flood timesteps
            d_n_ts = find(qin<qd);
            d_m_ts = find(qout_m<qd);
            d_o_ts = find(qout_o<qd);
            
            f_n_ts = find(qin>Qr_d);
            f_m_ts = find(qout_m>Qr_d);
            f_o_ts = find(qout_o>Qr_d);
            
            % drought & flood values at timesteps
            f_n = qin(f_n_ts);
            d_n = qin(d_n_ts);
            f_m = qout_m(f_m_ts);
            d_m = qout_m(d_m_ts);
            f_o = qout_o(f_o_ts);
            d_o = qout_o(d_o_ts);
            
            
            % find # of time steps
            timesteps(1,1) = size(f_n,1);
            timesteps(2,1) = size(d_n,1);
            timesteps(3,1) = size(f_m,1);
            timesteps(4,1) = size(d_m,1);
            timesteps(5,1) = size(f_o,1);
            timesteps(6,1) = size(d_o,1);
            
            % volume [1000 m3]
            volume(1,1) = 3.6*sum(f_n - Qr_d);
            volume(2,1) = 3.6*sum(qd(d_n_ts)-d_n);
            volume(3,1) = 3.6*sum(f_m - Qr_d);
            volume(4,1) = 3.6*sum(qd(d_m_ts)-d_m);
            volume(5,1) = 3.6*sum(f_o - Qr_d);
            volume(6,1) = 3.6*sum(qd(d_o_ts)-d_o);
            
            % penalty
            pF_n = -5*(f_n-Qr_d);
            pD_n = -1./sqrt(d_n)+1./sqrt(qd(d_n_ts));
            pD_n(d_n<0.001)=-1./sqrt(0.001)+1./sqrt(qd(d_n<0.001));
            
            pen(1,1) = sum(pF_n);
            pen(2,1) = sum(pD_n);
            pen(3,1) = sum(pF_d(f_n_ts));
            pen(4,1) = sum(pD_d(d_n_ts));
            pen(5,1) = sum(pF_o(f_n_ts));
            pen(6,1) = sum(pD_o(d_o_ts));
            
            % operation modes
            store = zeros(6,1);
            release = store;
            maintain = store;
            
            % volume stored / released
            storeV = store;
            releaseV = store;
            
            modTS_b = zeros(size(qin));
            for i=1:length(qin)
                
                if qin(i)>Qr_d
                    modTS_b(i) = 1;
            
                elseif qin(i)<qout_m(i)
                    modTS_b(i) = 3;
            
                else
                    modTS_b(i) = 5;
            
                end
            end
            
            % storage
            store(1) = 0;               % natural flood
            store(2) = 0;               % natural drought
            store(3) = sum(modTS_b==1); % modified flood 
            store(4) = 0;               % modified drought 
            store(5) = sum(modTS==1);   % optimized flood
            store(6) = sum(modTS==2);   % optimized drought
            
            % release
            release(1) = 0;
            release(2) = 0;
            release(3) = sum(modTS_b==3);
            release(4) = 0;
            release(5) = sum(modTS==3);
            release(6) = sum(modTS==4)+sum(modTS==6);
            
            % maintain
            maintain(1) = length(qin);
            maintain(2) = 0;
            maintain(3) = sum(modTS_b==5);
            maintain(4) = 0;
            maintain(5) = sum(modTS==5 & v_o==0);
            maintain(6) = sum(modTS==5 & v_o~=0);

            % store / release volumes
            storeV(1) = 0;                          % natural flood
            storeV(2) = 0;                          % natural drought
            storeV(3) = sum(findpeaks(v_m));        % modified flood 
            storeV(4) = 0;                          % modified drought 
            storeV(5) = sum(findpeaks(results{2,2}.Vflood));   % optimized flood
            storeV(6) = sum(findpeaks(results{2,2}.Vstore));   % optimized drought
            
            releaseV(1) = 0;               
            releaseV(2) = 0;               
            releaseV(3) = sum(findpeaks(v_m)); 
            releaseV(4) = 0;               
            releaseV(5) = results{2,2}.Vrelease_f_c(end);   
            releaseV(6) = results{2,2}.Vrelease_d_c(end);  

            % construct table
            rowNames = {'nat_f';'nat_d';'hw_f';'hw_d';'hwnw_f';'hwnw_d'};
            colNames = {'timesteps','volume','penalty','storageTS','releaseTS','maintainTS','storeVol','releaseVol'};
            
            baseStats = table(timesteps,volume,pen,store,release,maintain,storeV,releaseV,'VariableNames',colNames,'RowNames',rowNames);
            obj.baseStats = baseStats;
        end

        % Plot monthly default penalty distributions as ridge plots
        function obj = penaltyRidgePlot(obj)

            figure;
            t = tiledlayout(2,3);
            t.TileSpacing = 'compact';
            pD = obj.pD_d;
            pF = obj.pF_d;
            penalties = [pF,pD];
            monthTS = month(obj.qin.time);
            
            % set up arrays for each month
            jan = penalties(monthTS==1,1:2);
            feb = penalties(monthTS==2,1:2);
            mar = penalties(monthTS==3,1:2);
            apr = penalties(monthTS==4,1:2);
            may = penalties(monthTS==5,1:2);
            jun = penalties(monthTS==6,1:2);
            jul = penalties(monthTS==7,1:2);
            aug = penalties(monthTS==8,1:2);
            sep = penalties(monthTS==9,1:2);
            oct = penalties(monthTS==10,1:2);
            nov = penalties(monthTS==11,1:2);
            dec = penalties(monthTS==12,1:2);
            
            % find range for plotting / calculating bins
            min_vD = min(penalties(:,2));
            lim_vD = [floor(min_vD*2)/2 0];
            edge_vD = linspace(floor(min_vD),0,200);
            
            min_pF = min(penalties(:,1));
            if min_pF==0
                lim_pF = [-30*obj.Qr_d -5*obj.Qr_d];
                edge_pF = linspace(-30*obj.Qr_d,-5*obj.Qr_d,50);
            elseif floor(min_pF) < -5*obj.Qr_d
                lim_pF = [floor(min_pF) -5*obj.Qr_d];
                edge_pF = linspace(floor(min_pF),-5*obj.Qr_d,50);
            else
                lim_pF = [floor(min_pF) 0];
                edge_pF = linspace(floor(min_pF),0,50);
            end
            
            
            %% drought plots
            % find histcounts for each month
            [janCount,~] = histcounts(nonzeros(jan(:,2)),edge_vD,'Normalization','probability');
            [febCount,~] = histcounts(nonzeros(feb(:,2)),edge_vD,'Normalization','probability');
            [marCount,~] = histcounts(nonzeros(mar(:,2)),edge_vD,'Normalization','probability');
            [aprCount,~] = histcounts(nonzeros(apr(:,2)),edge_vD,'Normalization','probability');
            [mayCount,~] = histcounts(nonzeros(may(:,2)),edge_vD,'Normalization','probability');
            [junCount,~] = histcounts(nonzeros(jun(:,2)),edge_vD,'Normalization','probability');
            [julCount,~] = histcounts(nonzeros(jul(:,2)),edge_vD,'Normalization','probability');
            [augCount,~] = histcounts(nonzeros(aug(:,2)),edge_vD,'Normalization','probability');
            [sepCount,~] = histcounts(nonzeros(sep(:,2)),edge_vD,'Normalization','probability');
            [octCount,~] = histcounts(nonzeros(oct(:,2)),edge_vD,'Normalization','probability');
            [novCount,~] = histcounts(nonzeros(nov(:,2)),edge_vD,'Normalization','probability');
            [decCount,~] = histcounts(nonzeros(dec(:,2)),edge_vD,'Normalization','probability');
            
            janCount = [0 janCount];
            febCount = [0 febCount];
            marCount = [0 marCount];
            aprCount = [0 aprCount];
            mayCount = [0 mayCount];
            junCount = [0 junCount];
            julCount = [0 julCount];
            augCount = [0 augCount];
            sepCount = [0 sepCount];
            octCount = [0 octCount];
            novCount = [0 novCount];
            decCount = [0 decCount];
            
            minMonth = [min(jan(:,2));min(feb(:,2));min(mar(:,2));min(apr(:,2));min(may(:,2));min(jun(:,2));min(jul(:,2));min(aug(:,2));min(sep(:,2));min(oct(:,2));min(nov(:,2));min(dec(:,2))];
            data = [janCount',febCount',marCount',aprCount',mayCount',junCount',julCount',augCount',sepCount',octCount',novCount',decCount'];
            tickLabels = {"December","November","October","September","August","July","June","May","April","March","February","January"};
            
            spaceDiv = 30;
            
            spacing = fliplr(linspace(0,11/spaceDiv,12));
            tempOnes = ones(size(edge_vD));
            
            for i=1:12
                data(:,i) = data(:,i)+spacing(i);
            end
            
            maxData = max(max(data));
            
            t1 = nexttile;
            hold on
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,1)*tempOnes,fliplr(spacing(1,1)+janCount)],minMonth(1),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,2)*tempOnes,fliplr(spacing(1,2)+febCount)],minMonth(2),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,3)*tempOnes,fliplr(spacing(1,3)+marCount)],minMonth(3),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,4)*tempOnes,fliplr(spacing(1,4)+aprCount)],minMonth(4),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,5)*tempOnes,fliplr(spacing(1,5)+mayCount)],minMonth(5),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,6)*tempOnes,fliplr(spacing(1,6)+junCount)],minMonth(6),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,7)*tempOnes,fliplr(spacing(1,7)+julCount)],minMonth(7),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,8)*tempOnes,fliplr(spacing(1,8)+augCount)],minMonth(8),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,9)*tempOnes,fliplr(spacing(1,9)+sepCount)],minMonth(9),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,10)*tempOnes,fliplr(spacing(1,10)+octCount)],minMonth(10),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,11)*tempOnes,fliplr(spacing(1,11)+novCount)],minMonth(11),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,12)*tempOnes,fliplr(spacing(1,12)+decCount)],minMonth(12),'FaceAlpha',0.7);
            hold off
            
            xlim(lim_vD)
            ylim([spacing(12) maxData+0.025]);
            yticks(fliplr(spacing));
            yticklabels(tickLabels);
            title(t1,'Drought Penalty Distribution');
            colormap(t1,autumn);
            c = colorbar;
            c.Label.String = 'Maximum Penalty';
            c.Location = 'southoutside';
            
            %% total values of penalty
            
            janD = sum(jan(:,2));
            febD = sum(feb(:,2));
            marD = sum(mar(:,2));
            aprD = sum(apr(:,2));
            mayD = sum(may(:,2));
            junD = sum(jun(:,2));
            julD = sum(jul(:,2));
            augD = sum(aug(:,2));
            sepD = sum(sep(:,2));
            octD = sum(oct(:,2));
            novD = sum(nov(:,2));
            decD = sum(dec(:,2));
            
            janF = sum(jan(:,1));
            febF = sum(feb(:,1));
            marF = sum(mar(:,1));
            aprF = sum(apr(:,1));
            mayF = sum(may(:,1));
            junF = sum(jun(:,1));
            julF = sum(jul(:,1));
            augF = sum(aug(:,1));
            sepF = sum(sep(:,1));
            octF = sum(oct(:,1));
            novF = sum(nov(:,1));
            decF = sum(dec(:,1));
            
            yearD = [janD;febD;marD;aprD;mayD;junD;julD;augD;sepD;octD;novD;decD];
            yearF = [janF;febF;marF;aprF;mayF;junF;julF;augF;sepF;octF;novF;decF];
            
            t2 = nexttile(4);
            plot(1:12,yearD);
            hold on;
            xlim([1 12]);
            ylabel('Drought Penalty [-]');
            title('Total Penalty per Month');
            
            vD = obj.results{2,2}.Vneed;
            monthTS = month(obj.qin.time);
            
            % set up arrays for each month
            jan = vD(monthTS==1);
            feb = vD(monthTS==2);
            mar = vD(monthTS==3);
            apr = vD(monthTS==4);
            may = vD(monthTS==5);
            jun = vD(monthTS==6);
            jul = vD(monthTS==7);
            aug = vD(monthTS==8);
            sep = vD(monthTS==9);
            oct = vD(monthTS==10);
            nov = vD(monthTS==11);
            dec = vD(monthTS==12);
            
            % find range for plotting / calculating bins
            max_vD = max(vD);
            lim_vD = [0 max_vD];
            edge_vD = linspace(0,ceil(max_vD),200);
            
            %% drought plots
            % find histcounts for each month
            [janCount,~] = histcounts(nonzeros(jan),edge_vD,'Normalization','probability');
            [febCount,~] = histcounts(nonzeros(feb),edge_vD,'Normalization','probability');
            [marCount,~] = histcounts(nonzeros(mar),edge_vD,'Normalization','probability');
            [aprCount,~] = histcounts(nonzeros(apr),edge_vD,'Normalization','probability');
            [mayCount,~] = histcounts(nonzeros(may),edge_vD,'Normalization','probability');
            [junCount,~] = histcounts(nonzeros(jun),edge_vD,'Normalization','probability');
            [julCount,~] = histcounts(nonzeros(jul),edge_vD,'Normalization','probability');
            [augCount,~] = histcounts(nonzeros(aug),edge_vD,'Normalization','probability');
            [sepCount,~] = histcounts(nonzeros(sep),edge_vD,'Normalization','probability');
            [octCount,~] = histcounts(nonzeros(oct),edge_vD,'Normalization','probability');
            [novCount,~] = histcounts(nonzeros(nov),edge_vD,'Normalization','probability');
            [decCount,~] = histcounts(nonzeros(dec),edge_vD,'Normalization','probability');
            
            janCount = [0 janCount];
            febCount = [0 febCount];
            marCount = [0 marCount];
            aprCount = [0 aprCount];
            mayCount = [0 mayCount];
            junCount = [0 junCount];
            julCount = [0 julCount];
            augCount = [0 augCount];
            sepCount = [0 sepCount];
            octCount = [0 octCount];
            novCount = [0 novCount];
            decCount = [0 decCount];
            
            maxMonth = [max(jan);max(feb);max(mar);max(apr);max(may);max(jun);max(jul);max(aug);max(sep);max(oct);max(nov);max(dec)];
            data = [janCount',febCount',marCount',aprCount',mayCount',junCount',julCount',augCount',sepCount',octCount',novCount',decCount'];
            tickLabels = {"December","November","October","September","August","July","June","May","April","March","February","January"};
            
            spaceDiv = 30;
            
            spacing = fliplr(linspace(0,11/spaceDiv,12));
            tempOnes = ones(size(edge_vD));
            
            for i=1:12
                data(:,i) = data(:,i)+spacing(i);
            end
            
            maxData = max(max(data));
            
            t3 = nexttile(2);
            hold on
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,1)*tempOnes,fliplr(spacing(1,1)+janCount)],maxMonth(1),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,2)*tempOnes,fliplr(spacing(1,2)+febCount)],maxMonth(2),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,3)*tempOnes,fliplr(spacing(1,3)+marCount)],maxMonth(3),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,4)*tempOnes,fliplr(spacing(1,4)+aprCount)],maxMonth(4),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,5)*tempOnes,fliplr(spacing(1,5)+mayCount)],maxMonth(5),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,6)*tempOnes,fliplr(spacing(1,6)+junCount)],maxMonth(6),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,7)*tempOnes,fliplr(spacing(1,7)+julCount)],maxMonth(7),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,8)*tempOnes,fliplr(spacing(1,8)+augCount)],maxMonth(8),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,9)*tempOnes,fliplr(spacing(1,9)+sepCount)],maxMonth(9),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,10)*tempOnes,fliplr(spacing(1,10)+octCount)],maxMonth(10),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,11)*tempOnes,fliplr(spacing(1,11)+novCount)],maxMonth(11),'FaceAlpha',0.7);
            fill([edge_vD, fliplr(edge_vD)],[spacing(1,12)*tempOnes,fliplr(spacing(1,12)+decCount)],maxMonth(12),'FaceAlpha',0.7);
            hold off
            
            xlim(lim_vD)
            ylim([spacing(12) maxData+0.025]);
            yticks(fliplr(spacing));
            yticklabels([]);
            title(t3,'Deficit Volume Distribution');
            colormap(t3,flipud(autumn));
            c = colorbar;
            c.Label.String = 'Maximum Deficit [1000 m^3]';
            c.Location = 'southoutside';
            
            t2 = nexttile(5);
            
            janD = sum(jan);
            febD = sum(feb);
            marD = sum(mar);
            aprD = sum(apr);
            mayD = sum(may);
            junD = sum(jun);
            julD = sum(jul);
            augD = sum(aug);
            sepD = sum(sep);
            octD = sum(oct);
            novD = sum(nov);
            decD = sum(dec);
            
            yearV = [janD;febD;marD;aprD;mayD;junD;julD;augD;sepD;octD;novD;decD];
            
            plot(1:12,yearV);
            ylabel('Deficit Volume [1000 m^3]')
            xlim([1 12]);
            
            title('Total Deficit per Month');
            
            
            %% flood plots
            % find histcounts for each month
            [janCount,~] = histcounts(nonzeros(jan(:,1)),edge_pF,'Normalization','probability');
            [febCount,~] = histcounts(nonzeros(feb(:,1)),edge_pF,'Normalization','probability');
            [marCount,~] = histcounts(nonzeros(mar(:,1)),edge_pF,'Normalization','probability');
            [aprCount,~] = histcounts(nonzeros(apr(:,1)),edge_pF,'Normalization','probability');
            [mayCount,~] = histcounts(nonzeros(may(:,1)),edge_pF,'Normalization','probability');
            [junCount,~] = histcounts(nonzeros(jun(:,1)),edge_pF,'Normalization','probability');
            [julCount,~] = histcounts(nonzeros(jul(:,1)),edge_pF,'Normalization','probability');
            [augCount,~] = histcounts(nonzeros(aug(:,1)),edge_pF,'Normalization','probability');
            [sepCount,~] = histcounts(nonzeros(sep(:,1)),edge_pF,'Normalization','probability');
            [octCount,~] = histcounts(nonzeros(oct(:,1)),edge_pF,'Normalization','probability');
            [novCount,~] = histcounts(nonzeros(nov(:,1)),edge_pF,'Normalization','probability');
            [decCount,~] = histcounts(nonzeros(dec(:,1)),edge_pF,'Normalization','probability');
            
            janCount = [0 janCount];
            febCount = [0 febCount];
            marCount = [0 marCount];
            aprCount = [0 aprCount];
            mayCount = [0 mayCount];
            junCount = [0 junCount];
            julCount = [0 julCount];
            augCount = [0 augCount];
            sepCount = [0 sepCount];
            octCount = [0 octCount];
            novCount = [0 novCount];
            decCount = [0 decCount];
            
            janCount(isnan(janCount))=0;
            febCount(isnan(febCount))=0;
            marCount(isnan(marCount))=0;
            aprCount(isnan(aprCount))=0;
            mayCount(isnan(mayCount))=0;
            junCount(isnan(junCount))=0;
            julCount(isnan(julCount))=0;
            augCount(isnan(augCount))=0;
            sepCount(isnan(sepCount))=0;
            octCount(isnan(octCount))=0;
            novCount(isnan(novCount))=0;
            decCount(isnan(decCount))=0;
            
            tickLabels = {"December","November","October","September","August","July","June","May","April","March","February","January"};
            minMonth = [min(jan(:,1));min(feb(:,1));min(mar(:,1));min(apr(:,1));min(may(:,1));min(jun(:,1));min(jul(:,1));min(aug(:,1));min(sep(:,1));min(oct(:,1));min(nov(:,1));min(dec(:,1))];
            data = [janCount',febCount',marCount',aprCount',mayCount',junCount',julCount',augCount',sepCount',octCount',novCount',decCount'];
            
            spaceDiv = 10;
            
            spacing = linspace(0,11/spaceDiv,12);
            tempOnes = ones(size(edge_pF));
            
            for i=1:12
                data(:,i) = data(:,i)+spacing(i);
            end
            
            maxData = max(data,[],'all');
            
            t5 = nexttile(3);
            hold on
            fill([edge_pF, fliplr(edge_pF)],[spacing(1,12)*tempOnes,fliplr(spacing(1,12)+janCount)],minMonth(1),'FaceAlpha',0.7);
            fill([edge_pF, fliplr(edge_pF)],[spacing(1,11)*tempOnes,fliplr(spacing(1,11)+febCount)],minMonth(2),'FaceAlpha',0.7);
            fill([edge_pF, fliplr(edge_pF)],[spacing(1,10)*tempOnes,fliplr(spacing(1,10)+marCount)],minMonth(3),'FaceAlpha',0.7);
            fill([edge_pF, fliplr(edge_pF)],[spacing(1,9)*tempOnes,fliplr(spacing(1,9)+aprCount)],minMonth(4),'FaceAlpha',0.7);
            fill([edge_pF, fliplr(edge_pF)],[spacing(1,8)*tempOnes,fliplr(spacing(1,8)+mayCount)],minMonth(5),'FaceAlpha',0.7);
            fill([edge_pF, fliplr(edge_pF)],[spacing(1,7)*tempOnes,fliplr(spacing(1,7)+junCount)],minMonth(6),'FaceAlpha',0.7);
            fill([edge_pF, fliplr(edge_pF)],[spacing(1,6)*tempOnes,fliplr(spacing(1,6)+julCount)],minMonth(7),'FaceAlpha',0.7);
            fill([edge_pF, fliplr(edge_pF)],[spacing(1,5)*tempOnes,fliplr(spacing(1,5)+augCount)],minMonth(8),'FaceAlpha',0.7);
            fill([edge_pF, fliplr(edge_pF)],[spacing(1,4)*tempOnes,fliplr(spacing(1,4)+sepCount)],minMonth(9),'FaceAlpha',0.7);
            fill([edge_pF, fliplr(edge_pF)],[spacing(1,3)*tempOnes,fliplr(spacing(1,3)+octCount)],minMonth(10),'FaceAlpha',0.7);
            fill([edge_pF, fliplr(edge_pF)],[spacing(1,2)*tempOnes,fliplr(spacing(1,2)+novCount)],minMonth(11),'FaceAlpha',0.7);
            fill([edge_pF, fliplr(edge_pF)],[spacing(1,1)*tempOnes,fliplr(spacing(1,1)+decCount)],minMonth(12),'FaceAlpha',0.7);
            hold off
            
            xlim(lim_pF)
            ylim([0 maxData+0.1]);
            yticks(spacing);
            yticklabels([]);
            title(t5,'Flood Penalty Distribution');
            colormap(t5, parula);
            c = colorbar;
            c.Label.String = 'Maximum Penalty';
            c.Location = 'southoutside';
            
            t2 = nexttile(6);
            plot(1:12,yearF);
            xlim([1 12]);
            ylabel('Flood Penalty [-]');
            title('Total Penalty per Month');

            pMonthly = table(yearD,yearF,yearV,'VariableNames',{'Monthly Drought Totals','Monthly Flood Totals','Monthly Deficit Totals'});

            obj.pMonthly = pMonthly;

        end

        % Calculate the worst-case ED; i.e. fastest possible ED
        function obj = calcED(obj)
            Qrd = obj.Qr_d;
            % only concerned about operable volume
            C = obj.Vv - obj.Vd;

            % round up to next integer
            obj.ED = ceil(C/(3.6*Qrd));
        end

        function obj = calcRF(obj)
            % find mean Qin and mean Q70
            mq = mean(obj.qin.Q);
            mnq = min(obj.qd.Q70);
            
            % pull cumulative drought release volume [1000 m3]
            droughtRelease = table2array(obj.results{2,2}(end,6));
            storedV = sum(obj.results{2,2}.Vstore) + sum(obj.results{2,2}.Vflood);

            % pull operating volume
            C = obj.Vv - obj.Vd;

            % find number of years
            days = size(retime(table2timetable(obj.qin),'daily','mean'),1);
            yrs = days/365.25;

            obj.rf = (mq-mnq)*31536/C;      % 31,536,000 s/year -> divide by 1000 bc C is in 1000 m3
            obj.rf_o = storedV/(C*yrs);
            obj.rf_o_d = droughtRelease/(C*yrs);
        end

    end
end



