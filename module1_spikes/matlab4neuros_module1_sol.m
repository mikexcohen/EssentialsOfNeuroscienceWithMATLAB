%%
%   COURSE: MATLAB training for early-career neuroscientists										
%      URL: ...
% 
%  SECTION: Module 1: spikes
% 
%  TEACHER: Mike X Cohen, sincxpress.com
%

% NOTE: This is the solutions code.
%       You should work through the "partial" file before looking at this.

%% data sources

% Main reference for this dataset:
%   Kohn, A., Smith, M.A. (2016) Utah array extracellular recordings of spontaneous and visually
%   evoked activity from anesthetized macaque primary visual cortex (V1). CRCNS.org
%   http://dx.doi.org/10.6080/K0NC5Z4X

% Direct link to the data (downloading requires a free crcns.org account):
%   http://crcns.org/data-sets/vc/pvc-11

% Direct link to the description of the data:
%   http://crcns.org/files/data/pvc-11/crcns_pvc-11_data_description.pdf

% Direct link to the publication using these data:
%   https://www.jneurosci.org/content/jneuro/28/48/12591.full.pdf

%% a clear MATLAB workspace is a clear mental workspace

close all; clear; clc

%%
% -------------------------------------------------------- %
%                                                          %
%  Video 2: Import data and convert spikes to data matrix  %
%                                                          %
% -------------------------------------------------------- %
% 
%% Load the data

% download from online and unpack
websave('file.zip','https://sincxpress.com/neuroscience/matlab4neuros_module1.zip');
unzip('file.zip');

% import to matlab
load('data_monkey1_gratings.mat')
whos

%% spike count for all trials

% note about sizes:
% data.EVENTS is [ neurons gratings trials ]

% extract sizes of the data matrix
[nNeurons,nGratings,nTrials] = size(data.EVENTS);

% initialize
totalSpikeCount = zeros([nNeurons,nGratings,nTrials]);

% loop through all elements of the data matrix
for neuroni=1:nNeurons
    for grati=1:nGratings
        for triali=1:nTrials
            
            % count the number of spikes in each cell
            totalSpikeCount(neuroni,grati,triali) = numel(data.EVENTS{neuroni,grati,triali});
        end
    end
end

%% and now using cellfun

% a much more efficient method to get the same result
totalSpikeCount2 = cellfun(@length,data.EVENTS);


% compare them to show they're equal
size(totalSpikeCount)
size(totalSpikeCount2)

% logic: if A=B, then A-B=0
differenceMatrix = totalSpikeCount - totalSpikeCount2;
sum(differenceMatrix(:))


%%
% ----------------------------------------------------------- %
%                                                             %
%  Video 3: Histograms of spike counts over units and trials  %
%                                                             %
% ----------------------------------------------------------- %
% 
%% histogram of spike counts

figure(1), clf

subplot(211)
histogram( totalSpikeCount(:),40 )
xlabel('Number of spikes')
ylabel('Count')
title('Including zero-spike trials')

%% repeat without no-spike trials

subplot(212)
histogram( nonzeros(totalSpikeCount),40 )
xlabel('Number of spikes')
ylabel('Count')
title('Excluding zero-spike trials')


%%
% ---------------------------------------------------- %
%                                                      %
%  Video 4: Tuning curve for a randomly selected cell  %
%                                                      %
% ---------------------------------------------------- %
% 
%% pick a unit and compute its tuning curve

% pick a neuron at random
randomunit = randi(nNeurons,1);

% compute the average spike count over all trials per orientation
averageSpikes = mean(totalSpikeCount(randomunit,:,:),3);

% find the maximum response
[maxval,maxresp] = max(averageSpikes);

%% visualize!

% vector of stimulus orientations in degrees
gradientOrient = 0:30:330;

% generate a figure
figure(2), clf
subplot(5,1,2:4)

