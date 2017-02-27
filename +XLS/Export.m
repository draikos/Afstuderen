classdef Export < handle
  %EXPORT Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    data;
    info;
    path;
    Excel;
    Workbook;
  end
  
  methods
    function self = Export(data, info)
      self.data = data;
      self.info = info;
    end
    
    function to(self)
      [name, path_] = uiputfile(...
        {'*.xls'; '*.xlsx'},...
        'Export to excel',...
        self.info);
      
      if ~isempty(self.data) && ischar(name)
        copyfile('+XLS/template.xlsx', [path_ name], 'f');
        self.path = [path_ name];
        
        try
          self.Excel    = actxserver('Excel.Application');
          self.Workbook = self.Excel.Workbooks.Open(self.path);
        catch
          % TODO: give warning that there are no excel program on system
          msgbox('Exscel is not installed', 'Error', 'Error');
          return;
        end
        
        wbar = waitbar(0, 'saving file...');
        
        try
            for I = 1:5
                self.arrange(I);
                waitbar(I/5, wbar);
            end
            
            self.cleanup;
            delete(wbar);
        catch exception
            self.cleanup;
            delete(wbar);
            msgText = getReport(exception);

            msgbox(msgText, 'Error', 'Error');
        end
      end
    end
    
    function arrange(self, x)
%       length_ = 2:192; % length(self.data);
%       tmp = cell(192,1);
      
      switch x
        case 1
          self.overview;
        case 2
%           xlswrite(self.path, length_', x, 'a2');
          for I = 1:length(self.data)
            if ~isempty(self.data{I})
              tmp = [self.data{I}.location];
              self.working('LAT', 1, length(tmp), tmp, 'B', I);
            end
          end
        case 3
%           xlswrite(self.path, length_', x, 'a2');
          for I = 1:length(self.data)
            if ~isempty(self.data{I})
              tmp = [self.data{I}.amplitude];
              self.working('Amplitudes', 1, length(tmp), tmp, 'B', I);
            end
          end
        case 4
%           xlswrite(self.path, length_', x, 'a2');
          for I = 1:length(self.data)
            if ~isempty(self.data{I})
              tmp = diff([self.data{I}.duration]);
              tmp = tmp(1:2:length(tmp));
              self.working('Duration', 1, length(tmp),...
                tmp, 'B', I);
            end
          end
        case 5
%           self.working('Slope', 192, 1, length_', 'A', 2);
          for I = 1:length(self.data)
            if ~isempty(self.data{I})
              tmp = [self.data{I}.velocity];
              self.working('Slope', 1, length(tmp), -tmp, 'B', I);
            end
          end
      end
    end
    
    function overview(self)
      for I = 2:length(self.data)
        if ~isempty(self.data{I})
          amp = mean([self.data{I}.amplitude]);
          dur = mean(diff([self.data{I}.duration]));
          slp = -mean([self.data{I}.velocity]);
          int = mean(diff([self.data{I}.location]));
          tot = length(self.data{I});
          
%           tmp = zeros(length([self.data{I}.location]), 1);
%           for J = 1:length([self.data{I}.location])
%               tmp(J) = self.data{I}(J).duration(2) - self.data{I}(J).duration(1);
%           end
%           disp([self.data{I}(1).duration]);
%           dur = mean(tmp);

          
          self.working('Overview', 1, 5, [int amp dur slp tot], 'B', I);
        end
      end
    end
    
    function update(self, data)
      self.data = data;
    end
    
    function working(self, sheetname, nr, nc, m, FirstCol, fr)
      try
        Sheets = self.Excel.ActiveWorkBook.Sheets;
        target_sheet = get(Sheets, 'Item', sheetname);
      catch
        % Error if the sheet doesn't exist.  It would be nice to create it, but
        % I'm too lazy.
        % The alternative to try/catch is to call xlsfinfo to see if the sheet exists, but
        % that's really slow.
        error(['Sheet ' sheetname ' does not exist!']);
      end;
      
      invoke(target_sheet, 'Activate');
      
      Activesheet = self.Excel.Activesheet;
      
      % Put a MATLAB array into Excel.
      FirstRow = fr;
      LastRow = FirstRow+nr-1;
      LastCol = self.localComputLastCol(FirstCol,nc);
      ActivesheetRange = get(Activesheet,'Range',[FirstCol num2str(FirstRow)],[LastCol num2str(LastRow)]);
      set(ActivesheetRange, 'Value', m);
      
    end
    
    function cleanup(self)
            % Save and quit Excel and clean up
      if ~isempty(self.Excel) && ~isempty(self.Workbook)
        invoke(self.Workbook, 'Save');
        invoke(self.Excel, 'Quit');
      end;
      
      %Delete the ActiveX object
      delete(self.Excel);
    end
    
    function LastColumnLetters = localComputLastCol(~, FirstCol, numberOfColumnsToWrite)
      % Convert to upper case.
      FirstCol = upper(FirstCol);
      
      if length(FirstCol) == 1
        FirstColOffset = double(FirstCol) - double('A');    %Offset from column A
      else
        % Fix for starting columns having double letters
        % provided by Mark Hayworth, Procter & Gamble
        firstLetter = FirstCol(1);
        secondLetter = FirstCol(2);
        FirstColOffset = 26 * (double(firstLetter) - double('A') + 1) + (double(secondLetter) - double('A'));    %Offset from column A
      end
      
      % Compute the numerical column number where the last data will reside.
      lastColumnNumber = FirstColOffset + numberOfColumnsToWrite;
      if lastColumnNumber > 256
        % Excel (STILL!) can handle only 256 columns.
        % Set it to 256 if it exceeds this, just to avoid an error.
        lastColumnNumber = 256;
      end
      
      % Compute the column header letters.  It will either be one letter in the range of A-Z
      % or two letters, like AA, AB, . . . IV.  IV is the most Excel can handle.
      if lastColumnNumber <= 26
        % It needs just a single letter.
        % Just convert to ASCII code, add the number of needed columns,
        % and convert back to a string.
        LastColumnLetters = char(double(FirstCol) + numberOfColumnsToWrite - 1);
      else
        % It needs a double letter.
        
        % This block fixes Michelle Hirsch's code (which has a bug for high
        % column letters and/or high numbers of columns to write).
        % Fixed by Mark Hayworth, The Procter & Gamble Company.
        
        % Get which group of 26 it's in: A-Z, AA-AZ, BA-BZ, ... HA-HZ, or IA-IV
        % A* = group #0, B* = group #1, I* = group #8.
        groupNumber = ceil(lastColumnNumber / 26) - 2;
        
        % Find out what the offset is for the last column with that group of 26.
        % In other words, how many columns beyond the last group of 26 is it?
        groupOffset = rem(lastColumnNumber - 1, 26);
        % The above line maps ranges 27-52, 53-78, 79-104, 105-130, 106-156,
        % 157-182, 183-208, 209-234, and 235-260 into the range 0-25.
        
        LastColFirstLetter  = char(double('A') + groupNumber);
        LastColSecondLetter = char(double('A') + groupOffset);
        % Append first and last letters together to get combined double letter.
        LastColumnLetters = [LastColFirstLetter LastColSecondLetter];
      end
      return;
    end
  end
  
end

