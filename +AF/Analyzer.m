classdef Analyzer < handle
    
    properties
        locations;
        regions;
        points
    end
    
    methods
        
        function self = Analyzer(locations, length_)
            self.locations = locations;
            self.regions   = AF.Util.regions(locations, length_);
            warning('off', 'signal:findpeaks:largeMinPeakHeight');
        end
        
        function ret = all(self, data, varargin)
            p = inputParser;
            p.addParameter('SlopeTreshold', .025, @isnumeric);
            p.addParameter('QrsTreshold'  , .1  , @isnumeric);
            p.addParameter('AmpTreshold'  , .5  , @isnumeric);
            p.parse(varargin{:});
            
            filt = sgolayfilt(data, 7, 23);
            
            % TODO: fix horzcat/vertcat
            normal = self.find_slopes(data, p.Results.SlopeTreshold, 'normal');
            % -------- Experimental ---------
            qrs    = self.special(data, p.Results.QrsTreshold);
            
            try
                self.points = [normal; qrs];
            catch
                try
                    self.points = [normal; qrs'];
                catch
                    self.points = [normal'; qrs];
                end
            end
            
            if ~isempty(self.points)
                [~, order]  = sort([self.points.location]);
                self.points = self.points(order);
            end
            % -------- Experimental ---------
            
            for I = 1:length(self.points)
                self.points(I).duration  = self.length_slope(filt, data,...
                    self.points(I).location);
                self.points(I).amplitude = self.amplitude_slope(data,...
                    self.points(I).duration);
            end
            
            if(~isempty(self.points))
                ret = self.points(...
                    [self.points.amplitude] > p.Results.AmpTreshold);
            else
                ret = [];
            end
        end
        
        % differnatiate from qrs slope and artial signal
        function ret = special(self, data, t)
            % TODO: Improve this function!
            % TODO: debug and fix issue causing that some area signal are not
            % being detected!
            
            filt = data;%sgolayfilt(data, 7, 23);
            locs = self.find_slopes(data, t, 'qrs');
            
            % iterate over fragments and flag points
            if ~isempty(locs)
                for I = 1:length(self.locations);
                    region = self.locations(I, :);
                    area   = AF.Util.fragment(filt, region);
                    tmp    = locs([locs.location] > region(1) & [locs.location] < region(2));
                    
                    if ~isempty(tmp)
                        % if not empty then analyse otherwise skip!...
                        % search for any change of direction in region
                        changes = diff(sign(gradient(area)));
                        
                        % get total the changes
                        occurance = find(changes == -2);
                        
                        if length(occurance) > 1
                            try
                                ret = [ret; tmp];
                            catch
                                ret = tmp;
                            end
                        end
                    end
                end % for
            else
                ret = [];
            end
            
        end % function
        
        % Find the negatives deflection in current signal
        function ret = find_slopes(self, data, treshold, area)
            %       filt = sgolayfilt(data, 7, 11);
            % TODO: Fix issue that causes certain slope to not be detected
            frag = AF.Util.split(data, self.regions);
            
            if strcmp(area, 'qrs')
                [vel, pks] = findpeaks(-gradient(frag.qrs),...
                    'MinPeakHeight', treshold,...
                    'MinPeakDistance', 4);
            else
                [vel, pks] = findpeaks(-gradient(frag.signal),...
                    'MinPeakHeight', treshold,...
                    'MinPeakDistance', 4);
            end
            
            if ~isempty(pks)
                ret = AF.Util.correction(data, pks, vel);
            else
                ret = [];
            end
        end
        
        % Get deflection length by finding the top and bottom of slope
        function ret = length_slope(self, data_f, data_o, x)
            %       ff = sgolayfilt(data, 7, 17);
            
            if ~isempty(x)
                if ~isempty(self.points)
                    p_point = [self.points([self.points.location] < x).location];
                    n_point = [self.points([self.points.location] > x).location];
                end
                
                try
                    if ~isempty(p_point)
                        p_point = max(p_point);
                    else
                        p_point = 1;
                    end
                    
                    if ~isempty(n_point)
                        n_point = min(n_point);
                    else
                        n_point = length(data_o);
                    end
                catch
                    p_point = 1;
                    n_point = length(data_o);
                end
                
                change_direction   = diff(sign(diff(data_f)));
                b_change_direction = diff(sign(diff(data_o)));
                
                ups     = find(change_direction   ==  2);
                b_ups   = find(b_change_direction ==  2);
                downs   = find(change_direction   == -2);
                b_downs = find(b_change_direction == -2);
                
                % make filter corrections
                % TODO: Test if works and optimize
                tmp_t   = max(downs(downs < x));
                b_downs = b_downs(b_downs <= x & b_downs > p_point);
                if ~isempty(b_downs)
                    try
                        downs_diff = abs(b_downs - tmp_t);
                        [~, xd] = min(downs_diff);
                        top = b_downs(xd) + 1;
                    catch
                        top = min(b_downs);
                    end
                else
                    top = tmp_t;
                end
                
                tmp_b = min(ups(ups > x));
                b_ups = b_ups(b_ups >= x & b_ups < n_point);
                if ~isempty(b_ups)
                    try
                        ups_diff = abs(b_ups - tmp_b);
                        [~, xu] = min(ups_diff);
                        bottom = b_ups(xu) + 1;
                    catch
                        bottom = min(b_ups);
                    end
                    % TODO: fix empty tmp_b that causes error msg.
                else
                    bottom = tmp_b;
                end
                
                ret = [top bottom];
            else
                ret = [];
            end
        end
        
        % Get deflection amplitude
        function ret = amplitude_slope(~, data, x)
            if length(x) < 2
                ret = [];
                return;
            end
            
            ret = data(x(1)) - data(x(2));
        end
        
        function ret = seeker(self, data, x)
            % seeks top and bottom of selected slope then calculate the negative
            % gradient and return location duration and amplitude
            filt = sgolayfilt(data, 7, 23);
            
            duration = self.length_slope(filt, data, x);
            amplitude = self.amplitude_slope(data, duration);
            [velocity, location] = findpeaks(-gradient(data(duration(1):duration(2))));
            
            [~, idx] = max(velocity);
            
            ret = struct;
            ret.location = duration(1) + location(idx);
            ret.velocity = velocity(idx);
            ret.duration = duration;
            ret.amplitude = amplitude;
        end
        
    end % end methods
    
end % end classdeff
