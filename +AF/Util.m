classdef Util
  % fragments signal and analyse the two different framents
  
  methods (Static)
    
    function ret = regions(locations, length_)
      % Create AF_Util with qrs location and signal length
      ecg = false(length_, 1);
      
      for I = 1:length(locations)
        ecg(locations(I, 1): locations(I, 2)) = true;
      end
      
      ret = ecg; % set frames where there is a qrs signal to true
    end
    
    function ret = split(data, qrs)
      % Split data in to two, where one contain signal without QRS periods
      % and one with only the QRS periods
      QRS = data;
      signal = data;
      QRS(~qrs) = NaN;
      signal(qrs) = NaN;
      
      ret = struct('qrs', QRS, 'signal', signal);
    end
    
    function ret = fragment(data, region)
        if region(2) <= length(data)
            ret = data(region(1): region(2));
        else
            ret = data(region(1):end);
        end
    end
    
    function ret = sensitivity(pks_Level)
      % calculate avg slope speed for a given signal. Returns the average
      % and the standard deviation.
      avg = median(pks_Level);
      sigma = std(pks_Level);
      
      ret = struct('mean', avg, 'std', sigma);
    end
    
    function ret = grouping(data, location)
      % Find points that belongs to the same slope and grouped them
      % together and return the group points
      filt = sgolayfilt(data, 7, 23); % remove unwanted noise
      
      A = @(x) location(x) - location(x - 1);
      D = @(x) diff(sign(diff(filt(location(x - 1):location(x)))));
      
      ret = cell(length(location), 1);
      % for loop vars
      N = 1; % cell index
      K = 1; % column index
      S = true; % state, prevent empty cells
      
      for I = 2:length(location)
        value = ~any(abs(D(I))); % true if graph changes direction
        
        if value && A(I) < 30
          ret{N}(K) = I - 1; % store points index as group in cell
          K = K + 1;
          S = false;
        else
          if ~S
            ret{N}(K) = I - 1;
            N = N + 1;
            K = 1;
          end
          
          S = true;
        end
      end
      
      ret(cellfun('isempty', ret)) = [];
    end
    
    function ret = points(location, velocity, groups)
      % ret the single points of slopes, if there more than one the mean of
      % group
      C = @(x, N) any(x == groups{N}); % x in groups, returns bool...
      
      I = 1;
      k = 1;
      n = 1;
      
      points_ = repmat(struct, length(location)-(length(groups) + 1), 1);
      while I <= length(location)
        % reduce vector
        if isempty(groups) || ~C(I, n)
          % if index not in groups
          points_(k).location = location(I);
          points_(k).velocity = velocity(I);
          I = I + 1;
        else
          % return mean of group points
          points_(k).location = round(mean(location(groups{n})));
          points_(k).velocity = mean(velocity(groups{n}));
          I = groups{n}(end) + 1;
          
          if n < length(groups)
            n = n + 1;
          end
        end
        
        k = k + 1;
      end
      
      % TODO: remove empty structs
      ret = points_;
    end
    
    function ret = correction(data, location, velocity)
      % Correct markings that are part of the same deflaction
      % uses functions grouping and points
      groups = AF.Util.grouping(data, location);
      ret = AF.Util.points(location, velocity, groups);
    end
    
  end
  
end % end classdef