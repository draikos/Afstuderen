classdef Graph < handle
  % display graphs
  properties
    analyzer;
    callback;
    
    % UI elements
    marks;
    indicators;
    highlight;
    seeker;
    qrsLine;
    view;
    dataLine;
    pks
    locs
    plotPeaks;
    
    % info's
    current;
    regions;
    location;
    zoom;
    timeline;
    scroll;
    points;
    channel;
    tresholds;
  end
  
  methods
    function self = Graph(view)
      self.view = view;
      self.scroll = 0;
      self.zoom = [-3 3];
      self.timeline = [0 2000];
    end
    
    function toggleQRS(self, ~, ~)
      if ~isempty(self.qrsLine)
        state = self.qrsLine.Visible;
        
        if strcmp(state, 'off')
          self.qrsLine.Visible = 'on';
        else
          self.qrsLine.Visible = 'off';
        end
      end
    end
    
    function toggleMarks(self, ~, ~)
      if ~isempty(self.marks)
        state = self.marks.Visible;
        
        if strcmp(state, 'off')
          for I = 1:length(self.marks)
            self.marks(I).Visible = 'on';
          end
          if ~isempty(self.highlight)
            self.highlight.Visible = 'on';
            self.indicators.Visible = 'on';
          end
        else
          for I = 1: length(self.marks)
            self.marks(I).Visible = 'off';
          end
          if ~isempty(self.highlight)
            self.highlight.Visible = 'off';
            self.indicators.Visible = 'off';
          end
        end
      end

    end
    
    function nextMark(self, ~, ~)
      % select next marker and highlight it
      if self.current < length(self.points{self.channel})
        self.current = self.current + 1;
        x = self.points{self.channel}(self.current).location;
        
        if x+25 > self.scroll+2000
          self.scrollLeftCallback;
        end
        
        self.selectable_helper(x);
      end
    end
    
    function previousMark(self, ~, ~)
      % select previous marker and highlight it
      if self.current > 1
        self.current = self.current - 1;
        x = self.points{self.channel}(self.current).location;
        
        if x-25 < self.scroll
          self.scrollRightCallback;
        end
        
        self.selectable_helper(x);
      end
    end
    
    function scrollLeftCallback(self, ~, ~)
      tmp = self.scroll + diff(self.timeline)/2;
      
      if tmp + 2000 <= 11000
        self.scroll = tmp;
        self.timeline = self.timeline + diff(self.timeline)/2;
      end
      
      xlim(self.view, self.timeline);
    end
        
    function scrollRightCallback(self, ~, ~)
      tmp = self.scroll - diff(self.timeline)/2;
      
      if tmp >= -diff(self.timeline)/2
        self.scroll = tmp;
        self.timeline = self.timeline - diff(self.timeline)/2;
      end
      
      xlim(self.view, self.timeline);
    end
    
    function zoomInCallback(self, ~, ~)
      % zoom in function
      self.zoom = self.zoom ./ 1.2;
      ylim(self.view, self.zoom);
    end
    
    function zoomOutCallback(self, ~, ~)
      % zoom in function
      self.zoom = self.zoom .* 1.2;
      ylim(self.view, self.zoom);
    end
    
    function shrinkCallback(self, ~, ~)
      self.timeline = self.timeline ./ 1.2;
      xlim(self.view, self.timeline);
    end
    
    function growCallback(self, ~, ~)
      self.timeline = self.timeline .* 1.2;
      xlim(self.view, self.timeline);
    end
    
    function setCallback(self, x)
      self.callback = x;
    end
    
    function show(self)
      % draws graph on axes    
      ylim(self.view, self.zoom);
      xlim(self.view, [0 2000]);
      
      set(self.view, 'YTick',[], 'YTickLabel',[], 'box', 'off',...
        'XAxisLocation', 'top');
    end
    
    function draw(self, data)
      qrs = QRS.Analyzer(data);
      
      self.analyzer = AF.Analyzer(qrs.qrs, length(data(:,1)));
      self.regions = AF.Util.regions(qrs.qrs, length(data(:,1)));
      if isempty(self.tresholds)
          self.tresholds = cell(length(data(1, :)), 1);
      end
      self.channel = 1;
      frag = AF.Util.split(data(:,1), self.regions);
      
      self.dataLine = plot(self.view, data(:,1), 'k'); hold on;
      self.qrsLine = plot(self.view, frag.qrs, 'g'); hold on;
      % find peaks on the graph, gets updated with graph.update()
      % tweak for more accurate peak finding. Valleys must be added in
      % aswell
      [self.pks,self.locs] = findpeaks(data(:,1), 'MinPeakDistance', 200, 'MinPeakHeight', 0.5);
      self.plotPeaks = plot(self.view,self.locs,self.pks,'rs');hold off;
      
      ylim(self.view, self.zoom);
      xlim(self.view, self.timeline);
      
      set(self.view, 'YTick',[], 'YTickLabel',[], 'box', 'off',...
        'XAxisLocation', 'top');
      
      set(self.view, 'ButtonDownFcn', @self.markFixer);
      set(self.dataLine, 'ButtonDownFcn', @self.markFixer);
      set(self.qrsLine, 'ButtonDownFcn', @self.markFixer);
      % data naar excel toe schrijven
      % self.writeToExcelFil(data);
      
    end
    
    % Functie snel geschreven door Ben voor test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     function writeToExcelFile(~, xData)
