classdef App < handle
    % AF_Viewer The GUI for AF detection
    %   Detailed explanation goes here, if any...
    
    properties %(Access = private)
        % UI elements
        Window;
        SelectorX;
        GraphX;
        Panel;
        
        % extern components
        selector;
        graph;
        panel;
        menu;
        config;
        qrsFixer;
        
        
        % tools
        reader;
        export;
        qrs;
        analyzer;
        util;
        
        % data
        channel;
        
        % flag
        opened = false;
        panMode;
        savePath;
    end
    
    methods
        function self = App
            self.channel = 1;
        end
        
        function closeApp(self, ~, ~)
            % this function runs when the app is closed
            delete(self.Window);
        end
        
        function fileOpenerCallback(self, ~, ~)
            [filename, PathName] = uigetfile({'*.E01;*.EEE',...
                'AF_Viewer files (*.E01, *.EEE)'}, 'Select E01 file');
            
            
            if PathName
                self.reader  = E01.Reader([PathName filename]);
                self.export  = XLS.Export([], [PathName filename]);
                self.savePath = [PathName filename];
                self.Window.Name = ['AF Detector: ' filename];
                
                if exist([PathName filename '.m'], 'file')
                    S = load([PathName filename '.m'], '-mat');
                    self.graph.points = S.p;
                    self.graph.tresholds = S.t;
                end
                
                if ~self.opened
                    self.graph.draw(self.reader.all);
                    self.opened = true;
                else
                    self.closeApp;
                    self.run;
                    self.graph.draw(self.reader.all);
                end
            end
        end
        
        function run(self)
            % run App
            self.create;
            
            % configurations
            self.menu.setOpen(@self.fileOpenerCallback);
            self.menu.setClose(@self.closeApp);
            self.menu.setSave(@self.saveCallback);
            self.menu.setCallbacks(@self.menuCallback);
            
            self.panel.setCallbacks(@self.selectableCallback);
            
            self.selector.setCallback(@self.channelCallback);
            
            self.config.setCallback(@self.markingCallback);
            
            self.graph.setCallback(@self.infoCallback);
            
            
            self.show;
            
        end
        
    end
    
    methods (Access = private)
        function create(self)
            self.Window = figure('MenuBar', 'none',...
                'NumberTitle', 'off', 'Name', 'AF Detector',...
                'units', 'normalized', 'outerposition', [.1 .15 .80 .75],...
                'KeyPressFcn', @self.keyCallback);
            selectorX = axes(self.Window, 'Position', [0, .30, .15, .70]);
            graphX = axes(self.Window, 'Position', [0, 0, 1, .269]);
            
            self.selector = UI.Selector(selectorX);
            self.graph = UI.Graph(graphX);
            self.panel = UI.Panel(self.Window);
            self.menu = UI.Menu;
            self.config = UI.Config;
        end
        
        function show(self)
            % display UI
            self.selector.show;
            self.graph.show;
            self.panel.show;
            
            self.panMode = pan(self.Window);
            setAllowAxesPan(self.panMode, self.selector.view, false);
            self.panMode.Motion = 'vertical';
            self.panMode.Enable = 'off';
        end
        
        function keyCallback(self, ~, event)
            switch event.Key
                case 'w'
                    if strcmp(event.Modifier, 'control')
                        self.closeApp;
                    end
                case 'o'
                    if strcmp(event.Modifier, 'control')
                        self.fileOpenerCallback;
                    end
                case 'leftarrow'
                    self.graph.scrollRightCallback;
                case 'rightarrow'
                    self.graph.scrollLeftCallback;
                case 'uparrow'
                    self.selector.next;
                case 'downarrow'
                    self.selector.previous;
                case 'g'
                    if strcmp(event.Modifier, 'shift')
                        self.graph.zoomInCallback;
                    else
                        self.graph.zoomOutCallback;
                    end
                case 'z'
                    if strcmp(event.Modifier, 'control')
                        self.graph.deleteEntry;
                    end
                case 'p'
                    self.graph.getQrs;
                case 'l'
                    self.graph.redraw;
                case 't'
                    if strcmp(event.Modifier, 'shift')
                        self.graph.shrinkCallback;
                    else
                        self.graph.growCallback;
                    end
                case 'e'
                    if strcmp(event.Modifier, 'control')
                        self.config.show;
                    end
                case 's'
                    if strcmp(event.Modifier, 'control')
                        self.saveCallback;
                    end
                case 'm'
                    if strcmp(event.Modifier, 'control')
                        self.modeSelection;
                    end
                    if strcmp(event.Modifier, 'shift')
                        self.modeSelection;
                    end
                case 'r'
                    if strcmp(event.Modifier, 'control')
                        self.graph.update(self.reader.get(self.channel), self.channel);
                    end
                case 'backspace'
                    self.graph.deleteMark;
                case 'escape'
                    set(self.Window, 'WindowButtonMotionFcn', '');
                    self.graph.handleSeeker('delete');
                    self.graph.clearHiglight;
            end
        end
        
        function channelCallback(self, x)
            self.channel = x;
            
            if ~isempty(self.reader)
                self.graph.update(self.reader.get(x), x);
            end
        end
        
        function selectableCallback(self, x)
            switch x
                case 'next'
                    self.graph.nextMark;
                case 'previous'
                    self.graph.previousMark;
                case 'delete'
                    self.graph.delete;
            end
        end
        
        function menuCallback(self, x)
            switch x
                case 'qrs'
                    self.graph.toggleQRS;
                case 'marks'
                    self.graph.toggleMarks;
                case 'edit'
                    self.config.show;
                case 'add'
                    self.modeSelection;
                case 'remove'
                    self.graph.deleteMark;
                case 'panning'
                    self.panModeHelper;
                case 'exportfile'
                    self.exportCallback
            end
        end
        
        function markingCallback(self, f)
            if ~isempty(self.reader)
                t = struct;
                t.slope = self.config.vel_norm;
                t.amp = self.config.amp_norm;
                t.qrs = self.config.vel_qrs;
                
                self.graph.mark(self.reader.get(self.channel), t, f);
            end
        end
        
        function infoCallback(self, name, varargin)
            switch name
                case 'clear'
                    self.panel.clear;
                case 'update'
                    self.panel.update(varargin{:});
                case 'toggle'
                    self.menu.marksToggle;
                case 'treshold'
                    %           disp(varargin);
                    self.config.setValues(varargin{:});
                case 'export'
                    self.export.update(varargin{1});
            end
        end
        
        function saveCallback(self, ~, ~)
            state = struct;
            state.p = self.graph.points;
            state.t = self.graph.tresholds;
            
            save([self.savePath '.m'],'-struct','state');
        end
        
        function exportCallback(self, ~, ~)
            if ~isempty(self.export)
                self.graph.export(self.reader.all);
                self.export.to;
            end
        end
        
        function modeSelection(self)
            fcn = get(self.Window, 'WindowButtonMotionFcn');
            if strcmp(fcn, '')
                % switch to marking mode
                self.graph.handleSeeker('create');
                set(self.Window, 'WindowButtonMotionFcn', @self.modeHelper);
            else
                % switch back to normal mode
                set(self.Window, 'WindowButtonMotionFcn', '');
                self.graph.handleSeeker('delete');
            end
        end
        
        function modeHelper(self, ~, ~)
            self.graph.followMouse;
        end
        
        function panModeHelper(self, ~, ~)
            if strcmp(self.panMode.Enable, 'on')
                self.panMode.Enable = 'off';
            else
                self.panMode.Enable = 'on';
            end
        end
    end
    
end