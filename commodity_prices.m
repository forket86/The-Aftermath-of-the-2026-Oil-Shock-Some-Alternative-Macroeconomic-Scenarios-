clear; clc; close all;


% This will be used to pull data from Haver
addpath('O:\PROJ_LIB\Presentations\Chartbook\Data\Dataset Creation\cbd');
graphname2 = 'COMM_PRICES';
graphname3 = 'WTI_FUTURES_PRICES';




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot: Prices of Other Commodities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
prices = readtable('./data_raw/commodityprices.csv');
seriesinfo = readtable('./data_raw/commodities_info.xlsx');


seriesnames = {strcat("NGUSHHUB Comdty"), ...
               strcat("GCFPURGB Index"), ...
               strcat("GCFPAMNB Index"), ...
               strcat("GCFPSRTC Index"), ...
               strcat("GCFPDANO Index")};

seriestickers = strcat("TICKER, ", string(seriesnames));


titles = {"Natural Gas", ...
          "Urea (Fertilizer)", ...
          "Ammonia (Fertilizer)",...
          "Sulfur (Fertilizer)",...
          "DAP (Fertilizer)" };


tiledlayout(3, 2, 'TileSpacing','loose')
g = 0;
lw = 1.5;
fs = 12;

for i = 1:numel(seriesnames)
    data = prices(prices.IDENTIFIER == seriesnames{i}, ["DATE", "PX_LAST"]);
    nexttile(g+1); hold on;

    plot(data.DATE, data.PX_LAST, 'LineWidth', lw)
    xline(datetime(2026, 02, 28), '--k', 'LineWidth', 0.5)
    xlim([max(datetime(2019, 1, 1), data.DATE(1)), data.DATE(end)])

    title(titles{i})
    subtitle(seriesinfo{strcmp(seriesinfo.BloombergName, seriestickers{i}), "Description"});
    xlabel("Date")
    ylabel(seriesinfo{strcmp(seriesinfo.BloombergName, seriestickers{i}), "Unit"});
    increase_pct = (data.PX_LAST(end)./data.PX_LAST(find(data.DATE <= datetime(2026, 02, 28), 1, 'last'))) - 1;
    text(data.DATE(end), data.PX_LAST(end), sprintf("%.1f%% increase", increase_pct*100), 'FontSize', 8)
    g = g + 1;
end



% Format
set(gcf, 'PaperOrientation', 'landscape');

% Save
%print(gcf, ['./figures_pdf/pricedata/' graphname2 '.pdf'],'-dpdf');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot: WTI Futures (at different points in time)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

date_comp = prices{(prices.DATE <= datetime(2026, 02, 28)) & (prices.IDENTIFIER == "CL1 Comdty"), ["DATE"]}(end);
date_mar = prices{(prices.DATE <= datetime(2026, 03, 31)) & (prices.IDENTIFIER == "CL1 Comdty"), ["DATE"]}(end);
date_apr = prices{(prices.DATE <= datetime(2026, 04, 30)) & (prices.IDENTIFIER == "CL1 Comdty"), ["DATE"]}(end);
date_may = prices{(prices.DATE <= datetime(2026, 05, 31)) & (prices.IDENTIFIER == "CL1 Comdty"), ["DATE"]}(end);
date_now = prices{(prices.DATE <= datetime(2026, 06, 22)) & (prices.IDENTIFIER == "CL1 Comdty"), ["DATE"]}(end);
date_last_list = datetime(2026, 03, 31) + calmonths(0:3);
intervals = [1:60]; % Futures dates available in data
wtifuturesnow = NaN(numel(intervals), numel(date_last_list));
wtifuturescomp = NaN(numel(intervals), 1);
calendar_dates = NaT(numel(intervals), numel(date_last_list));


for k = 1:numel(date_last_list)
    date_last = prices{(prices.DATE <= date_last_list(k)) & (prices.IDENTIFIER == "CL1 Comdty"), ["DATE"]}(end);
    
    for j = 1:numel(intervals)
        i = intervals(j);
        wtifuturesname = strcat("CL", string(i), " Comdty");
        wtifuturesnow(j, k) = prices{(prices.DATE == date_last) & (prices.IDENTIFIER == wtifuturesname), ["PX_LAST"]};

        % Find February (comparison) futures price levels.
        % Only needs to be executed once
        if k == 1
            wtifuturescomp(j) = prices{(prices.DATE == date_comp ) & (prices.IDENTIFIER == wtifuturesname), ["PX_LAST"]};
        end
        
        % Calendar date associated with each entry in wtifuturesnow
        calendar_dates(j, k) = eomdate(date_last) + calmonths(i - 1);

    end
end

wtifutureschange = (wtifuturesnow./wtifuturescomp - 1)*100;


