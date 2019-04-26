function outputTrajectories = createTrajectories_aic(opts, inputTrajectories, startTime, endTime, iCam,appear_model_param,motion_model_param)
% CREATETRAJECTORIES partitions a set of tracklets into trajectories.
%   The third stage uses appearance grouping to reduce problem complexity;
%   the fourth stage solves the graph partitioning problem for each
%   appearance group.


% find current, old, and future tracklets
currentTrajectoriesInd    = findTrajectoriesInWindow(inputTrajectories, startTime, endTime);
currentTrajectories       = inputTrajectories(currentTrajectoriesInd);

% safety check
if length(currentTrajectories) <= 1
    outputTrajectories = inputTrajectories;
    return;
end

% select tracklets that will be selected in association. For previously
% computed trajectories we select only the last three tracklets.
inAssociation = []; tracklets = []; trackletLabels = [];
for i = 1 : length(currentTrajectories)
   for k = 1 : length(currentTrajectories(i).tracklets) 
       tracklets        = [tracklets; currentTrajectories(i).tracklets(k)]; %#ok
       trackletLabels   = [trackletLabels; i]; %#ok
       
       inAssociation(length(trackletLabels)) = false; %#ok
       if k >= length(currentTrajectories(i).tracklets) - 2
           inAssociation(length(trackletLabels)) = true; %#ok
       end
       
   end
end
inAssociation = logical(inAssociation);

% show all tracklets
if opts.visualize, trajectoriesVisualizePart1; end

% solve the graph partitioning problem for each appearance group
result = solveInGroups_aic(opts, tracklets(inAssociation), trackletLabels(inAssociation), iCam,appear_model_param,motion_model_param);

% merge back solution. Tracklets that were associated are now merged back
% with the rest of the tracklets that were sharing the same trajectory
labels = trackletLabels; labels(inAssociation) = result.labels;
count = 1;
for i = 1 : length(inAssociation)
   if inAssociation(i) > 0
      labels(trackletLabels == trackletLabels(i)) = result.labels(count);
      count = count + 1;
   end
end

% merge co-identified tracklets to extended tracklets
newTrajectories = trackletsToTrajectories(opts, tracklets, labels);
smoothTrajectories = recomputeTrajectories(newTrajectories, opts);

for i = 1 : length(smoothTrajectories)
    if isempty(smoothTrajectories(i).tracklets)
        smoothTrajectories(i)
    end
end

outputTrajectories = inputTrajectories;
outputTrajectories(currentTrajectoriesInd) = [];
outputTrajectories = [outputTrajectories; smoothTrajectories'];

% show merged tracklets in window 
if opts.visualize, trajectoriesVisualizePart3; end

end


