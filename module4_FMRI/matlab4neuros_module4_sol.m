%%
%   COURSE: MATLAB training for early-career neuroscientists										
%      URL: ...
% 
%  SECTION: Module 4: FMRI
% 
%  TEACHER: Mike X Cohen, sincxpress.com
%

% NOTE: This is the solutions code.
%       You should work through the "partial" file before looking at this.

%% data sources

% Publication (behind paywall):
%   https://www.nature.com/articles/s41592-020-0941-6
% 
% Related publication on biorxiv:
%   https://www.biorxiv.org/content/10.1101/868455v1
% 
% Dataset:
%   https://osf.io/j2wsc/wiki/home/
% 
% YouTube video about the method described in the paper:
%   https://www.youtube.com/watch?v=Sz13i-9EtmA


%% a clear MATLAB workspace is a clear mental workspace

close all; clear; clc

%%
% -------------------------------------------------------- %
%                                                          %
%              Video 2: Visualize flatmaps                 %
%                                                          %
% -------------------------------------------------------- %
% 
%% Load the data

load('exampledataset.mat')

% explore the data

% 121695 voxels
numvoxels = size(data{1},1);


%% visualize a time point and standard deviation map

% produce the spatial map at one time-point
onetimepoint = data{1}(:,50);
onetimepoint = onetimepoint(imglookup);
onetimepoint(extrapmask) = NaN;

% let's see what it looks like!
figure(1), clf
subplot(121)
imagesc(onetimepoint)
title('One time point')


% standard deviation map
stdmap = std(data{1},[],2);
stdmap = stdmap(imglookup);
stdmap(extrapmask) = NaN;

% and show that one
subplot(122)
imagesc(stdmap)
title('Standard deviation map')
set(gca,'clim',[0 200])

% force the axis to have isotropic pixel size
axis image
%axis square % also try this one!


%%
% -------------------------------------------------------- %
%                                                          %
%          Video 3: Preprocess BOLD signal data            %
%                                                          %
% -------------------------------------------------------- %
% 
%% 

%% time courses of a random voxel

% pick a voxel to show time course from
voxel2plot = 12121;

% setup a subplot in the middle of the figure
figure(2), clf
subplot(4,1,2:3)

% create a time vector converted from TRs to seconds
time = (0:size(data{1},2)-1) / (1/tr); % note: 1/tr is the sampling rate

% plot the data
plot(time,data{1}(voxel2plot,:),'k','linew',2)

% and make the plot more interpretable
set(gca,'xlim',time([1 end]))
xlabel('Time (s)')
ylabel('BOLD signal (a.u.)')
title([ 'BOLD time course from voxel #' num2str(voxel2plot) ])

%% convert to percent change and detrend