%         filename = 'C:\Users\502896\Desktop\Documentatie Stagiaires\Ben Havenaar\test.xlsx';
%         xlswrite(filename, xData);
%     end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function update(self, data, ch)
      % update graph
      frag = AF.Util.split(data, self.regions);
      self.channel = ch;
      self.dataLine.YData = data;
      self.qrsLine.YData  = frag.qrs;
      % update peaks
      [peaks,idx] = findpeaks(data, 'MinPeakDistance', 200, 'MinPeakHeight', 0.5);
      self.plotPeaks.YData = peaks;
      self.plotPeaks.XData = idx;
      
      self.current = 0;
      if ~isempty(self.marks)
        delete(self.marks);
      end 
       
      if ~isempty(self.tresholds{ch})
        flagged = @(x) (x == 1 || x == 8 ||...
        x == 185 || x == 192);
        
        if ~flagged(self.channel)
          if (length(self.points) < ch || isempty(self.points{ch}))
            self.points{ch} = self.analyzer.all(data, self.tresholds{ch}{:});
          end
          
          if ~isempty(self.points{ch})
              self.marks = self.vline([self.points{ch}.location]);
              set(self.marks, 'ButtonDownFcn', @self.selectable);
          else
              self.marks = [];
          end
          
          self.callback('treshold', self.tresholds{ch}{:});
          
        end
      end
      
      if ~isempty(self.indicators)
        delete(self.indicators);
        self.indicators = [];
        self.callback('clear');
      end
      
      if ~isempty(self.highlight)
        delete(self.highlight);
        self.highlight = [];
      end
    end
      
    function mark(self, data, t, f)
      p = {'SlopeTreshold', t.slope, 'AmpTreshold', t.amp, 'QrsTreshold', t.qrs};
      
      if ~isempty(self.marks)
        delete(self.marks);
      end
      
      % if flag is on set paramaters for all channels
      if f == 1
        wbar = waitbar(0, 'analyzing all channels...');
        clear('self.points');
        
        for I = 1:length(self.tresholds)
%           self.points{I} = self.analyzer.all(data, p{:});
          self.tresholds{I} = p;
          waitbar(I/length(self.tresholds), wbar);
        end
        
        delete(wbar);
      else
