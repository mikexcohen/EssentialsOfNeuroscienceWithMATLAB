%%
%   COURSE: MATLAB training for early-career neuroscientists										
%      URL: ...
% 
%  SECTION: Module 5: Calcium imaging
% 
%  TEACHER: Mike X Cohen, sincxpress.com
%

% NOTE: This is the partially completed code accompanying the video.
%       You can work through this code before looking at the solution.

%% data sources

% Publication:
%   http://dx.doi.org/10.1016/j.neuron.2015.06.030
% 
% Dataset:
%   http://crcns.org/data-sets/vc/pvc-10/about
% 


%% a clear MATLAB workspace is a clear mental workspace

close all; clear; clc

%%
% -------------------------------------------------------- %
%                                                          %
%     Video 2: Animate calcium fluctuations over time      %
%                                                          %
% -------------------------------------------------------- %
% 
%% Load the data

% download from online and unpack
websave('file.zip','https://sincxpress.com/neuroscience/matlab4neuros_module5.zip',weboptions('Timeout',120));
unzip('file.zip');


load('mouse10depth125green.mat')

% inspect the data
whos

% sampling rate is 30 Hz according to dataset info
srate = 30;

% we can create an arbitrary time vector
timevec = 

% check the time range by printing the first and last time points


% variable to store the number of time points
npnts = 

%% show a movie as we've done in previous modules

figure(1), clf

% setup the figure and title with handles
imgh = imagesc();
tith = title();
set(gca,'clim',[1 1]*900)
axis square


% select a number of frames to animate
nFrames = 500; % don't need to go through the entire movie