for runi=1:4
    
    % convert to %change via broadcasting
    meanvals = mean(data{runi},2);
    data{runi} = 100*(data{runi}-meanvals)./meanvals;
    
    % detrending. note the orientation
    data{runi} = detrend(data{runi}')';
end


% Now re-run figures 1 and 2 in new figures.


%%
% -------------------------------------------------------- %
%                                                          %
%       Video 4: Trial-average BOLD response matrix        %
%                                                          %
% -------------------------------------------------------- %
% 
%% design matrix

figure(5), clf

% the design matrix as lines
plot(time,design{1},'s-')


% perhaps it's easier to visualize as an image?
imagesc(design{1})
xlabel('Condition number')
ylabel('Time (TR)')
colormap gray

%% show events plotted on top of the time course

figure(6), clf, hold on

% plot time course from one voxel as illustration
plot(data{1}(voxel2plot,:),'k','linew',2)



% find all time points with this event
eventonsets = find(design{1}(:,1));

% plot a dashed line at each of those events
for ei=1:length(eventonsets)
    plot([1 1]*eventonsets(ei),get(gca,'ylim'),'m--')
end

xlabel('Time (TR)')
ylabel('Detrended BOLD')
legend({'Voxel t.s.','Event 1'})

%% create event-related BOLD response around each eventtype

% time vector (converted to seconds!)
timebounds = [ -2 15 ]; % in TRs
timevec = ( timebounds(1):timebounds(2) ) / (1/tr);

% initialize matrix (condition X voxels X time)
erBOLD = zeros(6,numvoxels,length(timevec));


% loop over condition
for condi=1:6
    
    % loop over runs
    for runi=1:4
        
        % find all events of this condition in this run
        events = find(design{runi}(:,condi));
        
        % extract peri-event time series in a temporary variable
        tmp = zeros(numvoxels,length(timevec));
        for ei=1:length(events)
            tmp = tmp + data{runi}(:,events(ei)+timebounds(1):events(ei)+timebounds(2));
        end
        
        % then add the trial-averaged event to the matrix
        erBOLD(condi,:,:) = squeeze(erBOLD(condi,:,:)) + tmp/ei;
    end
end

% divide for mean
erBOLD = erBOLD/runi;

%% visualize the event-related data matrix for one stimulus type

figure(7), clf

% show the result as an image, with seconds as x-axis label
imagesc(timevec,[],squeeze(erBOLD(1,:,:)))
title('erBOLD matrix for one condition')
set(gca,'clim',[-1 1]*3)
xlabel('Time (s)')
ylabel('Voxel index')

% now try 'axis image' here. Does it look better?

%%
% -------------------------------------------------------- %
%                                                          %
%      Video 5: Animation of BOLD responses over time      %
%                                                          %
% -------------------------------------------------------- %
% 
%% 

%% make a gaussian for the spatial smoothing

% create a Gaussian (arbitrary and hand-selected size and width)
[Y,X] = meshgrid(linspace(-4,4,21));
G = exp( -(X.^2+Y.^2)/10 );
G = G./sum(G(:));

% let's see it!
figure(8), clf
imagesc(G)
axis square

%% now for the animation

% clear the figure again
figure(8), clf

% using tiledlayout to create a 2x3 grid of subplots
t = tiledlayout(2,3,'TileSpacing','Compact');


% In most animations, it's better to setup the figure first using handles,
% and then update the handles instead of redrawing the entire figure.
for condi=1:6
    
    % go to the next tile (subplot)
    nexttile
    
    % create an image. We just need the handle; the data don't matter.
    imh(condi) = imagesc(randn(size(imglookup)));
    
    % settings for each image. 
    % These settings will remain during the animation.
    set(gca,'clim',[-1 1]*3)
    axis off, axis image
    title([ 'Condition ' num2str(condi) ])
    set(gca,'fontsize',14)
end


%%% now that the figure is setup, we can run through the animation
for timei=1:size(erBOLD,3)
    
    % loop over conditions
    for condi=1:6
        
        % get the map from this time point
        timepointmap = squeeze(erBOLD(condi,:,timei));
        timepointmap = timepointmap(imglookup);
        
        % smooth with a Gaussian
        timepointmap = conv2(timepointmap,G,'same');
        timepointmap(extrapmask) = NaN;
        
        % update the color data
        set(imh(condi),'CData',timepointmap)
    end % end of condition loop
    
    
    % update the plot title
    set(get(t,'Title'),'String',[ 'Brain maps at time ' num2str(timevec(timei)) ' s.' ])
    
    % pause to allow MATLAB to update, and the audience to absorb the information
    pause(.2)
end

%%
% -------------------------------------------------------- %
%                                                          %
%   Video 6: Visualize the BOLD response from one voxel    %
%                                                          %
% -------------------------------------------------------- %
% 
%% pick a voxel in the graph and show an ERP from that pixel

% step 1: turn datacursormode on and click on a map

% step 2a: manually write down the xy coordinates
pix2plot = [463 465];

% step 2b: use the mouse to export to workspace
pix2plot = pix2plot.Position;


%% now show the time courses from that pixel

% convert from 2D coordinates to index
dataidx = imglookup(pix2plot(1),pix2plot(2));

% and plot!
figure(9), clf, hold on
plot(timevec,squeeze(erBOLD(:,dataidx,:)),'linew',2)

% some extra lines
plot(timevec([1 end]),[0 0],'k')
plot([0 0],get(gca,'ylim'),'k--')

% make the plot look nicer
xlabel('Time (s)')
ylabel('BOLD response')
set(gca,'xlim',timevec([1 end]))
legend({'Cond. 1','Cond. 2','Cond. 3','Cond. 4','Cond. 5','Cond. 6'})

%%
% -------------------------------------------------------- %
%                                                          %
%        Video 7: T-test on condition differences          %
%                                                          %
% -------------------------------------------------------- %
% 
%% simple t-test at 6s after two events

% initialize maps to empty
map1 = [];
map6 = [];


% loop over experiment runs
for runi=1:4
    
    % find all occurances of events 1 and 6
    events1 = find(design{runi}(:,1));
    events6 = find(design{runi}(:,6));
    
    % extract peri-event time series (hard-coded to 6 TRs post-onset)
    map1 = cat(2,map1,data{runi}(:,events1+6));
    map6 = cat(2,map6,data{runi}(:,events6+6));
end

% run t-test!
[~,p,~,tmap] = ttest(map1',map6');

%% visualize the map of t-values

figure(10), clf

% extract the t-values
tvals = tmap.tstat;

% statistical thresholding
tvals(p>.01) = 0;

% create and visualize the image
tmapbrain = tvals(imglookup);
tmapbrain(extrapmask) = 0;
imagesc(tmapbrain)

% various color adjustments
set(gca,'clim',[-1 1]*10)
colormap(bluewhitered(64))
colorbar

% final few niceties
axis image, axis off
set(gcf,'color','w')
title('T-test on conditions 1 vs. 6')

%% done.