% Get realized values
wtispots =    [prices{(prices.DATE == date_mar) & (prices.IDENTIFIER == "CL1 Comdty"), ["PX_LAST"]}, ...
               prices{(prices.DATE == date_apr) & (prices.IDENTIFIER == "CL1 Comdty"), ["PX_LAST"]}, ...
               prices{(prices.DATE == date_may) & (prices.IDENTIFIER == "CL1 Comdty"), ["PX_LAST"]}, ...
               prices{(prices.DATE == date_now) & (prices.IDENTIFIER == "CL1 Comdty"), ["PX_LAST"]}];
wtispotcomp = prices{(prices.DATE == date_comp) & (prices.IDENTIFIER == "CL1 Comdty"), ["PX_LAST"]};
wtispotschg = ((wtispots ./ wtispotcomp) - 1)*100;



figure(); hold on;
for i = 1:4
    plot(calendar_dates(:, i), wtifutureschange(:, i), 'LineWidth', 2) % Expectations at each date
end
plot(calendar_dates(1:4, 1), wtispotschg, 'LineWidth', 2, 'Color', 'Black', 'LineStyle', '--') % Realized prices
legend([string(date_last_list, 'MMM yyyy'), "Realized Price"], 'Location', 'southoutside')
title("Futures Price Trajectories, EOM March/April/May/June")
ylabel("Price Change since 02/27")
saveas(gcf, 'figures_png/wti_expectations.png')



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Table: WTI Expectations as of March
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

marchWTIexp = table(calendar_dates(:, 1), wtifutureschange(:, 1), 'VariableNames', {'Date', 'wtifutures_change'});
marchWTIexp.modelquarter = [1, floor((0:(size(marchWTIexp, 1) - 2)) ./ 3) + 2]';
writetable(groupsummary(marchWTIexp, 'modelquarter', 'mean', 'wtifutures_change'), ...
           './data_created/wtifutures_exp_March.csv', 'WriteVariableNames',true)



%{

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Table 1: WTI Futures (for Model Oil Price Calibration)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
date_comp = prices{(prices.DATE <= datetime(2026, 02, 28)) & (prices.IDENTIFIER == "CL1 Comdty"), ["DATE"]}(end);
wtifuturesname = "CL1 Comdty";
date_mar = prices{(prices.DATE <= datetime(2026, 03, 31)) & (prices.IDENTIFIER == "CL1 Comdty"), ["DATE"]}(end);
date_apr = prices{(prices.DATE <= datetime(2026, 04, 30)) & (prices.IDENTIFIER == "CL1 Comdty"), ["DATE"]}(end);
date_may = prices{(prices.DATE <= datetime(2026, 05, 31)) & (prices.IDENTIFIER == "CL1 Comdty"), ["DATE"]}(end);
date_now = prices{(prices.DATE <= datetime(2026, 06, 22)) & (prices.IDENTIFIER == "CL1 Comdty"), ["DATE"]}(end);
wtispots =    [prices{(prices.DATE == date_mar) & (prices.IDENTIFIER == wtifuturesname), ["PX_LAST"]}, ...
               prices{(prices.DATE == date_apr) & (prices.IDENTIFIER == wtifuturesname), ["PX_LAST"]}, ...
               prices{(prices.DATE == date_may) & (prices.IDENTIFIER == wtifuturesname), ["PX_LAST"]}];
wtispotcomp = prices{(prices.DATE == date_comp) & (prices.IDENTIFIER == wtifuturesname), ["PX_LAST"]};
wtispotschg = ((wtispots ./ wtispotcomp) - 1)*100;

% Get spot price change as of latest date (for comparison)
wtispotnow = prices{(prices.DATE == date_now) & (prices.IDENTIFIER == wtifuturesname), ["PX_LAST"]} ;
wtispotchgnow = ((wtispotnow ./ wtispotcomp) - 1)*100;



% Grab current and historic futures prices
date_last = prices.DATE(end);
intervals = [1:60]; % Futures dates available in data

wtifuturesnow = []; wtifuturescomp = [];
for j = 1:numel(intervals)
    i = intervals(j);
    wtifuturesname = strcat("CL", string(i), " Comdty");
    wtifuturesnow(j) = prices{(prices.DATE == date_last) & (prices.IDENTIFIER == wtifuturesname), ["PX_LAST"]};
    wtifuturescomp(j) = prices{(prices.DATE == date_comp ) & (prices.IDENTIFIER == wtifuturesname), ["PX_LAST"]};
end

% Compare change, store data for model
wtifutureschange = (wtifuturesnow./wtifuturescomp - 1)*100;
wtipricetable = table(["March Delta CL1"; "April Delta CL11"; "May Delta CL1"; strcat("June Delta CL", string(intervals'))], ...
                      [wtispotschg wtifutureschange]', 'VariableNames', ["source", "wtifutures_change"]);

wtipricetable.modelquarter = [1, floor((0:(size(wtipricetable, 1) - 2)) ./ 3) + 2]';
writetable(groupsummary(wtipricetable, 'modelquarter', 'mean', 'wtifutures_change'), ...
           'wtifutures_change.csv', 'WriteVariableNames',true)
writetable(wtipricetable, 'wtifutures_change_monthly.csv', 'WriteVariableNames', true)
%}