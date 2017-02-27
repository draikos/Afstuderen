classdef Selector < handle
  % 8 by N matrix of pixel to choose channel
  properties
    % some settings
    view;
    mat;
    val;
    selected = 1;
    xv;
    yv;
    xh;
    yh;
    hStrings;
    callback;
  end
  
  methods
    function self = Selector(view)
      self.mat = zeros(192/8, 8);
      self.mat(1) = 1;
      self.val = self.mat;
      self.view = view;
      
      for I = 1:192/8
        for J = 1:8
          self.val(I,J) = J + (I-1) * 8;
        end
      end
      
      pan(self.view, 'off');
    end
    
    function setCallback(self, x)
      self.callback = x;
    end
    
    function show(self)
      % display the selectors
      colormap(self.view, [1,1,1;1,0,0]);
      imagesc(self.view, self.mat);
      
      self.createGrid;
      self.displayGrid;
      self.displayText;
      set(self.view,'XTick',[], 'XTickLabel',[],...
        'YTick',[], 'YTickLabel',[], 'TickLength', [0 0]);
    end
    
    function next(self)
      % move to next channel
      if self.selected ~= 192
        [column, row] = self.selection(self.selected);
        self.mat(row, column) = 0;
        self.selected = self.selected + 1;
        [column, row] = self.selection(self.selected);
        self.mat(row, column) = 1;
        
        self.update;
        
        self.callback(self.selected);
      end
    end
    
    function previous(self)
      % move to previous channel
      if self.selected ~= 1
        [column, row] = self.selection(self.selected);
        self.mat(row, column) = 0;
        self.selected = self.selected - 1;
        [column, row] = self.selection(self.selected);
        self.mat(row, column) = 1;
        
        self.update;
        
        self.callback(self.selected);
      end
    end
  end
  
  methods (Access = private)
    % private function/methods
    function createGrid(self)
      % create grid
      h = findobj(gcf,'type','image');
      
      xdata = get(h, 'XData');
      ydata = get(h, 'YData');
      
      M = size(get(h,'CData'), 1);
      N = size(get(h,'CData'), 2);
      
      if M > 1
        pixel_height = diff(ydata) / (M-1);
        
      else
        pixel_height = 1;
      end
      
      if N > 1
        pixel_width = diff(xdata) / (N-1);
      else
        pixel_width = 1;
      end
      
      y_top = ydata(1) - (pixel_height/2);
      y_bottom = ydata(2) + (pixel_height/2);
      y = linspace(y_top, y_bottom, M+1);
      
      x_left = xdata(1) - (pixel_width/2);
      x_right = xdata(2) + (pixel_width/2);
      x = linspace(x_left, x_right, N+1);
      
      self.xv = zeros(1, 2*numel(x));
      self.xv(1:2:end) = x;
      self.xv(2:2:end) = x;
      
      self.yv = repmat([y(1) ; y(end)], 1, numel(x));
      self.yv(:,2:2:end) = flipud(self.yv(:,2:2:end));
      
      self.xv = self.xv(:);
      self.yv = self.yv(:);
      
      self.yh = zeros(1, 2*numel(y));
      self.yh(1:2:end) = y;
      self.yh(2:2:end) = y;
      
      self.xh = repmat([x(1) ; x(end)], 1, numel(y));
      self.xh(:,2:2:end) = flipud(self.xh(:,2:2:end));
      
      self.xh = self.xh(:);
      self.yh = self.yh(:);
    end
    
    function displayGrid(self)
      % displays grid
      line('Parent', self.view, 'XData', self.xh, 'YData', self.yh, ...
        'Color', 'k', 'Clipping', 'off');
      line('Parent', self.view, 'XData', self.xv, 'YData', self.yv, ...
        'Color', 'k', 'Clipping', 'off');
    end
    
    function displayText(self)
      textStrings = num2str(self.val(:));
      textStrings = strtrim(cellstr(textStrings));
      [x, y] = meshgrid(1:8, 1:192/8);
      self.hStrings = text(self.view, x(:),y(:), textStrings(:),...
        'HorizontalAlignment', 'center');
      set(self.hStrings, 'ButtonDownFcn', @self.selectorCallback);
    end
    
    function [column, row] = selection(~, selected)
      % return row and column of selected channel
      remainder = mod(selected, 8);
      row = floor(selected/8) + 1;
      if remainder == 0
        column = 8;
        row = row - 1;
      else
        column = remainder;
      end 
    end
  
    function update(self)
      % update view to current selected
      imagesc(self.view, self.mat);
      self.displayText;
      self.displayGrid;
      
      set(self.view,'XTick',[], 'XTickLabel',[],...
        'YTick',[], 'YTickLabel',[], 'TickLength', [0 0]);
    end
    
    function selectorCallback(self, src, ~)
      % callback function for selector
      [column, row] = self.selection(self.selected);
      self.mat(row, column) = 0;
      self.selected = str2double(src.String);
      [column, row] = self.selection(self.selected);
      self.mat(row, column) = 1;
      
      self.update;
      
      self.callback(self.selected);
    end
  end

end