classdef Panel < handle
  % panel full of information and shit
  properties
    panel;
    
    % callbacks
    callback;
    
    % display info's
    dur;
    vel;
    amp;
    
    lat;
    cyc;
  end
  
  methods
    function self = Panel(w)
      window = w;
      self.panel = uipanel(window, 'Title', 'Mark info', 'FontSize',12,...
        'Position', [.40 .50 .40 .40]);
      
      % Control buttons for selecting markers
      uicontrol(self.panel, 'Style', 'pushbutton',...
        'String', 'previous', 'Units', 'normalized',...
        'Position', [.38, .1, .1, .1],...
        'Callback', @self.previousCallback);
      uicontrol(self.panel, 'Style', 'pushbutton',...
        'String', 'next', 'Units', 'normalized',...
        'Position', [.52, .1, .1, .1],...
        'Callback', @self.nextCallback);
      
      % labels for panel info's
      uicontrol(self.panel, 'Style', 'text',...
        'String', 'Amplitude:', 'Units', 'normalized',...
        'Position', [.1, .7, 0.1, 0.1]);
      uicontrol(self.panel, 'Style', 'text',...
        'String', 'Duration:', 'Units', 'normalized',...
        'Position', [.4, .7, 0.1, 0.1]);
      uicontrol(self.panel, 'Style', 'text',...
        'String', 'Slope:', 'Units', 'normalized',...
        'Position', [.7, .7, 0.1, 0.1]);
      
      uicontrol(self.panel, 'Style', 'text',...
        'String', 'LAT:', 'Units', 'normalized',...
        'Position', [.25, .4, 0.1, 0.1]);
      uicontrol(self.panel, 'Style', 'text',...
        'String', 'Beat Interval:', 'Units', 'normalized',...
        'Position', [.55, .4, 0.1, 0.1]);
    end
    
    function setCallbacks(self, callback)
      % setter for callbacks, will be called by owner
      self.callback = callback;
    end
    
    function show(self)
      % show creates the placeholders for values
      self.amp = uicontrol(self.panel, 'Style', 'text',...
        'String', '-', 'Units', 'normalized',...
        'Position', [.2, .7, 0.1, 0.1]);
      self.dur = uicontrol(self.panel, 'Style', 'text',...
        'String', '-', 'Units', 'normalized',...
        'Position', [.5, .7, 0.1, 0.1]);
      self.vel = uicontrol(self.panel, 'Style', 'text',...
        'String', '-', 'Units', 'normalized',...
        'Position', [.8, .7, 0.1, 0.1]);
      
      self.lat = uicontrol(self.panel, 'Style', 'text',...
        'String', '-', 'Units', 'normalized',...
        'Position', [.35, .4, 0.1, 0.1]);
      self.cyc = uicontrol(self.panel, 'Style', 'text',...
        'String', '-', 'Units', 'normalized',...
        'Position', [.65, .4, 0.1, 0.1]);
    end
    
    function update(self, a, d, v, l, c)
      % update or set new values in panel
      self.dur.String = sprintf('%d ms', d);
      self.vel.String = sprintf('%.2f mV/ms', -v);
      self.amp.String = sprintf('%.2f mV', abs(a));
      
      self.lat.String = sprintf('%d ms', l);
      self.cyc.String = sprintf('%d ms', c);
    end
    
    function clear(self)
      % clears out the previous set values in panel
      self.dur.String = '-';
      self.vel.String = '-';
      self.amp.String = '-';
      
      self.lat.String = '-';
      self.cyc.String = '-';
    end
  end
  
  methods (Access = private)
    function nextCallback(self, ~, ~, ~)
      % will go to next marker and updates panel
      self.callback('next');
    end
    
    function previousCallback(self, ~, ~, ~)
      % will go to previous marker and updates panel
      self.callback('previous');
    end
  end
  
end