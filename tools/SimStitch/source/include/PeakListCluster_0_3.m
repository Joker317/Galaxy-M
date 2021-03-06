function [iOut] = PeakListCluster_0_3(mzIn, maxSpread)
% mzIn = SORTED (ascending) peak m/z values for N spectra
%           (cell length N, each cell is matrix size 1 x n peaks)
% maxSpread = maximum spread of peaks in cluster (m/z or ppm)

% iOut = cluster index of each peak, same size structure as mzIn
%           NB: peak count can be > 1 for one spectrum!  (Means close peaks
%           in spec.)

% MODIFICATION HISTORY
% 
% 14/Nov/07 (v0.1) Added rethrow error to pdist catch
% Rearranged conversion of pdist's to ppm to reduce memory requirements.
% 15/Nov/07 (v0.1b) Added PARAMS.BLOCKSIZE for better splitting up of
% search space.
% 7/Dec/07  (v0.1c) Added flag to speed processing and conserve memory 
% in cases where peak must be present in all spectra
% 17/Dec/07         Removed flag
% 18/Feb/08 (v0.2)  Fixed bug where block boundaries coinciding with peaks
%                   cause false peak clusters
% 19/Feb/08 (v0.3)  Simplified, takes only m/z values and returns cluster
%                   index of each m/z value (and mean cluster m/z)
% 11/Mar/08         Gives hint that PLS toolbox might cause cluster to fail
% 15/May/08         lin 64, bufl and bufh increased from 2* to 5* to try
%                   remove occurrences of failing
% 15/Jul/08         Added hint to rehash toolboxes and path list if cluster
%                   fails (seems function shadowing sometimes needs update)

%% start
MAXBLOCKSIZE = 2000;  % approx. maximum number of peaks in each block during clustering (reduce to solve MEMORY problems)
                      % a good value is 2000

numSpec = length(mzIn);

% mzOut = [];   % output of cluster mean m/z values

% iOut has same size as mzIn
iOut = {};
for i=1:numSpec
    iOut{i} = []; %zeros(size(mzIn{i}));
end

% search over limited space to conserve memory: limit number of peaks in
% block. Find suitable block end points.
mz = unique([mzIn{:}]);   % all data points
i = 1;    % index to mz
bc = 1;   % boundary count
bound = mz(i);    % first mz boundary value
while i < length(mz)
    i = i+MAXBLOCKSIZE;
    if i > length(mz), i=length(mz); end
    bc = bc+1;    
    bound(bc) = mz(i);
end

fprintf('Splitting search space into blocks with max ~%d peaks\n',MAXBLOCKSIZE);
fprintf('Clustering %d input peak lists\n',numSpec);

cc = 0; % cluster counter
tic;
fprintf('Progress:  0%%');
for bc = 1:length(bound)-1
    % cluster m/z values within current boundary
    MZb = [];
    SMb = [];   % spectral membership of each m/z value
    % add buffer to boundaries (to burn later) in case boundary coincides with cluster
    bufl = 5*maxSpread*bound(bc)/1e6; % need 5*maxSpread
    bufh = 5*maxSpread*bound(bc+1)/1e6;
    % find all the peaks from each spectrum within current boundaries
    for i=1:numSpec
        mz = mzIn{i};
        idx = find(bound(bc)-bufl <= mz & mz <= bound(bc+1)+bufh);
        MZb = [MZb mzIn{i}(idx)];
        SMb = [SMb repmat(i,1,length(idx))];
    end
    % catch cases where linkage won't work
    if length(MZb)<3, continue; end
    % cluster
    try
        Y = pdist(MZb.','cityblock');
    catch
        fprintf('Failed on pdist: is Statistics toolbox installed?\n');
        rethrow(lasterror);
    end
    % convert absolute distances to ppm (of mean of pair) distances
    k = 0;
    for j=1:length(MZb)-1
        idx = k+1:k+length(MZb)-j;
        Y(idx) = Y(idx) ./ mean([repmat(MZb(j),1,length(MZb)-j); MZb(j+1:end)]) * 1e6;
        k = k+length(MZb)-j;
    end
    Z = linkage(Y,'complete');  %furthest distance
    clear Y
    % cluster to give the cluster membership of each value in MZb
    try
        CMb = cluster(Z,'criterion','distance','cutoff',maxSpread);
    catch
        fprintf('''cluster'' function failed: is PLS_Toolbox installed?\n');
        fprintf('\tCheck PLS_Toolbox paths are below stats toolbox.\n');
        fprintf('\tIf you still see this error, try:\n');
        fprintf('\t''rehash pathreset''\n');
        fprintf('\t''rehash toolboxreset''\n');
        rethrow(lasterror);
    end
    clear Z
    % calculate mean m/z for each cluster, assuming clusters labelleled
    % monotonically
    CMZb = zeros(1,max(CMb));
    for i=1:max(CMb)
        CMZb(i) = mean(MZb(CMb==i));
    end
    %if cluster m/z is within the boundary buffer, burn it (it will
    %be included in the next region)
    if (bc > 1) && (bc < (length(bound)-1))
        % middle bound
        cBurn = find(bound(bc) > CMZb | CMZb >= bound(bc+1));
    elseif length(bound) == 2
        % single boundary region - do nothing
        cBurn = [];
    elseif bc == length(bound) - 1
        % final bound
        cBurn = find(bound(bc) > CMZb);
    elseif bc == 1
        % first bound
        cBurn = find(CMZb >= bound(bc+1));
    end
    % burn clusters
%     CMZb(cBurn) = 0;
    for i=1:length(cBurn)
        idx = find(CMb==cBurn(i));
        CMb(idx) = [];
        SMb(idx) = [];
        % re-label highest cluster number with cluster just burnt
        % to avoid missing values in the final output
        cl = unique(CMb); % cluster list
        if max(cl) > cBurn(i)
            % cluster membership list
            CMb(CMb==max(cl)) = cBurn(i);
            % and in case in burn list
            cBurn(cBurn==max(cl)) = cBurn(i);
%             % cluster m/z list
%             CMZb(cBurn(i)) = CMZb(max(cl));
%             CMZb(max(cl)) = 0;
        end
    end
%     CMZb = CMZb(CMZb>0);    % remove burned cluster m/z values
    % update output of cluster centers
%     mzOut = [mzOut CMZb];
    % offset cluster numbers so cluster numbers remain unique
    ccOld = cc;
    cc = cc + max(CMb);
    CMb = CMb + ccOld;
    % store cluster membership to output
    for i=1:numSpec
        iOut{i} = [iOut{i} CMb(SMb==i).'];
    end
    if round(toc) || bc==length(bound)-1
        fprintf('\b\b\b');
        fprintf('%2.0f%%',floor(bc/(length(bound)-1)*100));
        tic;
    end
end
fprintf('\n');

cl = unique([iOut{:}]); % cluster list
nc = length(cl);   %number of clusters

% check cluster numbered monotonically
if max(cl) ~= nc
    error('Clustering failed: non-monotonic cluster numbers detected');
end
% check dimensions match
for i=1:numSpec
    if ~isequal(size(mzIn{i}),size(iOut{i}))
        error(['Clustering failed i=',num2str(i)]);
    end
end
% % check number of clusters = length of mzBar
% if nc ~= length(find(mzOut))
%     error('Clustering failes');
% end

return
end
