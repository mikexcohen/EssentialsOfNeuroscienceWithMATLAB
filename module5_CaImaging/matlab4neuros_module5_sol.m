%%
%   COURSE: MATLAB training for early-career neuroscientists										
%      URL: ...
% 
%  SECTION: Module 5: Calcium imaging
% 
%  TEACHER: Mike X Cohen, sincxpress.com
%

% NOTE: This is the solutions code.
%       You should work through the "partial" file before looking at this.

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

load('mouse10depth125green.mat')

% inspect the data
whos

%% 

% sampling rate is 30 Hz according to dataset info
srate = 30;

% we can create an arbitrary time vector
timevec = (0:length(green)-1) / srate;
timevec([1 end])

% variable to store the number of time points
npnts = length(timevec);

%% show a movie as we've done in previous modules

figure(1), clf

% setup the figure and title with handles
imgh = imagesc(green{1});
tith = title('hello.');
set(gca,'clim',[-1 1]*900)
axis square


% select a number of frames to animate
nFrames = 500; % don't need to go through the entire movie

% now for the movie!
for framei=1:nFrames
    
    % update the image color data
    set(imgh,'CData',green{framei})
    
    % update the title
    set(tith,'String',timevec(framei) + " sec")
    set(tith,'String',sprintf('%.2f sec',timevec(framei)))
    
    % real-time delay (minus a smidge for graphics updating)
    pause(1/srate - .01)
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

% initialize matrix
data = zeros([size(green{1}) npnts]);

% populate the matrix with data, one slice at a time
for i=1:npnts
    data(:,:,i) = green{i};
end

%% save space by removing unnecessary data

whos

% convert bytes to gb
varSizeGB = 7177894304 / 1024^3;

clear green % free up ~7 gb!

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
avemap = squeeze(mean(data,3));

% normalize to a range of [0 1]
avemap = avemap-min(avemap(:));
avemap = avemap./max(avemap,[],'all');


% STEP 1b: apply MATLAB's local adaptive histogram equalization
avemap = adapthisteq(avemap);


% STEP 2: estimate the background as a fuzzy version of the image
background = imgaussfilt(avemap,10);


% STEP 3: create the boosted-SNR map by subtracting the 'background'
foreground = avemap-background;


%% pause to see what we've done so far

figure(3), clf
colormap hot

% the average map (many code statements in one line!)
subplot(221), imagesc(avemap), axis square, title('Mean')


% the background image
subplot(222)
imagesc(background)
axis square
title('Background')

% the foreground image
subplot(223)
imagesc(foreground)
axis square
title('Isolated')
set(gca,'clim',[0 .3])
% colorbar

%% continuing...

% STEP 4: threshold the foreground map
threshval = .05;
threshimg = foreground > threshval;


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
cellsizes = cellfun(@length,islands.PixelIdxList);

% find small and large cells
cells2cut = cellsizes<15 | cellsizes>100;

% remove those cells
islands.PixelIdxList(cells2cut) = [];

% update the number of remaining clusters ("neurons")
islands.NumObjects = numel(islands.PixelIdxList);


% finally, recreate the threshold image without rejected clusters 
threshimgFilt = false(size(avemap));
for i=1:islands.NumObjects
    threshimgFilt(islands.PixelIdxList{i}) = true;
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
neuronts = zeros(islands.NumObjects,npnts);

% extract data from each cell over time
for celli=1:islands.NumObjects
    
    % done per time point because cells are 2D
    for timei=1:npnts
        
        % get the entire map from this time point
        tmp = squeeze(data(:,:,timei));
        
        % compute the average of all pixels in this time point
        neuronts(celli,timei) = mean( tmp(islands.PixelIdxList{celli}) );
    end
end

%% visualize some time courses

% show one neuron
figure(5), clf

subplot(511)
plot(timevec,neuronts(37,:))
ylabel('Brightness (a.u.)')
set(gca,'xlim',timevec([1 end]),'xticklabel',[])
box off

% show all neurons at a time
subplot(5,1,2:5)
imagesc(timevec,[],neuronts)
xlabel('Time (sec.)')
ylabel('Cell number')

% another way of visualizing
figure(6), clf
plot(timevec,neuronts)
ylabel('Brightness (a.u.)')
title('Fluorescence of all neurons')
set(gca,'xlim',timevec([1 end]))
xlabel('Time (sec.)')

%% convert to dF

neuronts = bsxfun(@rdivide,neuronts,mean(neuronts,2));

% then recreate the previous figure for comparison


%% filter the time series

% wide-band filter
filterrange = [.5 13]; % units are Hz

% create filter coefficients
[b,a] = butter(5,filterrange./(srate/2)); % scale to Nyquist units

% filter the data
neurontsFilt = neuronts;
for neuroni=1:size(neurontsFilt,1)
    % The function filtfilt applies the filter forwards and backwards in
    % time, which gives the non-phase-shifted version of the signal.
    neurontsFilt(neuroni,:) = filtfilt(b,a,neuronts(neuroni,:));
end

%% compare the time series

figure(8), clf, hold on
plot(timevec,neuronts(37,:)-1)
plot(timevec,neurontsFilt(37,:))

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

[pca_ts,pca_scores,eigenvalues] = pca(neurontsFilt);


% compare the first PC against the average of all cells
figure(9), clf
plot(timevec,mean(neurontsFilt,1), timevec,pca_ts(:,1))

% make the plot look nicer
legend({'Average neurons','Top PC'})
xlabel('Time (sec.)')
ylabel('Brightness (a.u.)')
set(gca,'xlim',timevec([1 end]))
zoom on

% can also try plotting one against the other, and correlation

%% visualize the PC weightings

% create a map of neurons, colored by their PCA score
pcmap = zeros(size(avemap));
for i=1:islands.NumObjects
    pcmap(islands.PixelIdxList{i}) = pca_scores(i,1);
end

% create a grayscale image in RGB format
anatomy = cat(3,avemap,avemap,avemap);

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
