classdef Analyzer < handle
    
    properties
        AVG;
    end
    
    methods
        function self = Analyzer(channels)
            % get avarage of all signals
            % This should be private, but public now for testing purposes
            self.AVG = zeros(9999, 1);
            
            channels(:, 1) = NaN;
            channels(:, 8) = NaN;
            channels(:, 184) = NaN;
            channels(:, 192) = NaN;
            
            for I = 1:size(channels(:, 1))
                self.AVG(I) = mean(channels(I, :), 'omitnan');
            end
            
            self.AVG = sgolayfilt(self.AVG, 3, 101);
        end
        
        function ret = qrs(self)
            r = self.getR;
            qs = self.getQS;
            ret = self.getQRS(r, qs);
        end
        
        function ret = manualQRS(self)
            ret = self.getManualQRS();
        end
        
    end
    
    methods (Access = private)
        % vanaf hier moet ik gaan beginnen
        function ret = getR(self)
            % get R wave from gradient
            % private
            ecg = sgolayfilt(gradient(self.AVG), 3, 51);
            
            [~, ret] = findpeaks(ecg, 'MinPeakDistance', 200, ...
                'MinPeakHeight', 0.03); % find R peaks 300 samples appart
        end
        % mogelijk heeft dit ook nog verbetering nodig
        function ret = getQS(self)
            % get QS wave from gradient
            % private
            ecg = gradient(sign(gradient(self.AVG)));
            
            ret = find(ecg == -1); % detect Q and S peaks
        end
        
        function ret = getQRS(~, locs_R, locs_QS)
            % returns begin and end of QRS complex
            qrs = zeros(length(locs_R),2); % pre allocate matrix
            
            for I = 1: length(locs_R)
                locs_plus = locs_QS - locs_R(I);
                locs_min = -locs_plus;
                
                locs_plus(locs_plus<0) = Inf;
                locs_min(locs_min<0) = Inf;
                
                [~,xQ] = min(locs_min);
                [~,xS] = min(locs_plus);
                
                % store Q and S locations in qrs
                qrs(I,1:2)= [locs_QS(xQ) locs_QS(xS)];
            end
            
            ret = qrs;
        end
        %%---------------------------------------------------------
        % code jelle, function for analysing the manual qrs markings
        function dataQrs = getManualQRS(location_QRS)
            Qrs = location_QRS;
            
            dataQrs = Qrs;
            
        end
        
        %%---------------------------------------------------------
    end % end methods
    
end % end classdef