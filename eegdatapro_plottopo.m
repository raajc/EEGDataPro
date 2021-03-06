% plottopo() - plot concatenated multichannel data epochs in a topographic
% or
%              rectangular array. Uses a channel location file with the same 
%              format as topoplot(), or else plots data on a rectangular grid. 
%              If data are all positive, they are assumed to be spectra.
% Usage:
%    >> plottopo(data, 'key1', 'val1', 'key2', 'val2')
% Or
%    >> plottopo(data,'chan_locs',frames,limits,title,channels,...
%                      axsize,colors,ydir,vert) % old function call
% Inputs:
%   data       = data consisting of consecutive epochs of (chans,frames)
%                or (chans,frames,n)
%
% Optional inputs:
%  'chanlocs'  = [struct] channel structure or file plot ERPs at channel 
%                locations. See help readlocs() for data channel format.
%  'geom'      = [rows cols] plot ERP in grid (overwrite previous option).
%                Grid size for rectangular matrix. Example: [6 4].
%  'frames'    = time frames (points) per epoch {def|0 -> data length}
%  'limits'    = [xmin xmax ymin ymax]  (x's in ms or Hz) {def|0 
%                 (or both y's 0) -> use data limits)
%  'ylim'      = [ymin ymax] y axis limits. Overwrite option above.
%  'title'     = [string] plot title {def|'' -> none}
%  'chans'     = vector of channel numbers to plot {def|0 -> all}
%  'axsize'    = [x y] axis size {default [.05 .08]}
%  'legend'    = [cell array] cell array of string for the legend. Note
%                the last element can be an integer to set legend 
%                position.
%  'showleg'   = ['on'|'off'] show or hide legend.
%  'colors'    = [cell array] cell array of plot aspect. E.g. { 'k' 'k--' }
%                for plotting the first curve in black and the second one
%                in black dashed. Can also contain additional formating.
%                { { 'k' 'linewidth' 2 } 'k--' } same as above but
%                the first line is bolded.
%  'ydir'      = [1|-1] y-axis polarity (pos-up = 1; neg-up = -1) {def -> -1}
%  'vert'      = [vector] of times (in ms or Hz) to plot vertical lines 
%                {def none}
%  'hori'      = [vector] plot horizontal line at given ordinate values.
%  'regions'   = [cell array] cell array of size nchan. Each cell contains a
%                float array of size (2,n) each column defining a time region 
%                [low high] to be highlighted.
%  'plotfunc'  = [cell] use different function for plotting data. The format
%                is { funcname arg2 arg3 arg2 ... }. arg1 is taken from the
%                data.
%
% Author: Scott Makeig and Arnaud Delorme, SCCN/INC/UCSD, La Jolla, 3-2-98 
%
% See also: plotdata(), topoplot()

% Copyright (C) 3-2-98 from plotdata() Scott Makeig, SCCN/INC/UCSD,
% scott@sccn.ucsd.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% 5-11-98 added channels arg -sm
% 7-15-98 added ydir arg, made pos-up the default -sm
% 7-23-98 debugged ydir arg and pos-up default -sm
% 12-22-99 added grid size option, changed to sbplot() order -sm
% 03-16-00 added axcopy() feature -sm & tpj
% 08-21-00 debugged axheight/axwidth setting -sm
% 01-25-02 reformated help & license, added links -ad 
% 03-11-02 change the channel names ploting position and cutomize pop-up -ad 
% 03-15-02 added readlocs and the use of eloc input structure -ad 
% 03-15-02 debuging chanlocs structure -ad & sm 

%  'chan_locs' = file of channel locations as in >> topoplot example   {grid}
%                ELSE: [rows cols] grid size for rectangular matrix. Example: [6 4]
%   frames     = time frames (points) per epoch {def|0 -> data length}
%  [limits]    = [xmin xmax ymin ymax]  (x's in ms or Hz) {def|0 
%                 (or both y's 0) -> use data limits)
%  'title'     = plot title {def|0 -> none}
%   channels   = vector of channel numbers to plot & label {def|0 -> all}
%                   else, filename of ascii channel-name file
%   axsize     = [x y] axis size {default [.07 .07]}
%  'colors'    = file of color codes, 3 chars per line  
%                ( '.' = space) {0 -> default color order}
%   ydir       = y-axis polarity (pos-up = 1; neg-up = -1) {def -> pos-up}
%   vert       = [vector] of times (in ms or Hz) to plot vertical lines {def none}
%   hori        = [vector] of amplitudes (in uV or dB) to plot horizontal lines {def none}
%
%
% Renamed from tmseeg_plottopo to eegdatapro_plottopo by 
% Ben Schwartzmann 2019


function Axes = eegdatapro_plottopo(data, varargin)
    
%
%%%%%%%%%%%%%%%%%%%%% Graphics Settings - can be customized %%%%%%%%%%%%%%%%%%
%
LINEWIDTH     = 0.7;     % data line widths (can be non-integer)
FONTSIZE      = 10;      % font size to use for labels
CHANFONTSIZE  = 7;       % font size to use for channel names
TICKFONTSIZE  = 8;       % font size to use for axis labels
TITLEFONTSIZE = 12;      % font size to use for the plot title
PLOT_WIDTH    = 1;     % 0.95, width and height of plot array on figure
PLOT_HEIGHT   = 1;    % 0.88
gcapos = get(gca,'Position'); axis off;
PLOT_WIDTH    = gcapos(3)*PLOT_WIDTH; % width and height of gca plot array on gca
PLOT_HEIGHT   = gcapos(4)*PLOT_HEIGHT;
curfig = gcf;            % learn the current graphic figure number
%
%%%%%%%%%%%%%%%%%%%% Default settings - use commandline to override %%%%%%%%%%%
%
DEFAULT_AXWIDTH  = 0.04; %0.05
DEFAULT_AXHEIGHT = 0.07; % 0.08
DEFAULT_SIGN = -1;                        % Default - plot positive-up
ISRECT = 0;                               % default
    
if nargin < 1
    help plottopo
    return
end

if length(varargin) > 0
    if length(varargin) == 1 | ~isstr(varargin{1}) | isempty(varargin{1}) | ...
        (length(varargin)>2 &  ~isstr(varargin{3}))
        options = { 'chanlocs' varargin{1} };
        if nargin > 2, options = { options{:} 'frames' varargin{2} }; end;
        if nargin > 3, options = { options{:} 'limits' varargin{3} }; end;
        if nargin > 5, options = { options{:} 'chans'  varargin{5} }; end;
        if nargin > 6, options = { options{:} 'axsize' varargin{6} }; end;
        if nargin > 7, options = { options{:} 'colors' varargin{7} }; end;
        if nargin > 8, options = { options{:} 'ydir'   varargin{8} }; end;
        if nargin > 9, options = { options{:} 'vert'   varargin{9} }; end;
        if nargin > 10,options = { options{:} 'hori'  varargin{10} }; end;
        if nargin > 4 & ~isequal(varargin{4}, 0), options = {options{:} 'title'  varargin{4} }; end;
        %    , chan_locs,frames,limits,plottitle,channels,axsize,colors,ydr,vert)
    else
        options = varargin;
    end;
else
    options = varargin;
end;
g = finputcheck(options, { 'chanlocs'  ''    []          '';
                    'frames'    'integer'               [1 Inf]     size(data,2);
                    'chans'     { 'integer','string' }  { [1 Inf] [] }    0;
                    'geom'      'integer'               [1 Inf]     [];
                    'channames' 'string'                []          '';
                    'limits'    'float'                 []          0;
                    'ylim'      'float'                 []          [];
                    'title'     'string'                []          '';
                    'plotfunc'  'cell'                  []          {};
                    'axsize'    'float'                 [0 1]       [nan nan];
                    'regions'   'cell'                  []          {};
                    'colors'    { 'cell','string' }     []          {};
                    'legend'    'cell'                  []          {};
                    'showleg'   'string'                {'on','off'} 'on';
                    'ydir'      'integer'               [-1 1]      DEFAULT_SIGN;
                    'vert'      'float'                 []          [];
                    'hori'      'float'                 []          []});
if isstr(g), error(g); end;
N = size(data,2);
data = reshape(data, size(data,1), size(data,2), size(data,3));    
%if length(g.chans) == 1 & g.chans(1) ~= 0, error('can not plot a single ERP'); end;

[chans,framestotal]=size(data);           % data size

%
%%%%%%%%%%%%%%% Substitute defaults for missing parameters %%%%%%%%%%%%%%%%
%
  
axwidth  = g.axsize(1);
if length(g.axsize) < 2
    axheight = NaN;
else 
    axheight = g.axsize(2);
end;
if isempty(g.chans) | g.chans == 0
   g.chans = 1:size(data,1);
elseif ~isstr(g.chans)
   g.chans = g.chans;
end

nolegend = 0;
if isempty(g.legend), nolegend = 1; end;

if ~isempty(g.ylim)
    g.limits(3:4) = g.ylim;
end;
plotgrid = 0;
if isempty(g.chanlocs) % plot in a rectangular grid
    plotgrid = 1;
elseif ~isfield(g.chanlocs, 'theta')
    plotgrid = 1;
end;
if length(g.chans) < 4 & ~plotgrid
    disp('Not enough channels, does not use channel coordinate to plot axis');
    plotgrid = 1;
end;
if plotgrid & isempty(g.geom)
  n = ceil(sqrt(length(g.chans)));
  g.geom = [n ceil(length(g.chans)/n)];
end
if ~isempty(g.geom)
    plotgrid = 1;
end;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%% Test parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
  icadefs; % read BACKCOLOR, MAXPLOTDATACHANS constant from icadefs.m
  if g.frames <=0,
    g.frames = framestotal;    % default
    datasets=1;
  elseif g.frames==1,
    fprintf('plottopo: cannot plot less than 2 frames per trace.\n');
    return
    datasets=1;
  else
    datasets = fix(framestotal/g.frames);        % number of traces to overplot
  end;

  if max(g.chans) > chans
    fprintf('plottopo(): max channel index > %d channels in data.\n',...
                       chans);
    return
  end
  if min(g.chans) < 1
    fprintf('plottopo(): min channel index (%g) < 1.\n',...
                       min(g.chans));
    return
  end;
  if length(g.chans)>MAXPLOTDATACHANS,
    fprintf('plottopo(): not set up to plot more than %d traces.\n',...
                       MAXPLOTDATACHANS);
    return
  end;

%   if datasets>MAXPLOTDATAEPOCHS 
%       fprintf('plottopo: not set up to plot more than %d epochs.\n',...
%                        MAXPLOTDATAEPOCHS);
%     return
%   end;

  if datasets<1
      fprintf('plottopo: cannot plot less than 1 epoch!\n');
      return
  end;

  if ~isempty(g.geom)
      if isnan(axheight) % if not specified
          axheight = gcapos(4)/(g.geom(1)+1);
          axwidth  = gcapos(3)/(g.geom(2)+1);
      end
      % if chan_locs(2) > 5
      %     axwidth = 0.66/(chan_locs(2)+1);
      % end
  else
      axheight = DEFAULT_AXHEIGHT;
      axwidth =  DEFAULT_AXWIDTH;
  end
    fprintf('Plotting data using axis size [%g,%g]\n',axwidth,axheight);

    %
    %%%%%%%%%%%%% Extend the size of the plotting area in the window %%%%%%%%%%%%
    %
    curfig = gcf;
    h=figure(curfig);
    set(h,'PaperUnits','normalized'); % use percentages to avoid US/A4 difference
    set(h,'PaperPosition',[0.0235308 0.0272775 0.894169 0.909249]); % equivalent
    orient portrait
    axis('normal');

    set(gca,'Color',BACKCOLOR);               % set the background color
    
    axcolor= get(0,'DefaultAxesXcolor'); % find what the default x-axis color is
    vertcolor = 'k';
    horicolor = vertcolor;
       
    %
    %%%%%%%%%%%%%%%%%%%%%%%%% Plot and label specified channels %%%%%%%%%%%%%%%%%%
    %
    data = data(g.chans,:);
    chans = length(g.chans);
    

    %%%%%%%%%%%%%%%%%%%%%%% Read and adjust limits %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    if g.limits==0,      % == 0 or [0 0 0 0]
        xmin=0;
        xmax=g.frames-1;
        % for abs max scaling:
        ymax=max(max(abs(data)));
        ymin=ymax*-1;
        % for data limits:
        %ymin=min(min(data));
        %ymax=max(max(data));
    else
        if length(g.limits)~=4,
            error('plottopo: limits should be 0 or an array [xmin xmax ymin ymax].\n');
        end;
        xmin = g.limits(1);
        xmax = g.limits(2);
        ymin = g.limits(3);
        ymax = g.limits(4);
    end;

    if xmax == 0 & xmin == 0,
        x = (0:1:g.frames-1);
        xmin = 0;
        xmax = g.frames-1;
    else
        dx = (xmax-xmin)/(g.frames-1);
        x=xmin*ones(1,g.frames)+dx*(0:g.frames-1); % compute x-values
    end;
    if xmax<=xmin,
        fprintf('plottopo() - xmax must be > xmin.\n')
        return
    end

    if ymax == 0 & ymin == 0,
        % for abs max scaling:
        ymax=max(max(abs(data)));
        ymin=ymax*-1;
        % for data limits:
        %ymin=min(min(data));
        %ymax=max(max(data));
    end
    if ymax<=ymin,
        fprintf('plottopo() - ymax must be > ymin.\n')
        return
    end

    xlabel = 'Time (ms)';
    %
    %%%%%%%%%%%%%%%%%%%%%% Set up plotting environment %%%%%%%%%%%%%%%%%%%%%%%%%
%     %
%     h = gcf;
%     set(h,'YLim',[ymin ymax]);       % set default plotting parameters
%     set(h,'XLim',[xmin xmax]);
%     set(h,'FontSize',18);
%     set(h,'DefaultLineLineWidth',1); % for thinner postscript lines
%     
    %%%%%%%%%%%%%%%%%%%%%%%%%% Print plot info %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % clf;   % clear the current figure

    % print plottitle over (left) subplot 1
    figure(curfig); h=gca;title(g.title,'FontSize',TITLEFONTSIZE); % title plot 
    hold on
    msg = ['Plotting %d traces of %d frames with colors: '];

    fprintf('limits: [xmin,xmax,ymin,ymax] = [%4.1f %4.1f %4.2f %4.2f]\n',...
            xmin,xmax,ymin,ymax);
    fprintf(msg,datasets,g.frames);

    set(h,'FontSize',FONTSIZE);           % choose font size
    set(h,'YLim',[ymin ymax]);            % set default plotting parameters
    set(h,'XLim',[xmin xmax]);

    axis('off')
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Read chan_locs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    if plotgrid
        ISRECT = 1;
        ht = g.geom(1);
        wd = g.geom(2);
        if chans > ht*wd
            fprintf('plottopo(): (%d) channels to be plotted > grid size [%d %d]\n',...
                    chans,ht,wd);
            return
        end
        xvals = 0; yvals = 0;
        if isempty(g.channames)
            if isfield(g.chanlocs,'labels') && ~iscellstr({g.chanlocs.labels})
                g.channames = strvcat(g.chanlocs.labels);
            else
                g.channames = repmat(' ',ht*wd,4);
                for i=1:ht*wd
                    channum = num2str(i);
                    g.channames(i,1:length(channum)) = channum;
                end
            end
        end
        
    else % read chan_locs file
         % read the channel location file
         % ------------------------------
        if isstruct(g.chanlocs)
            nonemptychans = cellfun('isempty', { g.chanlocs.theta });
            nonemptychans = find(~nonemptychans);
            [tmp g.channames Th Rd] = readlocs(g.chanlocs(nonemptychans));
            g.channames = strvcat({ g.chanlocs.labels });
            
        else
            [tmp g.channames Th Rd] = readlocs(g.chanlocs);
            g.channames = strvcat(g.channames);
            nonemptychans = [1:length(g.channames)];
        end;
        Th = pi/180*Th;                 % convert degrees to radians
        Rd = Rd; 
        
        if length(g.chans) > length(g.chanlocs),
            error('plottopo(): data channels must be <= ''chanlocs'' channels')
        end
        
        [yvalstmp,xvalstmp] = pol2cart(Th,Rd); % translate from polar to cart. coordinates
        xvals(nonemptychans) = xvalstmp;
        yvals(nonemptychans) = yvalstmp;
        
        % find position for other channels
        % --------------------------------
        totalchans = length(g.chanlocs);
        emptychans = setdiff_bc(1:totalchans, nonemptychans);
        totalchans = floor(sqrt(totalchans))+1;
        for index = 1:length(emptychans)
            xvals(emptychans(index)) = 0.7+0.2*floor((index-1)/totalchans);
            yvals(emptychans(index)) = -0.4+mod(index-1,totalchans)/totalchans;
        end;
        g.channames = g.channames(g.chans,:);
        xvals     = xvals(g.chans);
        yvals     = yvals(g.chans);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % xvals = 0.5+PLOT_WIDTH*xvals;   % controls width of  plot array on page!
    % yvals = 0.5+PLOT_HEIGHT*yvals;  % controls height of plot array on page!
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if length(xvals) > 1
        if length(unique(xvals)) > 1
            xvals = (xvals-mean([max(xvals) min(xvals)]))/(max(xvals)-min(xvals)); % recenter
            xvals = gcapos(1)+gcapos(3)/2+PLOT_WIDTH*xvals;   % controls width of plot 
                                                              % array on current axes
        end;
    end;
    yvals = gcapos(2)+gcapos(4)/2+PLOT_HEIGHT*yvals;  % controls height of plot 
                                                      % array on current axes
                                                      %
                                                      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Plot traces %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                                      %

    xdiff=xmax-xmin;
    ydiff=ymax-ymin;

    Axes = [];

%--------------------------shorter code test-------------------------------
 for c = 1:chans
    if plotgrid
        Axes = [ Axes sbplot(g.geom(1), g.geom(2), c)];
    else
        xcenter = xvals(c);
        ycenter = yvals(c);
        Axes = [Axes axes('Units','Normal','Position', ...
                          [xcenter-axwidth/2 ycenter-axheight/2 axwidth axheight])];
    end;

    hold on;                      % plot down left side of page first
                                  % set(h,'YLim',[ymin ymax]);    % set default plotting parameters
                                  % set(h,'XLim',[xmin xmax]);


end


