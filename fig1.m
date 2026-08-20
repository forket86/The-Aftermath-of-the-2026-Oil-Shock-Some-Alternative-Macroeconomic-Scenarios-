clear; clc; close all;


% This will be used to pull data from Haver
addpath('O:\PROJ_LIB\Presentations\Chartbook\Data\Dataset Creation\cbd');
graphname1 = 'Fig1_1x2';
graphname2 = 'Fig1_singlepanel';
graphname2_png = 'fig1';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WTI Prices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Pull CPI and WTI data from Haver 
start = '1/31/1947';        % start date for all series
end_date = eomdate(today);
wtidata = cbd.data({'PCU@USECON','PCUSLE@USECON', 'PZTEXP@USECON'}, 'startDate', start, 'endDate', end_date);


%% Format data
wtidata{{'31-Oct-2025'},1}=sqrt(wtidata{{'30-Nov-2025'},1}.*wtidata{{'30-Sep-2025'},1}); % Interpolate october CP
wtidata(sum(isnan(wtidata{:,:}),2)>0,:)=[];   % get rid of any row that contains NaN
wtidates = datetime(datenum(cell2mat(wtidata.Properties.RowNames)), ...
    'ConvertFrom','datenum');
wtidata.PCU = wtidata.PCU*(100/(wtidata{{'31-Dec-2025'},1})); % Jan 2025 = 100
wtidata.PCUSLE = wtidata.PCUSLE*(100/(wtidata{{'31-Dec-2025'},2})); % Jan 2025 = 100
wtidata.WTI_REAL_CPI = wtidata.PZTEXP.*(100./wtidata.PCU);
wtidata.WTI_REAL_CPILE = wtidata.PZTEXP.*(100./wtidata.PCUSLE);
wtidata.WTI_NOM = wtidata.PZTEXP;

% Convert to annual
%convert2annual(wtidata)
%wtidata.DATE = datetime(cell2mat(wtidata.Properties.RowNames));
%data = table2timetable(wtidata,'RowTimes', "DATE")
%data.Row = cell2mat(data.Row)
%convert2monthly(data, 'Aggregation','lastvalue')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Barrels Consumed (Real)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%  FRED Pull: GDPA
% Build URL
api_key = '540b4512e6afae7030a5bc8e4f8b1d89';
series_ids = {'GDPA', 'GDPCA', 'A191RG3A086NBEA', 'A191RD3A086NBEA'};
series_names = {'GDPA', 'GDPCA', 'GDP_PI', 'GDPDEF'};
fred = struct();

for i = 1:numel(series_ids)
    series_id = series_ids{i};

    url = sprintf(['https://api.stlouisfed.org/fred/series/observations?' ...
               'series_id=%s&api_key=%s&file_type=json'], ...
               series_id, api_key);

    % Fetch data
    data = webread(url);
    obs = data.observations;
    dates_str = {obs.date}';
    values_str = {obs.value}';
    values = str2double(values_str);
    dates = datetime(dates_str, 'InputFormat', 'yyyy-MM-dd');
    fred(i).data = renamevars(table(dates, values), ["values", "dates"], [string(series_names{i}), "Date"]); 
end

% Read in EIA Data
petdata = readtable('./data_raw/petroleum_consumption_ann.xls', 'Sheet', 'Data');
petdata.Date = datetime(year(petdata.Date), 1,1);

% Merge
consdata = outerjoin(fred(1).data, petdata, "Keys", "Date", "Type", "right", "MergeKeys",true); % Merge nom GDP data
consdata = outerjoin(consdata, fred(2).data, "Keys", "Date", "Type", "left", "MergeKeys",true ); % Merge real GDP data
consdata = outerjoin(consdata, fred(3).data, "Keys", "Date", "Type", "left", "MergeKeys",true ); % Merge GDP PI data
consdata = outerjoin(consdata, fred(4).data, "Keys", "Date", "Type", "left", "MergeKeys",true ); % Merge GDP QI data

% Rebase Real GDP (2025 = 100)
consdata.GDPDEF = (consdata.GDPDEF./consdata.GDPDEF(consdata.Date == "01-Jan-2025")).*100;
consdata.REAL_GDP = consdata.GDPA.*100./consdata.GDPDEF;

