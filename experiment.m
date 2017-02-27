patient = E01.Reader('F:\Marshall Croes/data/RA_chronic_AF/02_CAF_RAFW_123.EEE');
% patient = E01.Reader('F:\Marshall Croes\data\AF\Hovig_20_10_14_AF_BB0.E01');
qrs     = QRS.Analyzer(patient.all);
locs    = qrs.qrs;
regions = AF.Util.regions(qrs.qrs, length(qrs.qrs));

filt = sgolayfilt(patient.get(21), 7, 11);
ff = sgolayfilt(patient.get(21), 7, 17);
orig  = AF.Util.split(filt, regions);
data  = AF.Util.split(ff, regions);
data2 = AF.Util.split(qrs.AVG, regions);

region = locs(7, :);
% check for any change of direction
avg_points = diff(sign(gradient(data2.qrs(region(1):region(2))))); 
cur_points = diff(sign(gradient(data.qrs(region(1):region(2)))));
cur_points(cur_points == -1) = 0;
cur_points(cur_points == 1) = 0;

[~, pks] = findpeaks(-gradient(orig.qrs(region(1):region(2))),...
        'MinPeakHeight', .05,...
        'MinPeakDistance', 4);

% get index of changes that goes up and down
up_point = find(avg_points == 2);
down_point = find(avg_points == -2);

% get all the changes
up_locs = find(cur_points == 2);
down_locs = find(cur_points == -2);

% find closest match
closest = @(x, c) min(abs(x - c));
[~, match_up] = closest(up_locs, up_point);
[~, match_down] = closest(down_locs, down_point);

% up_locs = up_locs(up_locs < up_locs(match_up));
% down_locs = 

% disp(any(pks < up_locs(match_up)));
% disp(any(down_locs < up_locs(match_up)));
deltaY = patient.getY(21, region(1))- patient.getY(21, region(1)+up_locs(match_up));


for I = 1:length(down_locs(down_locs < up_locs(match_up)))
  deltaY = patient.getY(21, region(1)+down_locs(I)) - patient.getY(21, region(1)+up_locs(match_up));
%   disp(deltaY);
%   deltaY = patient.getY(21, region(1))- patient.getY(21, region(1)++down_locs(I));
%   disp(deltaY);
end

pks(pks < up_locs(match_up) & pks > 0) = [];
pks(pks > down_locs(match_down+1) & pks < length(avg_points)) = [];


% point = mean(locations(1:2));
% calculate velocity of slope
% cache = region(1)+locations(1)+6;
% deltaX = region(1)+locations(1)-2 - region(1)+locations(2)-6;
% deltaY = patient.getY(21, region(1)+locations(1)-2) - patient.getY(21, region(1)+locations(2)-4);
% velocity = deltaY/deltaX;
figure(1)
plot(avg_points./4, 'g');  hold on;
plot(pks(isfinite(pks)), orig.qrs(region(1)+pks(isfinite(pks))-1), 'rx');
plot(cur_points./4, 'r');
% plot(gradient(orig.qrs(region(1):region(2))), 'r');
plot(orig.qrs(region(1):region(2))); hold off;
% plot(orig.qrs);
ylim([-1 1]);
xlim([0 100]); pan('xon');