%         self.points{self.channel} = self.analyzer.all(data, p{:});
        self.tresholds{self.channel} = p;
      end
      flagged = @(x) (x == 1 || x == 8 ||...
        x == 185 || x == 192);
      
      if ~flagged(self.channel)
        self.points{self.channel} = self.analyzer.all(data, p{:});
      
            
        if ~isempty(self.points{self.channel})
          self.marks = self.vline([self.points{self.channel}.location]);
          set(self.marks, 'ButtonDownFcn', @self.selectable);
        end
      end
    end
    
    function clearHiglight(self)
      if ~isempty(self.indicators)
        delete(self.indicators);
        self.indicators = [];
        self.callback('clear');
      end
      
      if ~isempty(self.highlight)
        delete(self.highlight);
        self.highlight = [];
      end
    end
    
    function export(self, data)
      wbar = waitbar(0, 'preparing for export...');
      flagged = @(x) (x == 1 || x == 8 ||...
        x == 185 || x == 192);
        
      for I = 1:length(self.tresholds)
        if (length(self.points) < I || isempty(self.points{I})) && ~flagged(I)
          self.points{I} = self.analyzer.all(data(:, I), self.tresholds{I}{:});
        end
        
        waitbar(I/length(self.tresholds), wbar);
      end
      
      delete(wbar);
      self.callback('export', self.points);
    end
    
    function deleteMark(self)

      if ~isempty(self.indicators)
        self.points{self.channel}(self.current) = [];
        
        delete(self.indicators);
        self.indicators = [];
        self.callback('clear');
      end
      
      if ~isempty(self.highlight)
        delete(self.highlight);
        self.highlight = [];
      end
      
      if ~isempty(self.marks)
        delete(self.marks);
        
        if ~isempty(self.points)
          self.marks = self.vline([self.points{self.channel}.location]);
          set(self.marks, 'ButtonDownFcn', @self.selectable);
        else
          self.marks = [];
        end
      end
      
    end
    
    function addMark(self, ~, ~)
      x = get(self.view, 'CurrentPoint');
      
      tmp = self.analyzer.seeker(self.dataLine.YData, x(1));
      try
        self.points{self.channel} = [self.points{self.channel}([self.points{self.channel}.location] < tmp.location);...
          tmp; self.points{self.channel}([self.points{self.channel}.location] > tmp.location)];
        
        delete(self.marks);
        self.marks = self.vline([tmp.location self.points{self.channel}.location]);
        set(self.marks, 'ButtonDownFcn', @self.selectable);
      catch
        self.points{self.channel} = tmp;
        self.marks = self.vline(tmp.location);
        set(self.marks, 'ButtonDownFcn', @self.selectable);
      end
    end
    
    function followMouse(self)
      y = get(self.view, 'Ylim');
      x = get(self.view, 'CurrentPoint');
          
      if ~isempty(self.seeker)
        self.seeker.XData = [x(1)-45 x(1)+45 x(1)+45 x(1)-45];
        self.seeker.YData = [y(1) y(1) y(2) y(2)];
      end
    end
    
    function handleSeeker(self, flag)
      switch flag
        case 'create'
          y = get(self.view, 'Ylim');
          x = get(self.view, 'CurrentPoint');
          
          if ~isempty(self.indicators)
            delete(self.indicators);
            self.indicators = [];
            self.callback('clear');
          end
          
          if ~isempty(self.highlight)
            delete(self.highlight);
            self.highlight = [];
          end
          
          self.seeker = patch(self.view, [x(1)-45 x(1)+45 x(1)+45 x(1)-45],...
            [y(1) y(1) y(2) y(2)], [1 .6 1], 'EdgeColor', 'None');
          uistack(self.seeker, 'bottom');
          
          set(self.seeker, 'ButtonDownFcn', @self.addMark);
          set(self.dataLine, 'ButtonDownFcn', @self.addMark);
          set(self.qrsLine, 'ButtonDownFcn', @self.addMark);
        case 'delete'
          % TODO: handle delete
          if ~isempty(self.seeker)
            set(self.seeker, 'ButtonDownFcn', '');
            set(self.dataLine, 'ButtonDownFcn', @self.markFixer);
            set(self.qrsLine, 'ButtonDownFcn', @self.markFixer);
            
            delete(self.seeker);
            self.seeker = [];
          end
      end
    end
  end
  
  methods (Access = private)
    
    function ret = vline(self, x)
      % plot a vertical line on given positions
      x = x(:)';
      x = [x; x]; % recall: one line per column
      y = get(self.view, 'YLim');
      y = y(:);
      y = repmat(y(:), 1, size(x, 2));
      ret = line(self.view, x, y, 'Color', 'red');
    end
    
    function selectable(self, src, ~)
      self.selectable_helper(src.XData(end));
    end
    
    function selectable_helper(self, x)
      % select marks
      y = get(self.view, 'YLim');
      
      % get/calculate values for info panel
      p_ = self.points{self.channel}([self.points{self.channel}.location] == x);
      pv = self.points{self.channel}([self.points{self.channel}.location] < x);
      
      if isempty(pv)
        pv = struct;
        pv.location = 0;
      end

      self.current = find([self.points{self.channel}.location] == x);
      if isempty(self.highlight)
        % create/display highlight on selected marker
        locate = [x-25 x+25 x+25 x-25];
        self.highlight = patch(self.view, locate,...
          [y(1) y(1) y(2) y(2)], [.8 1 1], 'EdgeColor', 'None');
        uistack(self.highlight, 'bottom');
        
        % display beginning and ending of slope
        self.indicators = line(self.view, p_.duration,...
          self.dataLine.YData(p_.duration), 'LineStyle', 'none',...
          'Marker', 'o', 'MarkerEdgeColor', 'm');
      else
        % highlight selected deflection
        self.highlight.XData = [x-25 x+25 x+25 x-25];
        self.highlight.YData = [y(1) y(1) y(2) y(2)];
        
        % indacate start and end of selected deflection
        self.indicators.XData = p_.duration;
        self.indicators.YData = self.dataLine.YData(p_.duration);
      end
      
      % calls the panel update function
      self.callback('update', p_.amplitude,...
        (p_.duration(2) - p_.duration(1)), p_.velocity,...
        p_.location, (p_.location - pv(end).location));
    end
    
    function markFixer(self, ~, ~)
      x = get(self.view, 'CurrentPoint');
      modifiers = get(gcf,'currentModifier');        %(Use an actual figure number if known)
      ctrlIsPressed = ismember('control',modifiers);
      
      if ctrlIsPressed && ~isempty(self.indicators)
        self.fixer_helper(x);
      end
    end
    
    function fixer_helper(self, x)
      p_ = self.points{self.channel}(self.current);
      
      if self.current == 1
        pv = struct;
        pv.location = 0;
      else
        pv = self.points{self.channel}(self.current - 1);
      end
      
      if x < p_.location
        self.points{self.channel}(self.current).duration(1) = round(x(1));
      else
        self.points{self.channel}(self.current).duration(2) = round(x(1));
      end
      
      tmp_h = self.dataLine.YData(...
          self.points{self.channel}(self.current).duration(1):self.points{self.channel}(self.current).location);
      tmp_l = self.dataLine.YData(...
          self.points{self.channel}(self.current).location:self.points{self.channel}(self.current).duration(2));
      self.points{self.channel}(self.current).amplitude = max(tmp_h) - min(tmp_l);
      
      self.indicators.XData = self.points{self.channel}(self.current).duration;
      self.indicators.YData = self.dataLine.YData(self.points{self.channel}(self.current).duration);
      
      p_ = self.points{self.channel}(self.current);
      
      % calls the panel update function
      self.callback('update', p_.amplitude,...
        (p_.duration(2) - p_.duration(1)), p_.velocity,...
        p_.location, (p_.location - pv(end).location));
    end
    
  end
end