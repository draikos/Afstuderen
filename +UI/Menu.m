classdef Menu < handle
  
  properties
    f;
    e;
    v;
    h;
    
    callback;
  end
  
  methods
    function self = Menu
      self.f = uimenu('Label', '&File');
          uimenu(self.f, 'Label', '&Open...    Ctrl + O');
          uimenu(self.f, 'Label', '&Close      Ctrl + W');
          uimenu(self.f, 'Label', '&Save       Ctrl + S');
          uimenu(self.f, 'Label', '&Export    ', 'Separator', 'on');
      self.e = uimenu('Label', '&Edit');
          uimenu(self.e, 'Label', '&Analyse settings    Ctrl + E');
          uimenu(self.e, 'Label', '&Manual marking      Ctrl + M');
          uimenu(self.e, 'Label', '&Delete selected     Backspace');
      self.v = uimenu('Label', '&View');
          uimenu(self.v, 'Label', '&Show markings', 'Checked', 'on');
          uimenu(self.v, 'Label', '&Show QRS', 'Checked', 'on');
          uimenu(self.v, 'Label', '&Activate Pan', 'Checked', 'off');
      self.h = uimenu('Label', '&Help');
          uimenu(self.h, 'Label', '&Open help');
          
      set(self.f.Children(3), 'Callback', 'disp(''save'')');
    end
    
    function setOpen(self, x)
      set(self.f.Children(4), 'Callback', x);
    end
    
    function setClose(self, x)
      set(self.f.Children(3), 'Callback', x);
    end
    
    function setSave(self, x)
      set(self.f.Children(2), 'Callback', x);
    end
    
    function setCallbacks(self, x)
      self.callback = x;
      
      set(self.f.Children(1), 'Callback', @self.export_);
      
      set(self.e.Children(3), 'Callback', @self.edit);
      set(self.e.Children(2), 'Callback', @self.add);
      set(self.e.Children(1), 'Callback', @self.remove_);
      
      set(self.v.Children(1), 'Callback', @self.panToggle);
      set(self.v.Children(2), 'Callback', @self.qrsToggle);
      set(self.v.Children(3), 'Callback', @self.marksToggle);
      
      set(self.h.Children(1), 'CallBack', @self.help_);
    end

    function marksToggle(self, ~,~)
      state = self.v.Children(3).Checked;
      
      if strcmp(state, 'on')
        self.v.Children(3).Checked = 'off';
      else
        self.v.Children(3).Checked = 'on';
      end
      
      self.callback('marks');
    end
    
    function qrsToggle(self, ~,~)
      state = self.v.Children(2).Checked;
      
      if strcmp(state, 'on')
        self.v.Children(2).Checked = 'off';
      else
        self.v.Children(2).Checked = 'on';
      end
      
      self.callback('qrs');
    end
    
    function panToggle(self, ~, ~)
        state = self.v.Children(1).Checked;
        
        if strcmp(state, 'on')
            self.v.Children(1).Checked = 'off';
        else
            self.v.Children(1).Checked = 'on';
        end
        
        self.callback('panning');
    end
    
    function edit(self, ~,~)
      self.callback('edit');
    end
    
    function add(self, ~, ~)
      self.callback('add');
    end
    
    function remove_(self, ~, ~)
      self.callback('remove');
    end
    
    function export_(self, ~, ~)
        self.callback('exportfile');
    end
    
    function help_(~, ~, ~)
      
    end
  end
  
end