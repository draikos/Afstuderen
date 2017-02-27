classdef Reader < handle
  properties
    channels; % int
    signals;
  end % end properties

  methods
    function self = Reader(filename)
      % AF_Signal reads an .E10 file and saves the body in a matrix and the
      % total channels in a variable.
      if ~ischar(filename)
        error('Error. File name must be a string');
      end

      fid = fopen(filename, 'r', 'l'); % Get file id

      if fid == -1
        error('Error. File can not be found');
      else
        head          = fread(fid, 4608, 'char'); % Reads E10 header
        body          = fread(fid, [256 20000], 'int16'); % Reads E10 body
        self.channels = str2double(char(head(1702:1704)')); % Total channels used
        
        try
          calibratie    = max(gradient(body(self.channels, :)));
          self.signals  = body(1:192,:)' ./ calibratie;
        catch
          self.signals  = body(1:192,:)' ./ 2500; % Signals stored in matrix
        end
      end
    end

    function ret = get(self, channel, sizeT, start)
      % Get returns a vector. 
      % Arguments:
      % channel - choose which channel
      % sizeT - sample size of vector, default maximum
      % start - start point of vector, default first
      switch nargin
      case 2
        ret = self.signals(:, channel);
      case 3
        ret = self.signals(1:sizeT, channel);
      case 4
        ret = self.signals(1 + start:start + sizeT, channel);
      otherwise
        ret = 0;
      end
    end

    function ret = getY(self, channel, location)
      % getY return a single point in the matrix signal
      ret = self.signals(location, channel);
    end

    function ret = size(self)
      % size returns the size of matrix
      ret = self.channels;
    end

    function ret = all(self)
      % all returns all signal in a matrix
      ret = self.signals;
    end

  end % end methods
  
end % end classdef