% bar plot
bar(gradientOrient,averageSpikes)
xlabel('Gradient orientation')
ylabel('Average spike count')
title("Unit number " + randomunit + " 'prefers' " + gradientOrient(maxresp) + "$^\circ$",'Interpreter','latex')

% make the figure look a bit nicer
set(gca,'fontsize',14,'xticklabel',gradientOrient)
set(gcf,'color','w')

%% same data in a polar plot

figure(3), clf
polarplot(gradientOrient,averageSpikes)

help polarplot
polarplot(deg2rad(gradientOrient),averageSpikes,...
    'ks-','linewidth',3,'markersize',14,'markerfacecolor','w')


% make the graph connected (wrap around without a gap)
th = [gradientOrient gradientOrient(1)];
r  = [averageSpikes  averageSpikes(1)];
polarplot(deg2rad(th),r,...
    'ks-','linewidth',3,'markersize',14,'markerfacecolor','w')


%%
% -------------------------------------------------- %
%                                                    %
%  Video 5: Visualize a spatial map of spike counts  %
%                                                    %
% -------------------------------------------------- %
% 
%% gather the data

% first map is average number of spikes
APsPerCell = mean(mean(totalSpikeCount,2),3);

% list the channels with units
uniquechans = unique(data.CHANNELS(:,1));

%% create the data matrix

% initialize output matrix
spikesMap = zeros(size(data.MAP));

% loop over all unique units
for chani=1:length(uniquechans)
    
    % find all units on this electrode
    whichunits = data.CHANNELS(:,1)==uniquechans(chani);
    
    % map coordinate for this channel
    [row,col] = find(data.MAP==uniquechans(chani));
    
    % average number of spikes for all units on this channel
    spikesMap(row,col) = mean(APsPerCell(whichunits));
end

%% now let's see what it looks like

figure(4), clf
subplot(121)

% draw the image
imagesc(spikesMap)
title('Firing rate map')

% make the plot look nicer
axis square
colorbar
set(gca,'xtick',[],'ytick',[],'clim',[0 20])
xlabel('Spatial dimension X')
ylabel('Spatial dimension Y')
colormap hot

%%
% -------------------------------------------------- %
%                                                    %
%  Video 6: Visualize a spatial map of tuning angle  %
%                                                    %
% -------------------------------------------------- %
% 
%% 

% compute the average spike count over all trials per orientation
averageSpikes = mean(totalSpikeCount,3);

% find the maximum response and convert to degrees
[maxval,maxresp] = max(averageSpikes,[],2);
maxresp = gradientOrient(maxresp);

%% create the data matrix

% initialize output matrix
orientationMap = nan(size(data.MAP));

for chani=1:length(uniquechans)
    
    % find all units on this electrode
    whichchans = data.CHANNELS(:,1)==uniquechans(chani);
    
    % map coordinate for this channel
    [row,col] = find(data.MAP==uniquechans(chani));
    
    % average number of spikes for all units on this channel
    orientationMap(row,col) = mean(maxresp(whichchans));
end

%% visualize using the same (unipolar) colormap as the previous map

subplot(122)
imagesc(orientationMap)
axis square
colorbar
set(gca,'xtick',[],'ytick',[],'clim',[0 360])
xlabel('Spatial dimension X')
ylabel('Spatial dimension Y')
title('Orientation map')

%% ... but we have circular data

% built-in circular colormap (affects figure)
colormap hsv

% create our own bimodal circular colormap, only for active axis
c = copper(16);
% c = cool(16); % also a nice one ;)
colormap(gca,[ c; flipud(c); c; flipud(c); ])

%% ... but nan's shouldn't have the same color as "0"

pcolor(orientationMap)
axis square, axis ij
colorbar
set(gca,'xtick',[],'ytick',[],'clim',[0 360])
xlabel('Spatial dimension X')
ylabel('Spatial dimension Y')
title('Orientation map')
colormap(gca,[ c; flipud(c); c; flipud(c); ])

%% done.