% Variables for plotting
consdata = renamevars(consdata, "U_S_ProductSuppliedOfCrudeOilAndPetroleumProducts_ThousandBarrelsPerDay_", "Petroleum Consumption (Daily)");
consdata.("Petroleum Consumption (Yearly)") = 365*consdata.("Petroleum Consumption (Daily)")
consdata.("b_per_gdp") = (consdata.("Petroleum Consumption (Yearly)").*1000)./(consdata.GDPA.*1e6); % Barrels / GDP (thousands USD)
consdata.("b_per_rgdp") = (consdata.("Petroleum Consumption (Yearly)").*1000)./(consdata.REAL_GDP.*1e6); % Barrels / GDP (thousands USD)







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figure 1 (Same Plot)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
date_beg = datetime(1970, 01, 01);

figure()
hold on;

yyaxis left
% Real WTI Price Series
l1 = plot(wtidates, wtidata.WTI_REAL_CPI, 'LineWidth', 1, 'Color', "#5D9EDA");
ylleft=ylabel('2025 U.S. dollars per barrel of oil', 'FontSize', 7);
set(ylleft, 'Units', 'Normalized', 'Position', [0 1.005], 'HorizontalAlignment', 'left', 'Rotation', 0)
ylim([0 210])
ax = gca;
ax.YColor = "black";

yyaxis right
% Barrels consumed per unit of GDP
l2 = plot(consdata.Date, consdata.b_per_rgdp, 'LineWidth', 1, 'Color', '#8E0000');
ylright=ylabel('barrels per thousands of 2025 U.S. dollars', 'FontSize', 7, 'Rotation', 0);
set(ylright, 'Units', 'Normalized', 'Position', [1 1.03], 'HorizontalAlignment', 'right')
ax = gca;
ax.YColor = "black";


yline(0, 'k--', 'LineWidth', 0.5);
datetick('x', 'yyyy', 'keepticks');
grid off;
legend([l1 l2], ["Real domestic oil spot price: West Texas Intermediate (left-hand scale)", "Domestic petroleum and crude oil consumption (right-hand scale)"], ...
                'Location', 'southoutside', 'FontSize', 9, 'Box', 'off')
set(gca, 'FontName', 'Arial');
xlim([date_beg, wtidates(end)]);

set(gcf, 'Position', [100, 100, 800, 550]); 
fig = gcf;
fig.Units = 'inches';
pos = fig.Position; % Gets [left bottom width height]
fig.PaperPositionMode = 'manual';
fig.PaperSize = [pos(3) pos(4)]; 
fig.PaperPosition = [0 0 pos(3) pos(4)];
%set(gcf, 'PaperOrientation', 'landscape');

% Change Formatting of xticks
curxticks = xticks;
curxticks_str = string(curxticks(curxticks >= date_beg));
xticks_formatted = cellstr(curxticks_str);
xticks_formatted = cell2mat(cellfun(@(s) strcat("'", s(3:4)), xticks_formatted, 'Uniformoutput', false));
xticks_final = [string(curxticks(curxticks < date_beg)) ...
                curxticks_str(1) ...
                xticks_formatted(2:(find(curxticks_str=="2000") - 1)) ...
                curxticks_str((find(curxticks_str=="2000"))) ...
                xticks_formatted((find(curxticks_str=="2000") + 1):length(xticks_formatted))];
xticklabels(xticks_final)


% Save figure
print(gcf, ['./figures_png/' graphname2_png '.png'],'-dpng');



%%%% Print Change in Oil Price from Monthly WTI (1979):
wtichanges = [];
date_beg = datetime(1979, 04, 30);
for q = 1:20
    nowdate = dateshift(date_beg + calmonths(q*3), 'end', 'month');
    wtichanges(q) = ((wtidata{wtidates == nowdate, ["WTI_REAL_CPI"]}./wtidata{wtidates == date_beg, ["WTI_REAL_CPI"]}) - 1)*100;
end

wtichangestable = table((1:20)', wtichanges','VariableNames', ["Quarter", "WTI Change"])
writetable(wtichangestable, './data_created/wtichanges_seventies.csv', 'WriteVariableNames',true)