% now for the movie!
for framei=1:nFrames
    
    % update the image color data
    set(imgh
    
    % update the title
    set(tith,'String',
    
    % real-time delay (minus a smidge for graphics updating)
    pause(.01)
end

%%
% -------------------------------------------------------- %
%                                                          %
%       Video 3: Convert data from cell to matrix          %
%                                                          %
% -------------------------------------------------------- %
% 
%%

%% 

% initialize data matrix (what size should it be?)
data = zeros

% populate the matrix with data, one slice at a time
for i=1:npnts
    
end

%% save space by removing unnecessary data

whos

% convert bytes to gb
varSizeGB = ;

% clear the cell array from the workspace
  % how much gets freed up??

%%
% -------------------------------------------------------- %
%                                                          %
%  Video 4: Image processing to reduce background noise    %
%                                                          %
% -------------------------------------------------------- %
% 
%%

%% identify and remove "background noise"

% STEP 1a: compute the average map
avemap = 

% normalize to a range of [0 1]
% this is done by (1) subtracting the smallest value and (2) dividing by the largest
avemap = 
avemap = 


% STEP 1b: apply MATLAB's local adaptive histogram equalization
avemap = adapthisteq();


% STEP 2: estimate the background as a fuzzy version of the image
background = imgaussfilt();


% STEP 3: create the boosted-SNR map by subtracting the 'background'
foreground = 


%% pause to see what we've done so far

figure(3), clf
colormap hot

% the average map (many code statements in one line!)
subplot(221), imagesc(avemap), axis square, title('Mean')


% the background image
subplot(222)
imagesc(background)
axis square
title(<insert title here>)

% the foreground image
subplot(223)
imagesc(foreground)
axis square
title('Isolated')
% find a good color limit (via trial-and-error)
set(gca,'clim',)
% colorbar

%% continuing...

% STEP 4: threshold the foreground map
threshval = % pick a threshold here based on inspecting the foreground map
threshimg = ; % create a boolean map of all pixels brighter than the threshold


% and visualize that
subplot(224)
imagesc(threshimg)
axis square
title('binarized')



%%
% -------------------------------------------------------- %
%                                                          %
%      Video 5: Identify neurons based on contiguity       %
%                                                          %
% -------------------------------------------------------- %
% 
%%

% get cluster information
islands = bwconncomp(threshimg);

% identify the cluster sizes
cellsizes = cellfun(@length,islands..);

% find small and large cells
cells2cut = cellsizes<15 | cellsizes>100;

% and remove those cells
islands.PixelIdxList( ) = [];

% update the number of remaining clusters ("neurons")
islands.NumObjects = 


% finally, recreate the threshold image without rejected clusters 
threshimgFilt = false(size(avemap));
for i=1:islands.NumObjects
    threshimgFilt(islands.PixelIdxList{i}) = % what value shall we assign these pixels?
end


%% visualize

% same as in previous video, redrawn for the before/after show
figure(4), clf
subplot(121)
imagesc(threshimg)
axis square
title('binarized (original)')
colormap gray



% show again for comparison
subplot(122)
imagesc(threshimgFilt)
axis square
title('binarized (filtered)')

%%
% -------------------------------------------------------- %
%                                                          %
%     Video 6: High-pass filter the time series data       %
%                                                          %
% -------------------------------------------------------- %
% 
%%

%% get time courses from all "neurons"

% initialize time series matrix
neuronts = 

% extract data from each cell over time
for celli=1:
    
    % done per time point because cells are 2D
    for timei=1:npnts
        
        % get the entire map from this time point
        tmp = squeeze(data(:,:,timei));
        
        % compute the average of all pixels in this time point
        neuronts(celli,timei) = tmp(islands.PixelIdxList{celli});
    end
end

%% visualize some time courses

figure(5), clf

% show time course from neuron #37
subplot(511)
plot(timevec,neuronts(37))
ylabel('Brightness (a.u.)')
set(gca,'xlim',timevec([1 end]),'xticklabel',[])
box off

% show all neurons at a time
subplot(5,1,2:5)
imagesc(timevec,neuronts)
xlabel('Time (sec.)')
ylabel('Cell number')


% show all neurons at the same time
figure(6), clf
plot(timevec,neuronts)
ylabel('Brightness (a.u.)')
title('Fluorescence of all neurons')
set(gca,'xlim',timevec([1 end]))
xlabel('Time (sec.)')

%% convert to dF

% divide by the average over time
neuronts = bsxfun(@rdivide,neuronts,mean(neuronts,npnts));


% then recreate the previous figure for comparison


%% filter the time series

% wide-band filter
filterrange = [ ]; % units are Hz

% create filter coefficients
% check the help file for butter for correct usage
[b,a] = butter(); 

% filter the data
neurontsFilt = neuronts; % initialization without zeros
for neuroni=1:size(neurontsFilt,1)
    % The function filtfilt applies the filter forwards and backwards in
    % time, which gives the non-phase-shifted version of the signal.
    neurontsFilt(neuroni,:) = filtfilt(b,a,neuronts(neuroni,:));
end

%% compare the time series

figure(8), clf

% plot the time course of neuron #37 before and after filtering
plot(timevec,
plot(timevec,

legend({'Original','Filtered'})
xlabel('Time (sec.)')
ylabel('Brightness (a.u.)')
set(gca,'xlim',timevec([1 end]))
zoom on

%%
% -------------------------------------------------------- %
%                                                          %
%          Video 7: Compute and visualize a PCA            %
%                                                          %
% -------------------------------------------------------- %
% 
%%

%% run the PCA

% compute the PCA
[pca_ts,pca_scores,eigenvalues] = pca(neurontsFilt);


figure(9), clf

% compare the first PC against the average of all cells
plot(timevec, , timevec,)

% make the plot look nicer
legend({'Average neurons','Top PC'})
xlabel('Time (sec.)')
ylabel('Brightness (a.u.)')
set(gca,'xlim',timevec([1 end]))
zoom on

%% visualize the PC weightings

% create a map of neurons, colored by their PCA score
pcmap = zeros(size(avemap));
for i=1:islands.NumObjects
    pcmap(islands.PixelIdxList{i}) = ;
end

% create a grayscale image in RGB format
anatomy = cat(3,,,);

% now we can visualize the map
figure(10), clf
imagesc(anatomy)

% and then plot the PCmap on top
hold on
h = imagesc(pcmap);

%% change the transparency of the pcmap

set(h,'AlphaData',threshimgFilt)
set(gca,'clim',[-1 1])
colormap(bluewhitered)
axis square

%% done.
